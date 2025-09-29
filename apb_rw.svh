`ifndef APB_RW_SVH
`define APB_RW_SVH

import uvm_pkg::*;

class apb_rw extends uvm_sequence_item;

  typedef enum {READ, WRITE} kind_e;
  rand kind_e kind;

  rand bit [31:0] addr;
  rand bit [31:0] data;

  `uvm_object_utils_begin(apb_rw)
    `uvm_field_enum(kind_e, kind, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "apb_rw");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("kind=%s addr=%0h data=%0h", kind.name(), addr, data);
  endfunction

endclass : apb_rw

`endif
