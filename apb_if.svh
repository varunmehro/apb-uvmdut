`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if(input bit pclk);

   // APB signals
   wire [31:0] paddr;    // 32-bit address
   wire        psel;     // select signal
   wire        penable;  // enable signal
   wire        pwrite;   // write/read control
   wire [31:0] prdata;   // data read from slave
   wire [31:0] pwdata;   // data written by master

   // Master Clocking block - used for Drivers
   clocking master_cb @(posedge pclk);
      output paddr, psel, penable, pwrite, pwdata;
      input  prdata;
   endclocking: master_cb
  
    // Slave Clocking Block - used for Slave BFMs
   clocking slave_cb @(posedge pclk);
      input  paddr, psel, penable, pwrite, pwdata;
      output prdata;
   endclocking: slave_cb
  
    // Monitor Clocking block - for passive monitors
   clocking monitor_cb @(posedge pclk);
      input paddr, psel, penable, pwrite, prdata, pwdata;
   endclocking: monitor_cb
  
     // Define modports (different “views” of interface)
   modport master(clocking master_cb);
   modport slave(clocking slave_cb);
   modport passive(clocking monitor_cb);
     
     endinterface: apb_if

`endif