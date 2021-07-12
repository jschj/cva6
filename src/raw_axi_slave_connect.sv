module raw_axi_slave_connect (
    AXI_BUS.Master master,

    // Raw axi master signals the given slave will be connected to!
    input  logic [5-1:0]                           axi_awid,
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
    output   logic [5-1:0]                           axi_bid,
    output   logic [1:0]                             axi_bresp,
    output   logic                                   axi_bvalid,
    output   logic [3:0]                             axi_buser,
    input  logic                                   axi_bready,
    input  logic [5-1:0]                           axi_arid,
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
    output   logic [5-1:0]                           axi_rid,
    output   logic [63:0]                            axi_rdata,
    output   logic [1:0]                             axi_rresp,
    output   logic                                   axi_rlast,
    output   logic [3:0]                             axi_ruser,
    output   logic                                   axi_rvalid,
    input  logic                                   axi_rready
);

    ariane_axi::req_t master_req_o;
    ariane_axi::resp_t resp_i;

    axi_master_connect slaveCon (
        .axi_req_i(master_req_o),
        .axi_resp_o(resp_i),
        .master(master)
    );

    // Connect request signals
    ariane_axi::aw_chan_t axi_req_aw;
    ariane_axi::w_chan_t axi_req_w;
    ariane_axi::ar_chan_t axi_req_ar;

    assign master_req_o.aw = axi_req_aw;
    assign master_req_o.w = axi_req_w;
    assign master_req_o.ar = axi_req_ar;

    assign master_req_o.aw_valid = axi_awvalid;
    assign master_req_o.w_valid = axi_wvalid;
    assign master_req_o.b_ready = axi_bready;
    assign master_req_o.ar_valid = axi_arvalid;
    assign master_req_o.r_ready = axi_rready;

    // axi_req_aw aw_chant_t signals

    assign axi_req_aw.id = axi_awid;
    assign axi_req_aw.addr = axi_awaddr;
    assign axi_req_aw.len = axi_awlen;
    assign axi_req_aw.size = axi_awsize;
    assign axi_req_aw.burst = axi_awburst;
    assign axi_req_aw.lock = axi_awlock;
    assign axi_req_aw.cache = axi_awcache;
    assign axi_req_aw.prot = axi_awprot;
    assign axi_req_aw.qos = axi_awqos;
    assign axi_req_aw.region = axi_awregion;
    assign axi_req_aw.atop = axi_awatop;
    assign axi_req_aw.user = axi_awuser;

    // w_chan_t axi_req_w
    assign axi_req_w.data = axi_wdata;
    assign axi_req_w.strb = axi_wstrb;
    assign axi_req_w.last = axi_wlast;
    assign axi_req_w.user = axi_wuser;

    assign axi_req_ar.id = axi_arid;
    assign axi_req_ar.addr = axi_araddr;
    assign axi_req_ar.len = axi_arlen;
    assign axi_req_ar.size = axi_arsize;
    assign axi_req_ar.burst = axi_arburst;
    assign axi_req_ar.lock = axi_arlock;
    assign axi_req_ar.cache = axi_arcache;
    assign axi_req_ar.prot = axi_arprot;
    assign axi_req_ar.qos = axi_arqos;
    assign axi_req_ar.region = axi_arregion;
    assign axi_req_ar.user = axi_aruser;

    // Connect response signals!
    ariane_axi::b_chan_t axi_resp_b_chan;
    assign axi_bid = axi_resp_b_chan.id;
    assign axi_bresp = axi_resp_b_chan.resp;
    assign axi_buser = axi_resp_b_chan.user;

    ariane_axi::r_chan_t axi_resp_r_chan;
    assign axi_rid = axi_resp_r_chan.id;
    assign axi_rdata = axi_resp_r_chan.data;
    assign axi_rresp = axi_resp_r_chan.resp;
    assign axi_rlast = axi_resp_r_chan.last;
    assign axi_ruser = axi_resp_r_chan.user;

    assign axi_awready = resp_i.aw_ready;
    assign axi_arready = resp_i.ar_ready;
    assign axi_wready = resp_i.w_ready;
    assign axi_bvalid = resp_i.b_valid;
    assign axi_rvalid = resp_i.r_valid;

    assign axi_resp_b_chan = resp_i.b;
    assign axi_resp_r_chan = resp_i.r;

endmodule