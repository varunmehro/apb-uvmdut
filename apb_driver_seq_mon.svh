`ifndef APB_DRV_SEQ_MON_SV
`define APB_DRV_SEQ_MON_SV


typedef apb_config;
typedef apb_agent;

//---------------------------------------------
// APB master driver Class  
//---------------------------------------------


class apb_master_drv extends uvm_driver#(apb_rw);

  `uvm_component_utils(apb_master_drv)

  virtual apb_if vif;
  apb_config cfg;

  function new(string name = "apb_master_drv", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
  `uvm_fatal("APB/DRV/NOVIF", "No virtual interface specified for this driver instance")
end

  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    // initialize signals to idle
    vif.master_cb.psel    <= 0;
    vif.master_cb.penable <= 0;
    vif.master_cb.pwrite  <= 0;
    vif.master_cb.paddr   <= 0;
    vif.master_cb.pwdata  <= 0;

    forever begin
      apb_rw tr;
      @(vif.master_cb);
      seq_item_port.get_next_item(tr);
      @(vif.master_cb);
      `uvm_info("APB_DRIVER", $sformatf("Got Transaction %s", tr.convert2string()), UVM_MEDIUM);

      case (tr.kind)
        apb_rw::READ:  drive_read(tr.addr, tr.data);
        apb_rw::WRITE: drive_write(tr.addr, tr.data);
      endcase

      seq_item_port.item_done();
    end
  endtask

  virtual protected task drive_read(input bit [31:0] addr, output bit [31:0] data);
    // setup
    vif.master_cb.paddr   <= addr;
    vif.master_cb.pwrite  <= 0;
    vif.master_cb.psel    <= 1;
    vif.master_cb.penable <= 0;
    @(vif.master_cb);

    // enable
    vif.master_cb.penable <= 1;
    @(vif.master_cb);

    // if pready exists, wait; else extra cycle
    if (^vif.master_cb.pready !== 1'bX) begin
      wait (vif.master_cb.pready == 1);
      @(vif.master_cb);
    end
    else begin
      @(vif.master_cb);
    end

    data = vif.master_cb.prdata;
    `uvm_info("APB_DRIVER", $sformatf("READ addr=0x%0h -> data=0x%0h", addr, data), UVM_LOW);

    // return to idle
    vif.master_cb.psel    <= 0;
    vif.master_cb.penable <= 0;
    @(vif.master_cb);
  endtask

  virtual protected task drive_write(input bit [31:0] addr, input bit [31:0] data);
    // setup
    vif.master_cb.paddr   <= addr;
    vif.master_cb.pwdata  <= data;
    vif.master_cb.pwrite  <= 1;
    vif.master_cb.psel    <= 1;
    vif.master_cb.penable <= 0;
    @(vif.master_cb);

    // enable
    vif.master_cb.penable <= 1;
    @(vif.master_cb);

    if (^vif.master_cb.pready !== 1'bX) begin
      wait (vif.master_cb.pready == 1);
      @(vif.master_cb);
    end

    `uvm_info("APB_DRIVER", $sformatf("WRITE addr=0x%0h data=0x%0h", addr, data), UVM_LOW);

    // back to idle
    vif.master_cb.psel    <= 0;
    vif.master_cb.penable <= 0;
    vif.master_cb.pwrite  <= 0;
    @(vif.master_cb);
  endtask

endclass : apb_master_drv


//---------------------------------------------
// APB Sequencer Class  
//  Derive form uvm_sequencer and parameterize to apb_rw sequence item
//---------------------------------------------
class apb_sequencer extends uvm_sequencer #(apb_rw);

   `uvm_component_utils(apb_sequencer)
 
   function new(input string name, uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

endclass : apb_sequencer

//-----------------------------------------
// APB Monitor class  
//-----------------------------------------

`ifndef APB_MONITOR_SVH
`define APB_MONITOR_SVH

import uvm_pkg::*;

class apb_monitor extends uvm_monitor;

  `uvm_component_utils(apb_monitor)

  // Use full interface handle for config_db compatibility
  virtual apb_if vif;

  // analysis port
  uvm_analysis_port#(apb_rw) ap;

  function new(string name = "apb_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_agent agent;
    if ($cast(agent, get_parent()) && agent != null) begin
      vif = agent.vif;
    end
    else begin
      virtual apb_if tmp;
      if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", tmp)) begin
        `uvm_fatal("APB/MON/NOVIF", "No virtual interface specified for this monitor instance")
      end
      vif = tmp;
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
      apb_rw tr;

      // wait for SETUP: psel=1 penable=0
      @(posedge vif.pclk);
      wait (vif.psel == 1'b1 && vif.penable == 1'b0);

      // create transaction and capture addr/kind at setup
      tr = apb_rw::type_id::create("tr", this);
      tr.addr = vif.paddr;
      tr.kind = (vif.pwrite) ? apb_rw::WRITE : apb_rw::READ;

      // wait for ENABLE
      wait (vif.penable == 1'b1);

      // If DUT has pready, wait for it; else provide a safe extra cycle
      if (^vif.pready !== 1'bX) begin
        wait (vif.pready == 1'b1);
        @(posedge vif.pclk); // sample after ready
      end
      else begin
        @(posedge vif.pclk); // safe extra cycle
      end

      // capture data (now stable)
      if (tr.kind == apb_rw::WRITE)
        tr.data = vif.pwdata;
      else
        tr.data = vif.prdata;

      `uvm_report_info("APB_MONITOR", $sformatf("Got Transaction %s", tr.convert2string()), UVM_LOW);

      // send to scoreboard
      ap.write(tr);

      // wait until transaction ends (psel deassert)
      wait (vif.psel == 1'b0);
    end
  endtask : run_phase

endclass : apb_monitor

`endif