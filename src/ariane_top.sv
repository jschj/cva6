/*
  // 4 is recommended by AXI standard, so lets stick to it, do not change
  `define IdWidth 4
  `define UserWidth 1
  `define AddrWidth 64
  `define DataWidth 64
  `define StrbWidth (`DataWidth/8)

  typedef logic [`IdWidth-1:0]   id_t;
  typedef logic [`AddrWidth-1:0] addr_t;
  typedef logic [`DataWidth-1:0] data_t;
  typedef logic [`StrbWidth-1:0] strb_t;
  typedef logic [`UserWidth-1:0] user_t;

  // AW Channel
  typedef struct packed {
      id_t     id;
      addr_t   addr;
      len_t    len;
      size_t   size;
      burst_t  burst;
      logic   lock;
      cache_t  cache;
      prot_t   prot;
      qos_t    qos;
      region_t region;
      atop_t   atop;
  } aw_chan_t;

  // W Channel
  typedef struct packed {
      data_t data;
      strb_t strb;
      logic  last;
  } w_chan_t;

  // B Channel
  typedef struct packed {
      id_t   id;
      resp_t resp;
  } b_chan_t;

  // AR Channel
  typedef struct packed {
      id_t     id;
      addr_t   addr;
      len_t    len;
      size_t   size;
      burst_t  burst;
      logic    lock;
      cache_t  cache;
      prot_t   prot;
      qos_t    qos;
      region_t region;
  } ar_chan_t;

  // R Channel
  typedef struct packed {
      id_t   id;
      data_t data;
      resp_t resp;
      logic  last;
  } r_chan_t;
*/
module ariane_top (
  input  logic                         clk_i,
  input  logic                         rst_ni,
  // Core ID, Cluster ID and boot address are considered more or less static
  input  logic [63:0]                  boot_addr_i,  // reset boot address
  input  logic [63:0]                  hart_id_i,    // hart id in a multicore environment (reflected in a CSR)

  // Interrupt inputs
  input  logic [1:0]                   irq_i,        // level sensitive IR lines, mip & sip (async)
  input  logic                         ipi_i,        // inter-processor interrupts (async)
  // Timer facilities
  input  logic                         time_irq_i,   // timer interrupt in (async)
  input  logic                         debug_req_i//,  // debug request (async)

  // memory side, AXI Master
  /*
  output aw_chan_t aw;
  output logic     aw_valid;
  output w_chan_t  w;
  output logic     w_valid;
  output logic     b_ready;
  output ar_chan_t ar;
  output logic     ar_valid;
  output logic     r_ready;

  input logic     aw_ready;
  input logic     ar_ready;
  input logic     w_ready;
  input logic     b_valid;
  input b_chan_t  b;
  input logic     r_valid;
  //input r_chan_t  r;
  input id_t   id;
  input data_t data;
  input resp_t resp;
  input logic  last;
  */
);
    /*
    typedef struct packed {
        id_t            id;
        data_t          data;
        axi_pkg::resp_t resp;
        logic           last;
        user_t          user;
    } r_chan_t;

    typedef struct packed {
        logic     aw_ready;
        logic     ar_ready;
        logic     w_ready;
        logic     b_valid;
        b_chan_t  b;
        logic     r_valid;
        r_chan_t  r;
    } resp_t;


    ariane_axi::req_t axi_req_o;
    ariane_axi::aw_chan_t axi_req_o_aw;

    assign axi_req_o.aw =;
    assign axi_req_o.aw_valid =;
    assign axi_req_o.w =;
    assign axi_req_o.w_valid =;
    assign axi_req_o.b_ready =;
    assign axi_req_o.ar =;
    assign axi_req_o.ar_valid =;
    assign axi_req_o.r_ready =;
    */
    /*
    // Request/Response structs
    typedef struct packed {
        aw_chan_t aw;
        logic     aw_valid;
        w_chan_t  w;
        logic     w_valid;
        logic     b_ready;
        ar_chan_t ar;
        logic     ar_valid;
        logic     r_ready;
    } req_t;
    */


    //ariane_axi::resp_t axi_resp_i;

    ariane#(

    ) core(
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        // Core ID, Cluster ID and boot address are considered more or less static
        .boot_addr_i(boot_addr_i),      // reset boot address
        .hart_id_i(hart_id_i),          // hart id in a multicore environment (reflected in a CSR)
        // Interrupt inputs
        .irq_i(irq_i),                  // level sensitive IR lines, mip & sip (async)
        .ipi_i(ipi_i),                  // inter-processor interrupts (async)
        // Timer facilities
        .time_irq_i(time_irq_i),        // timer interrupt in (async)
        .debug_req_i(debug_req_i),      // debug request (async)

        // memory side, AXI Master
        //axi_req_o.(axi_resp_o),
        //axi_resp_i.(axi_resp_i)
    );

endmodule