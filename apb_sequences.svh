`ifndef APB_SEQUENCES_SVH
`define APB_SEQUENCES_SVH

import uvm_pkg::*;

class apb_base_seq extends uvm_sequence#(apb_rw);
  `uvm_object_utils(apb_base_seq)

  function new(string name = "apb_base_seq");
    super.new(name);
  endfunction

  task body();
    apb_rw rw_trans;
    repeat (10) begin
      rw_trans = apb_rw::type_id::create("rw_trans");
      start_item(rw_trans);
      assert(rw_trans.randomize());
      finish_item(rw_trans);
    end
  endtask

endclass : apb_base_seq

`endif
