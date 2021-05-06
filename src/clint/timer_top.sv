module timer_top (
    input  logic                         clk_i,
    input  logic                         rst_ni,
    input  logic                         testmode_i,
    output logic [NR_CORES-1:0]          timer_irq_o,  // Timer interrupts
    output logic [NR_CORES-1:0]          ipi_o,        // software interrupt (a.k.a inter-process-interrupt)

    // memory side, AXI Master
    output  logic [3:0]                             axi_timer_awid,
    output  logic [63:0]                            axi_timer_awaddr,
    output  logic [7:0]                             axi_timer_awlen,
    output  logic [2:0]                             axi_timer_awsize,
    output  logic [1:0]                             axi_timer_awburst,
    output  logic                                   axi_timer_awlock,
    output  logic [3:0]                             axi_timer_awcache,
    output  logic [2:0]                             axi_timer_awprot,
    output  logic [3:0]                             axi_timer_awregion,
    output  logic [3:0]                             axi_timer_awuser,
    output  logic [3:0]                             axi_timer_awqos,
    output  logic                                   axi_timer_awvalid,
    input   logic                                   axi_timer_awready,
    output  logic [63:0]                            axi_timer_wdata,
    output  logic [7:0]                             axi_timer_wstrb,
    output  logic                                   axi_timer_wlast,
    output  logic [3:0]                             axi_timer_wuser,
    output  logic                                   axi_timer_wvalid,
    input   logic                                   axi_timer_wready,
    input   logic [3:0]                             axi_timer_bid,
    input   logic [1:0]                             axi_timer_bresp,
    input   logic                                   axi_timer_bvalid,
    input   logic [3:0]                             axi_timer_buser,
    output  logic                                   axi_timer_bready,
    output  logic [3:0]                             axi_timer_arid,
    output  logic [63:0]                            axi_timer_araddr,
    output  logic [7:0]                             axi_timer_arlen,
    output  logic [2:0]                             axi_timer_arsize,
    output  logic [1:0]                             axi_timer_arburst,
    output  logic                                   axi_timer_arlock,
    output  logic [3:0]                             axi_timer_arcache,
    output  logic [2:0]                             axi_timer_arprot,
    output  logic [3:0]                             axi_timer_arregion,
    output  logic [3:0]                             axi_timer_aruser,
    output  logic [3:0]                             axi_timer_arqos,
    output  logic                                   axi_timer_arvalid,
    input   logic                                   axi_timer_arready,
    input   logic [3:0]                             axi_timer_rid,
    input   logic [63:0]                            axi_timer_rdata,
    input   logic [1:0]                             axi_timer_rresp,
    input   logic                                   axi_timer_rlast,
    input   logic [3:0]                             axi_timer_ruser,
    input   logic                                   axi_timer_rvalid,
    output  logic                                   axi_timer_rready
);

    logic rtc;

    // ---------------
    // CLINT
    // ---------------
    // divide clock by two
    always_ff @(posedge clk or negedge ndmreset_n) begin
        if (~rst_ni) begin
            rtc <= 0;
        end else begin
            rtc <= rtc ^ 1'b1;
        end
    end

    /*
        OUTPUT
    */
    ariane_axi::req_t axi_req_o;
    ariane_axi::aw_chan_t axi_req_o_aw;
    ariane_axi::w_chan_t axi_req_o_w;
    ariane_axi::ar_chan_t axi_req_o_ar;

    assign axi_req_o.aw = axi_req_o_aw;
    assign axi_req_o.w = axi_req_o_w;
    assign axi_req_o.ar = axi_req_o_ar;
    assign axi_req_o.aw_valid = axi_timer_awvalid;
    assign axi_req_o.w_valid = axi_timer_wvalid;
    assign axi_req_o.b_ready = axi_timer_bready;
    assign axi_req_o.ar_valid = axi_timer_arvalid;
    assign axi_req_o.r_ready = axi_timer_rready;

    // axi_req_o_aw aw_chant_t signals

    assign axi_req_o_aw.id = axi_timer_awid;
    assign axi_req_o_aw.addr = axi_timer_awaddr;
    assign axi_req_o_aw.len = axi_timer_awlen;
    assign axi_req_o_aw.size = axi_timer_awsize;
    assign axi_req_o_aw.burst = axi_timer_awburst;
    assign axi_req_o_aw.lock = axi_timer_awlock;
    assign axi_req_o_aw.cache = axi_timer_awcache;
    assign axi_req_o_aw.prot = axi_timer_awprot;
    assign axi_req_o_aw.qos = axi_timer_awqos;
    assign axi_req_o_aw.region = axi_timer_awregion;
    assign axi_req_o_aw.atop = axi_timer_awatop;
    assign axi_req_o_aw.user = axi_timer_awuser;

    // w_chan_t axi_req_o_w
    assign axi_req_o_w.data = axi_timer_wdata;
    assign axi_req_o_w.strb = axi_timer_wstrb;
    assign axi_req_o_w.last = axi_timer_wlast;
    assign axi_req_o_w.user = axi_timer_wuser;

    assign axi_req_o_ar.id = axi_timer_arid;
    assign axi_req_o_ar.addr = axi_timer_araddr;
    assign axi_req_o_ar.len = axi_timer_arlen;
    assign axi_req_o_ar.size = axi_timer_arsize;
    assign axi_req_o_ar.burst = axi_timer_arburst;
    assign axi_req_o_ar.lock = axi_timer_arlock;
    assign axi_req_o_ar.cache = axi_timer_arcache;
    assign axi_req_o_ar.prot = axi_timer_arprot;
    assign axi_req_o_ar.qos = axi_timer_arqos;
    assign axi_req_o_ar.region = axi_timer_arregion;
    assign axi_req_o_ar.user = axi_timer_aruser;

    /*
        INPUT
    */
    ariane_axi::b_chan_t axi_resp_i_b_chan;
    assign axi_timer_bid = axi_resp_i_b_chan.id;
    assign axi_timer_bresp = axi_resp_i_b_chan.resp;
    assign axi_timer_buser = axi_resp_i_b_chan.user;

    ariane_axi::r_chan_t axi_resp_i_r_chan;
    assign axi_timer_rid = axi_resp_i_r_chan.id;
    assign axi_timer_rdata = axi_resp_i_r_chan.data;
    assign axi_timer_rresp = axi_resp_i_r_chan.resp_t;
    assign axi_timer_rlast = axi_resp_i_r_chan.last;
    assign axi_timer_ruser = axi_resp_i_r_chan.user;

    ariane_axi::resp_t axi_resp_i;
    assign axi_timer_awready = axi_resp_i.aw_ready;
    assign axi_timer_arready = axi_resp_i.ar_ready;
    assign axi_timer_wready = axi_resp_i.w_ready;
    assign axi_timer_bvalid = axi_resp_i.b_valid;
    assign axi_resp_i_b_chan = axi_resp_i.b;
    assign axi_timer_rvalid = axi_resp_i.r_valid;
    assign axi_resp_i_r_chan = axi_resp_i_r;

    clint#(

    ) timer(
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        // Timer facilities
        .timer_irq_o(timer_irq_o),
        .ipi_o(ipi_o),
        .rtc_i(rtc),
        .testmode_i(testmode_i),

        // memory side, AXI Master
        .axi_req_i(axi_req_i),
        .axi_resp_o(axi_resp_o)
    );

endmodule