module raw_axi_master_connect (
    AXI_BUS.Slave slave,

    // Raw axi slave signals the given master will be connected to!
    output  logic [5-1:0]                           axi_awid,
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
    input   logic [5-1:0]                           axi_bid,
    input   logic [1:0]                             axi_bresp,
    input   logic                                   axi_bvalid,
    input   logic [3:0]                             axi_buser,
    output  logic                                   axi_bready,
    output  logic [5-1:0]                           axi_arid,
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
    input   logic [5-1:0]                           axi_rid,
    input   logic [63:0]                            axi_rdata,
    input   logic [1:0]                             axi_rresp,
    input   logic                                   axi_rlast,
    input   logic [3:0]                             axi_ruser,
    input   logic                                   axi_rvalid,
    output  logic                                   axi_rready
);

    ariane_axi::req_t master_req_i;
    ariane_axi::resp_t resp_o;

    axi_slave_connect masterCon (
        .axi_req_o(master_req_i),
        .axi_resp_i(resp_o),
        .slave(slave)
    );

    // Connect request signals
    ariane_axi::aw_chan_t axi_req_aw;
    ariane_axi::w_chan_t axi_req_w;
    ariane_axi::ar_chan_t axi_req_ar;

    assign axi_req_aw = master_req_i.aw;
    assign axi_req_w = master_req_i.w;
    assign axi_req_ar = master_req_i.ar;

    assign axi_awvalid = master_req_i.aw_valid;
    assign axi_wvalid = master_req_i.w_valid;
    assign axi_bready = master_req_i.b_ready;
    assign axi_arvalid = master_req_i.ar_valid;
    assign axi_rready = master_req_i.r_ready;

    // axi_req_aw aw_chant_t signals

    assign axi_awid = axi_req_aw.id;
    assign axi_awaddr = axi_req_aw.addr;
    assign axi_awlen = axi_req_aw.len;
    assign axi_awsize = axi_req_aw.size;
    assign axi_awburst = axi_req_aw.burst;
    assign axi_awlock = axi_req_aw.lock;
    assign axi_awcache = axi_req_aw.cache;
    assign axi_awprot = axi_req_aw.prot;
    assign axi_awqos = axi_req_aw.qos;
    assign axi_awregion = axi_req_aw.region;
    assign axi_awatop = axi_req_aw.atop;
    assign axi_awuser = axi_req_aw.user;

    // w_chan_t axi_req_w
    assign axi_wdata = axi_req_w.data;
    assign axi_wstrb = axi_req_w.strb;
    assign axi_wlast = axi_req_w.last;
    assign axi_wuser = axi_req_w.user;

    assign axi_arid = axi_req_ar.id;
    assign axi_araddr = axi_req_ar.addr;
    assign axi_arlen = axi_req_ar.len;
    assign axi_arsize = axi_req_ar.size;
    assign axi_arburst = axi_req_ar.burst;
    assign axi_arlock = axi_req_ar.lock;
    assign axi_arcache = axi_req_ar.cache;
    assign axi_arprot = axi_req_ar.prot;
    assign axi_arqos = axi_req_ar.qos;
    assign axi_arregion = axi_req_ar.region;
    assign axi_aruser = axi_req_ar.user;

    // Connect response signals!
    ariane_axi::b_chan_t axi_resp_b_chan;
    assign axi_resp_b_chan.id = axi_bid;
    assign axi_resp_b_chan.resp = axi_bresp;
    assign axi_resp_b_chan.user = axi_buser;

    ariane_axi::r_chan_t axi_resp_r_chan;
    assign axi_resp_r_chan.id = axi_rid;
    assign axi_resp_r_chan.data = axi_rdata;
    assign axi_resp_r_chan.resp = axi_rresp;
    assign axi_resp_r_chan.last = axi_rlast;
    assign axi_resp_r_chan.user = axi_ruser;

    assign resp_o.aw_ready = axi_awready;
    assign resp_o.ar_ready = axi_arready;
    assign resp_o.w_ready = axi_wready;
    assign resp_o.b_valid = axi_bvalid;
    assign resp_o.r_valid = axi_rvalid;

    assign resp_o.b = axi_resp_b_chan;
    assign resp_o.r = axi_resp_r_chan;

endmodule