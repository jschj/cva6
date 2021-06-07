import ariane_pkg::*;

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
    input  logic                         debug_req_i,  // debug request (async)

    // memory side, AXI Master
    output  logic [3:0]                             io_axi_mem_awid,
    output  logic [63:0]                            io_axi_mem_awaddr,
    output  logic [7:0]                             io_axi_mem_awlen,
    output  logic [2:0]                             io_axi_mem_awsize,
    output  logic [1:0]                             io_axi_mem_awburst,
    output  logic                                   io_axi_mem_awlock,
    output  logic [3:0]                             io_axi_mem_awcache,
    output  logic [2:0]                             io_axi_mem_awprot,
    output  logic [3:0]                             io_axi_mem_awregion,
    output  logic [3:0]                             io_axi_mem_awuser,
    output  logic [3:0]                             io_axi_mem_awqos,
    output  logic [5:0]                             io_axi_mem_awatop,
    output  logic                                   io_axi_mem_awvalid,
    input   logic                                   io_axi_mem_awready,
    output  logic [63:0]                            io_axi_mem_wdata,
    output  logic [7:0]                             io_axi_mem_wstrb,
    output  logic                                   io_axi_mem_wlast,
    output  logic [3:0]                             io_axi_mem_wuser,
    output  logic                                   io_axi_mem_wvalid,
    input   logic                                   io_axi_mem_wready,
    input   logic [3:0]                             io_axi_mem_bid,
    input   logic [1:0]                             io_axi_mem_bresp,
    input   logic                                   io_axi_mem_bvalid,
    input   logic [3:0]                             io_axi_mem_buser,
    output  logic                                   io_axi_mem_bready,
    output  logic [3:0]                             io_axi_mem_arid,
    output  logic [63:0]                            io_axi_mem_araddr,
    output  logic [7:0]                             io_axi_mem_arlen,
    output  logic [2:0]                             io_axi_mem_arsize,
    output  logic [1:0]                             io_axi_mem_arburst,
    output  logic                                   io_axi_mem_arlock,
    output  logic [3:0]                             io_axi_mem_arcache,
    output  logic [2:0]                             io_axi_mem_arprot,
    output  logic [3:0]                             io_axi_mem_arregion,
    output  logic [3:0]                             io_axi_mem_aruser,
    output  logic [3:0]                             io_axi_mem_arqos,
    output  logic                                   io_axi_mem_arvalid,
    input   logic                                   io_axi_mem_arready,
    input   logic [3:0]                             io_axi_mem_rid,
    input   logic [63:0]                            io_axi_mem_rdata,
    input   logic [1:0]                             io_axi_mem_rresp,
    input   logic                                   io_axi_mem_rlast,
    input   logic [3:0]                             io_axi_mem_ruser,
    input   logic                                   io_axi_mem_rvalid,
    output  logic                                   io_axi_mem_rready
);

    /*
        OUTPUT
    */
    /*
    localparam IdWidth   = 4; // Recommended by AXI standard
    localparam UserWidth = 1;
    localparam AddrWidth = 64;
    localparam DataWidth = 64;
    localparam StrbWidth = DataWidth / 8;

    typedef logic   [IdWidth-1:0]   id_t;
    typedef logic [AddrWidth-1:0] addr_t;
    typedef logic [DataWidth-1:0] data_t;
    typedef logic [StrbWidth-1:0] strb_t;
    typedef logic [UserWidth-1:0] user_t;

    logic io_axi_mem_awvalid;
    logic io_axi_mem_wvalid;
    logic io_axi_mem_bready;
    logic io_axi_mem_arvalid;
    logic io_axi_mem_rready;
    logic io_axi_mem_awlock;
    id_t  io_axi_mem_awid;
    addr_t io_axi_mem_awaddr;
    user_t io_axi_mem_awuser;

    typedef logic [1:0] burst_t;
    typedef logic [1:0] resp_t;
    typedef logic [3:0] cache_t;
    typedef logic [2:0] prot_t;
    typedef logic [3:0] qos_t;
    typedef logic [3:0] region_t;
    typedef logic [7:0] len_t;
    typedef logic [2:0] size_t;
    typedef logic [5:0] atop_t; // atomic operations
    typedef logic [3:0] nsaid_t; // non-secure address identifier

    len_t    io_axi_mem_awlen;
    size_t   io_axi_mem_awsize;
    burst_t  io_axi_mem_awburst;
    cache_t  io_axi_mem_awcache;
    prot_t   io_axi_mem_awprot;
    qos_t    io_axi_mem_awqos;
    region_t io_axi_mem_awregion;
    atop_t   io_axi_mem_awatop;
    
    data_t io_axi_mem_wdata;
    strb_t io_axi_mem_wstrb;
    logic  io_axi_mem_wlast;
    user_t io_axi_mem_wuser;

    id_t     io_axi_mem_arid;
    addr_t   io_axi_mem_araddr;
    len_t    io_axi_mem_arlen;
    size_t   io_axi_mem_arsize;
    burst_t  io_axi_mem_arburst;
    logic    io_axi_mem_arlock;
    cache_t  io_axi_mem_arcache;
    prot_t   io_axi_mem_arprot;
    qos_t    io_axi_mem_arqos;
    region_t io_axi_mem_arregion;
    user_t   io_axi_mem_aruser;
    */

    ariane_axi::req_t axi_req_o;
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
    ariane_axi::aw_chan_t axi_req_o_aw;
    /*
    typedef struct packed {
        id_t              id;
        addr_t            addr;
        axi_pkg::len_t    len;
        axi_pkg::size_t   size;
        axi_pkg::burst_t  burst;
        logic             lock;
        axi_pkg::cache_t  cache;
        axi_pkg::prot_t   prot;
        axi_pkg::qos_t    qos;
        axi_pkg::region_t region;
        axi_pkg::atop_t   atop;
        user_t            user;
    } aw_chan_t;
    */
    ariane_axi::w_chan_t axi_req_o_w;
    /*
    typedef struct packed {
        data_t data;
        strb_t strb;
        logic  last;
        user_t user;
    } w_chan_t;
    */
    ariane_axi::ar_chan_t axi_req_o_ar;
    /*
    typedef struct packed {
        id_t             id;
        addr_t            addr;
        axi_pkg::len_t    len;
        axi_pkg::size_t   size;
        axi_pkg::burst_t  burst;
        logic             lock;
        axi_pkg::cache_t  cache;
        axi_pkg::prot_t   prot;
        axi_pkg::qos_t    qos;
        axi_pkg::region_t region;
        user_t            user;
    } ar_chan_t;
    */

    assign axi_req_o_aw = axi_req_o.aw;
    assign axi_req_o_w = axi_req_o.w;
    assign axi_req_o_ar = axi_req_o.ar;
    assign io_axi_mem_awvalid = axi_req_o.aw_valid;
    assign io_axi_mem_wvalid = axi_req_o.w_valid;
    assign io_axi_mem_bready = axi_req_o.b_ready;
    assign io_axi_mem_arvalid = axi_req_o.ar_valid;
    assign io_axi_mem_rready = axi_req_o.r_ready;

    // axi_req_o_aw aw_chant_t signals

    assign io_axi_mem_awid = axi_req_o_aw.id;
    assign io_axi_mem_awaddr = axi_req_o_aw.addr;
    assign io_axi_mem_awlen = axi_req_o_aw.len;
    assign io_axi_mem_awsize = axi_req_o_aw.size;
    assign io_axi_mem_awburst = axi_req_o_aw.burst;
    assign io_axi_mem_awlock = axi_req_o_aw.lock;
    assign io_axi_mem_awcache = axi_req_o_aw.cache;
    assign io_axi_mem_awprot = axi_req_o_aw.prot;
    assign io_axi_mem_awqos = axi_req_o_aw.qos;
    assign io_axi_mem_awregion = axi_req_o_aw.region;
    assign io_axi_mem_awatop = axi_req_o_aw.atop;
    assign io_axi_mem_awuser = axi_req_o_aw.user;

    // w_chan_t axi_req_o_w
    assign io_axi_mem_wdata = axi_req_o_w.data;
    assign io_axi_mem_wstrb = axi_req_o_w.strb;
    assign io_axi_mem_wlast = axi_req_o_w.last;
    assign io_axi_mem_wuser = axi_req_o_w.user;

    assign io_axi_mem_arid = axi_req_o_ar.id;
    assign io_axi_mem_araddr = axi_req_o_ar.addr;
    assign io_axi_mem_arlen = axi_req_o_ar.len;
    assign io_axi_mem_arsize = axi_req_o_ar.size;
    assign io_axi_mem_arburst = axi_req_o_ar.burst;
    assign io_axi_mem_arlock = axi_req_o_ar.lock;
    assign io_axi_mem_arcache = axi_req_o_ar.cache;
    assign io_axi_mem_arprot = axi_req_o_ar.prot;
    assign io_axi_mem_arqos = axi_req_o_ar.qos;
    assign io_axi_mem_arregion = axi_req_o_ar.region;
    assign io_axi_mem_aruser = axi_req_o_ar.user;







    /*
        INPUT
    */

    /*
    typedef logic   [IdWidth-1:0]   id_t;
    typedef logic [AddrWidth-1:0] addr_t;
    typedef logic [DataWidth-1:0] data_t;
    typedef logic [StrbWidth-1:0] strb_t;
    typedef logic [UserWidth-1:0] user_t;

    typedef logic [1:0] burst_t;
    typedef logic [1:0] resp_t;
    typedef logic [3:0] cache_t;
    typedef logic [2:0] prot_t;
    typedef logic [3:0] qos_t;
    typedef logic [3:0] region_t;
    typedef logic [7:0] len_t;
    typedef logic [2:0] size_t;
    typedef logic [5:0] atop_t; // atomic operations
    typedef logic [3:0] nsaid_t; // non-secure address identifier

    typedef struct packed {
        id_t            id;
        axi_pkg::resp_t resp;
        user_t          user;
    } b_chan_t;

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
     */

    ariane_axi::b_chan_t axi_resp_i_b_chan;
    assign axi_resp_i_b_chan.id = io_axi_mem_bid;
    assign axi_resp_i_b_chan.resp = io_axi_mem_bresp;
    assign axi_resp_i_b_chan.user = io_axi_mem_buser;

    ariane_axi::r_chan_t axi_resp_i_r_chan;
    assign axi_resp_i_r_chan.id = io_axi_mem_rid;
    assign axi_resp_i_r_chan.data = io_axi_mem_rdata;
    assign axi_resp_i_r_chan.resp = io_axi_mem_rresp;
    assign axi_resp_i_r_chan.last = io_axi_mem_rlast;
    assign axi_resp_i_r_chan.user = io_axi_mem_ruser;

    ariane_axi::resp_t axi_resp_i;
    assign axi_resp_i.aw_ready = io_axi_mem_awready;
    assign axi_resp_i.ar_ready = io_axi_mem_arready;
    assign axi_resp_i.w_ready = io_axi_mem_wready;
    assign axi_resp_i.b_valid = io_axi_mem_bvalid;
    assign axi_resp_i.b = axi_resp_i_b_chan;
    assign axi_resp_i.r_valid = io_axi_mem_rvalid;
    assign axi_resp_i.r = axi_resp_i_r_chan;

    ariane_pkg::ariane_cfg_t ArianeCfg = ariane_pkg::ArianeDefaultConfig;

    ariane#(
        .ArianeCfg(ArianeCfg)
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
        .axi_req_o(axi_req_o),
        .axi_resp_i(axi_resp_i)
    );

endmodule