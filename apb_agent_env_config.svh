`ifndef APB_AGENT_ENV_CFG_SVH
`define APB_AGENT_ENV_CFG_SVH

import uvm_pkg::*;
`include "apb_scoreboard.svh"

class apb_config extends uvm_object;
  `uvm_object_utils(apb_config)
  function new(string name="apb_config"); super.new(name); endfunction
endclass

class apb_agent extends uvm_agent;

  `uvm_component_utils(apb_agent)

  // Handles to subcomponents
apb_master_drv drv;
apb_monitor    mon;
apb_sequences  sqr;


  // Virtual interface
  virtual apb_if vif;

  function new(string name = "apb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build phase: create subcomponents
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    drv = apb_master_drv::type_id::create("drv", this);
    mon = apb_monitor::type_id::create("mon", this);
    sqr = apb_sequences::type_id::create("sqr", this);

    // Get vif from config_db
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("APB/AGENT/NOVIF", "No virtual interface specified for agent")
    end

    // Pass vif down
    uvm_config_db#(virtual apb_if)::set(this, "drv", "vif", vif);
    uvm_config_db#(virtual apb_if)::set(this, "mon", "vif", vif);
  endfunction

  // Connect phase: connect sequencer to driver
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass : apb_agent



class apb_env extends uvm_env;
  `uvm_component_utils(apb_env)

  apb_agent agt;
  apb_scoreboard scb;
  virtual apb_if vif;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = apb_agent::type_id::create("agt", this);
    scb = apb_scoreboard::type_id::create("scb", this);

    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("APB/ENV/NOVIF", "No virtual interface specified for this env instance")
    end
    uvm_config_db#(virtual apb_if)::set(this, "agt", "vif", vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // connect monitor analysis port to scoreboard imp
    agt.mon.ap.connect(scb.item_collected_export);
  endfunction

endclass : apb_env

`endif
