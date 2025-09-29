`ifndef APB_SCOREBOARD_SVH
`define APB_SCOREBOARD_SVH

import uvm_pkg::*;

class apb_scoreboard extends uvm_component;

  `uvm_component_utils(apb_scoreboard)

  // This is an analysis_imp (monitor connects to this)
  uvm_analysis_imp#(apb_rw, apb_scoreboard) item_collected_export;

  // Reference memory
  bit [31:0] ref_mem [int];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_collected_export = new("item_collected_export", this);
  endfunction

  // analysis write method called by monitor
  virtual function void write(apb_rw tr);
    if (tr.kind == apb_rw::WRITE) begin
      ref_mem[tr.addr] = tr.data;
      `uvm_info("APB_SCB",
        $sformatf("WRITE Addr=0x%0h Data=0x%0h (Stored in ref_mem)", tr.addr, tr.data),
        UVM_LOW)
    end
    else begin
      bit [31:0] exp;
      if (ref_mem.exists(tr.addr))
        exp = ref_mem[tr.addr];
      else
        exp = '0; // you can change to 'hx if you prefer to flag unwritten reads

      if (tr.data === exp) begin
        `uvm_info("APB_SCB",
          $sformatf("READ Match Addr=0x%0h Data=0x%0h", tr.addr, tr.data),
          UVM_LOW)
      end
      else begin
        `uvm_error("APB_SCB",
          $sformatf("READ MISMATCH Addr=0x%0h Expected=0x%0h Got=0x%0h",
                    tr.addr, exp, tr.data))
      end
    end
  endfunction

endclass : apb_scoreboard

`endif
