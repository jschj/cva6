module raw_axi_master_struct_connect #(
    parameter int unsigned AXI_ID_WIDTH = 4,
    parameter type req_t = ariane_axi::req_t,
    parameter type resp_t = ariane_axi::resp_t
)(
    input   req_t master_req_i,
    output  resp_t resp_o,

    // Raw axi slave signals the given master will be connected to!
    output  logic [AXI_ID_WIDTH - 1:0]                           axi_awid,
    output  logic [63:0]                            axi_awaddr,
    output  logic [7:0]                             axi_awlen,
    output  logic [2:0]                             axi_awsize,
    output  logic [1:0]                             axi_awburst,
    output  logic                                   axi_awlock,
    output  logic [3:0]                             axi_awcache,
    output  logic [2:0]                             axi_awprot,
    output  logic [3:0]                             axi_awregion,
    output  logic [3:0]                             axi_awuser,
    output  logic [3:0]                             axi_awqos,
    output  logic [5:0]                             axi_awatop,
    output  logic                                   axi_awvalid,
    input   logic                                   axi_awready,
    output  logic [63:0]                            axi_wdata,
    output  logic [7:0]                             axi_wstrb,
    output  logic                                   axi_wlast,
    output  logic [3:0]                             axi_wuser,
    output  logic                                   axi_wvalid,
    input   logic                                   axi_wready,
    input   logic [AXI_ID_WIDTH - 1:0]                           axi_bid,
    input   logic [1:0]                             axi_bresp,
    input   logic                                   axi_bvalid,
    input   logic [3:0]                             axi_buser,
    output  logic                                   axi_bready,
    output  logic [AXI_ID_WIDTH - 1:0]                           axi_arid,
    output  logic [63:0]                            axi_araddr,
    output  logic [7:0]                             axi_arlen,
    output  logic [2:0]                             axi_arsize,
    output  logic [1:0]                             axi_arburst,
    output  logic                                   axi_arlock,
    output  logic [3:0]                             axi_arcache,
    output  logic [2:0]                             axi_arprot,
    output  logic [3:0]                             axi_arregion,
    output  logic [3:0]                             axi_aruser,
    output  logic [3:0]                             axi_arqos,
    output  logic                                   axi_arvalid,
    input   logic                                   axi_arready,
    input   logic [AXI_ID_WIDTH - 1:0]                           axi_rid,
    input   logic [63:0]                            axi_rdata,
    input   logic [1:0]                             axi_rresp,
    input   logic                                   axi_rlast,
    input   logic [3:0]                             axi_ruser,
    input   logic                                   axi_rvalid,
    output  logic                                   axi_rready
);
    // Connect request signals
    assign axi_awvalid = master_req_i.aw_valid;
    assign axi_wvalid = master_req_i.w_valid;
    assign axi_bready = master_req_i.b_ready;
    assign axi_arvalid = master_req_i.ar_valid;
    assign axi_rready = master_req_i.r_ready;

    // master_req_i.aw aw_chant_t signals

    assign axi_awid = master_req_i.aw.id;
    assign axi_awaddr = master_req_i.aw.addr;
    assign axi_awlen = master_req_i.aw.len;
    assign axi_awsize = master_req_i.aw.size;
    assign axi_awburst = master_req_i.aw.burst;
    assign axi_awlock = master_req_i.aw.lock;
    assign axi_awcache = master_req_i.aw.cache;
    assign axi_awprot = master_req_i.aw.prot;
    assign axi_awqos = master_req_i.aw.qos;
    assign axi_awregion = master_req_i.aw.region;
    assign axi_awatop = master_req_i.aw.atop;
    assign axi_awuser = master_req_i.aw.user;

    // w_chan_t master_req_i.w
    assign axi_wdata = master_req_i.w.data;
    assign axi_wstrb = master_req_i.w.strb;
    assign axi_wlast = master_req_i.w.last;
    assign axi_wuser = master_req_i.w.user;

    assign axi_arid = master_req_i.ar.id;
    assign axi_araddr = master_req_i.ar.addr;
    assign axi_arlen = master_req_i.ar.len;
    assign axi_arsize = master_req_i.ar.size;
    assign axi_arburst = master_req_i.ar.burst;
    assign axi_arlock = master_req_i.ar.lock;
    assign axi_arcache = master_req_i.ar.cache;
    assign axi_arprot = master_req_i.ar.prot;
    assign axi_arqos = master_req_i.ar.qos;
    assign axi_arregion = master_req_i.ar.region;
    assign axi_aruser = master_req_i.ar.user;

    // Connect response signals!
    assign resp_o.b.id = axi_bid;
    assign resp_o.b.resp = axi_bresp;
    assign resp_o.b.user = axi_buser;

    assign resp_o.r.id = axi_rid;
    assign resp_o.r.data = axi_rdata;
    assign resp_o.r.resp = axi_rresp;
    assign resp_o.r.last = axi_rlast;
    assign resp_o.r.user = axi_ruser;

    assign resp_o.aw_ready = axi_awready;
    assign resp_o.ar_ready = axi_arready;
    assign resp_o.w_ready = axi_wready;
    assign resp_o.b_valid = axi_bvalid;
    assign resp_o.r_valid = axi_rvalid;

endmodule