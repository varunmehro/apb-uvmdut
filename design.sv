module apb_regfile (
    input  logic        pclk,
    input  logic        presetn,
    input  logic [31:0] paddr,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [31:0] pwdata,
    output logic [31:0] prdata
);

  // Register file of 16 x 32-bit registers
  logic [31:0] mem [0:15];

  // Reset all registers
  integer i;
  always_ff @(negedge presetn or posedge pclk) begin
    if (!presetn) begin
      for (i = 0; i < 16; i++) begin
        mem[i] <= 32'h0;
      end
      prdata <= 32'h0;
    end
    else begin
      if (psel && !penable) begin
        // SETUP phase: prepare read data (if read)
        if (!pwrite) begin
          prdata <= mem[paddr[3:0]];
        end
      end
      else if (psel && penable) begin
        // ENABLE phase: perform write
        if (pwrite) begin
          mem[paddr[3:0]] <= pwdata;
        end
      end
    end
  end

endmodule
