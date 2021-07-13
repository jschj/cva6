module raw_axi_slave_struct_connect #(
    parameter int unsigned AXI_ID_WIDTH = 4,
    parameter type req_t = ariane_axi::req_t,
    parameter type resp_t = ariane_axi::resp_t
)(
    output req_t master_req_o,
    input  resp_t resp_i,

    // Raw axi master signals the given slave will be connected to!
    input  logic [AXI_ID_WIDTH - 1:0]                           axi_awid,
    input  logic [63:0]                            axi_awaddr,
    input  logic [7:0]                             axi_awlen,
    input  logic [2:0]                             axi_awsize,
    input  logic [1:0]                             axi_awburst,
    input  logic                                   axi_awlock,
    input  logic [3:0]                             axi_awcache,
    input  logic [2:0]                             axi_awprot,
    input  logic [3:0]                             axi_awregion,
    input  logic [3:0]                             axi_awuser,
    input  logic [3:0]                             axi_awqos,
    input  logic [5:0]                             axi_awatop,
    input  logic                                   axi_awvalid,
    output   logic                                   axi_awready,
    input  logic [63:0]                            axi_wdata,
    input  logic [7:0]                             axi_wstrb,
    input  logic                                   axi_wlast,
    input  logic [3:0]                             axi_wuser,
    input  logic                                   axi_wvalid,
    output   logic                                   axi_wready,
    output   logic [AXI_ID_WIDTH - 1:0]                           axi_bid,
    output   logic [1:0]                             axi_bresp,
    output   logic                                   axi_bvalid,
    output   logic [3:0]                             axi_buser,
    input  logic                                   axi_bready,
    input  logic [AXI_ID_WIDTH - 1:0]                           axi_arid,
    input  logic [63:0]                            axi_araddr,
    input  logic [7:0]                             axi_arlen,
    input  logic [2:0]                             axi_arsize,
    input  logic [1:0]                             axi_arburst,
    input  logic                                   axi_arlock,
    input  logic [3:0]                             axi_arcache,
    input  logic [2:0]                             axi_arprot,
    input  logic [3:0]                             axi_arregion,
    input  logic [3:0]                             axi_aruser,
    input  logic [3:0]                             axi_arqos,
    input  logic                                   axi_arvalid,
    output   logic                                   axi_arready,
    output   logic [AXI_ID_WIDTH - 1:0]                           axi_rid,
    output   logic [63:0]                            axi_rdata,
    output   logic [1:0]                             axi_rresp,
    output   logic                                   axi_rlast,
    output   logic [3:0]                             axi_ruser,
    output   logic                                   axi_rvalid,
    input  logic                                   axi_rready
);

    // Connect request signals
    assign master_req_o.aw_valid = axi_awvalid;
    assign master_req_o.w_valid = axi_wvalid;
    assign master_req_o.b_ready = axi_bready;
    assign master_req_o.ar_valid = axi_arvalid;
    assign master_req_o.r_ready = axi_rready;

    // master_req_o.aw aw_chant_t signals

    assign master_req_o.aw.id = axi_awid;
    assign master_req_o.aw.addr = axi_awaddr;
    assign master_req_o.aw.len = axi_awlen;
    assign master_req_o.aw.size = axi_awsize;
    assign master_req_o.aw.burst = axi_awburst;
    assign master_req_o.aw.lock = axi_awlock;
    assign master_req_o.aw.cache = axi_awcache;
    assign master_req_o.aw.prot = axi_awprot;
    assign master_req_o.aw.qos = axi_awqos;
    assign master_req_o.aw.region = axi_awregion;
    assign master_req_o.aw.atop = axi_awatop;
    assign master_req_o.aw.user = axi_awuser;

    // w_chan_t master_req_o.w
    assign master_req_o.w.data = axi_wdata;
    assign master_req_o.w.strb = axi_wstrb;
    assign master_req_o.w.last = axi_wlast;
    assign master_req_o.w.user = axi_wuser;

    assign master_req_o.ar.id = axi_arid;
    assign master_req_o.ar.addr = axi_araddr;
    assign master_req_o.ar.len = axi_arlen;
    assign master_req_o.ar.size = axi_arsize;
    assign master_req_o.ar.burst = axi_arburst;
    assign master_req_o.ar.lock = axi_arlock;
    assign master_req_o.ar.cache = axi_arcache;
    assign master_req_o.ar.prot = axi_arprot;
    assign master_req_o.ar.qos = axi_arqos;
    assign master_req_o.ar.region = axi_arregion;
    assign master_req_o.ar.user = axi_aruser;

    // Connect response signals!
    assign axi_bid = resp_i.b.id;
    assign axi_bresp = resp_i.b.resp;
    assign axi_buser = resp_i.b.user;

    assign axi_rid = resp_i.r.id;
    assign axi_rdata = resp_i.r.data;
    assign axi_rresp = resp_i.r.resp;
    assign axi_rlast = resp_i.r.last;
    assign axi_ruser = resp_i.r.user;

    assign axi_awready = resp_i.aw_ready;
    assign axi_arready = resp_i.ar_ready;
    assign axi_wready = resp_i.w_ready;
    assign axi_bvalid = resp_i.b_valid;
    assign axi_rvalid = resp_i.r_valid;
endmodule