import uvm_pkg::*;


`include "uvm_macros.svh"

`include "apb_if.svh"
`include "apb_rw.svh"
`include "apb_driver_seq_mon.svh"
`include "apb_scoreboard.svh"
`include "apb_agent_env_config.svh
`include "apb_sequences.svh"
`include "apb_test.svh"

module test;
  logic pclk;
  logic presetn;

  initial begin
    pclk = 0;
    forever #10 pclk = ~pclk;
  end

  initial begin
    presetn = 0;
    #50 presetn = 1;
  end

  // instantiate interface (ensure your apb_if has pclk and presetn ports)
  apb_if apb_if_inst(.pclk(pclk), .presetn(presetn));

  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top", "vif", apb_if_inst);
    run_test("apb_base_test");
  end
endmodule
