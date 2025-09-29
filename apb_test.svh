`ifndef APB_BASE_TEST_SVH
`define APB_BASE_TEST_SVH

import uvm_pkg::*;

class apb_base_test extends uvm_test;
  `uvm_component_utils(apb_base_test)

  apb_env env;
  apb_config cfg;
  virtual apb_if vif;

  function new(string name="apb_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = apb_config::type_id::create("cfg", this);
    env = apb_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("APB/TEST/NOVIF", "No virtual interface specified for test");
    end
    uvm_config_db#(virtual apb_if)::set(this, "env", "vif", vif);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    apb_base_seq seq;
    seq = apb_base_seq::type_id::create("apb_seq");
    phase.raise_objection(this);
    `uvm_info("APB_TEST", "Starting apb_base_seq on sequencer", UVM_LOW)
    seq.start(env.agt.sqr);
    #100ns;
    phase.drop_objection(this);
  endtask

endclass

`endif
