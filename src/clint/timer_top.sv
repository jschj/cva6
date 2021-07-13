module timer_top #(
    parameter int unsigned AXI_ID_WIDTH   = 5,
    parameter int unsigned NR_CORES       = 1 // Number of cores therefore also the number of timecmp registers and timer interrupts
)(
    input  logic                         clk_i,
    input  logic                         rst_ni,
    input  logic                         testmode_i,
    output logic [NR_CORES-1:0]          timer_irq_o,  // Timer interrupts
    output logic [NR_CORES-1:0]          ipi_o,        // software interrupt (a.k.a inter-process-interrupt)

    // memory side, AXI Slave
    input  logic [AXI_ID_WIDTH-1:0]                             axi_timer_awid,
    input  logic [63:0]                            axi_timer_awaddr,
    input  logic [7:0]                             axi_timer_awlen,
    input  logic [2:0]                             axi_timer_awsize,
    input  logic [1:0]                             axi_timer_awburst,
    input  logic                                   axi_timer_awlock,
    input  logic [3:0]                             axi_timer_awcache,
    input  logic [2:0]                             axi_timer_awprot,
    input  logic [3:0]                             axi_timer_awregion,
    input  logic [3:0]                             axi_timer_awuser,
    input  logic [3:0]                             axi_timer_awqos,
    input  logic [5:0]                             axi_timer_awatop,
    input  logic                                   axi_timer_awvalid,
    output logic                                   axi_timer_awready,
    input  logic [63:0]                            axi_timer_wdata,
    input  logic [7:0]                             axi_timer_wstrb,
    input  logic                                   axi_timer_wlast,
    input  logic [3:0]                             axi_timer_wuser,
    input  logic                                   axi_timer_wvalid,
    output logic                                   axi_timer_wready,
    output logic [AXI_ID_WIDTH-1:0]                             axi_timer_bid,
    output logic [1:0]                             axi_timer_bresp,
    output logic                                   axi_timer_bvalid,
    output logic [3:0]                             axi_timer_buser,
    input  logic                                   axi_timer_bready,
    input  logic [AXI_ID_WIDTH-1:0]                             axi_timer_arid,
    input  logic [63:0]                            axi_timer_araddr,
    input  logic [7:0]                             axi_timer_arlen,
    input  logic [2:0]                             axi_timer_arsize,
    input  logic [1:0]                             axi_timer_arburst,
    input  logic                                   axi_timer_arlock,
    input  logic [3:0]                             axi_timer_arcache,
    input  logic [2:0]                             axi_timer_arprot,
    input  logic [3:0]                             axi_timer_arregion,
    input  logic [3:0]                             axi_timer_aruser,
    input  logic [3:0]                             axi_timer_arqos,
    input  logic                                   axi_timer_arvalid,
    output logic                                   axi_timer_arready,
    output logic [AXI_ID_WIDTH-1:0]                             axi_timer_rid,
    output logic [63:0]                            axi_timer_rdata,
    output logic [1:0]                             axi_timer_rresp,
    output logic                                   axi_timer_rlast,
    output logic [3:0]                             axi_timer_ruser,
    output logic                                   axi_timer_rvalid,
    input  logic                                   axi_timer_rready
);

    logic rtc;

    // ---------------
    // CLINT
    // ---------------
    // divide clock by two
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            rtc <= 0;
        end else begin
            rtc <= rtc ^ 1'b1;
        end
    end

    /*
        OUTPUT
    */
    tapasco_axi::req_slv_t axi_req_o;
    tapasco_axi::resp_slv_t axi_resp_i;

    clint#(
        .AXI_ID_WIDTH(tapasco_axi::IdWidthSlave),
        .NR_CORES(NR_CORES),
        .req_t(tapasco_axi::req_slv_t),
        .resp_t(tapasco_axi::resp_slv_t)
    ) timer(
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        // Timer facilities
        .timer_irq_o(timer_irq_o),
        .ipi_o(ipi_o),
        .rtc_i(rtc),
        .testmode_i(testmode_i),

        // memory side, AXI Master
        .axi_req_i(axi_req_o),
        .axi_resp_o(axi_resp_i)
    );

    // Connect slave pins
    raw_axi_slave_connect #(
        .AXI_ID_WIDTH(tapasco_axi::IdWidthSlave),
        .req_t(tapasco_axi::req_slv_t),
        .resp_t(tapasco_axi::resp_slv_t)
    ) dmMemConnect (
        .master(master.Master),

        .axi_awid(axi_dm_slave_awid),
        .axi_awaddr(axi_dm_slave_awaddr),
        .axi_awlen(axi_dm_slave_awlen),
        .axi_awsize(axi_dm_slave_awsize),
        .axi_awburst(axi_dm_slave_awburst),
        .axi_awlock(axi_dm_slave_awlock),
        .axi_awcache(axi_dm_slave_awcache),
        .axi_awprot(axi_dm_slave_awprot),
        .axi_awregion(axi_dm_slave_awregion),
        .axi_awuser(axi_dm_slave_awuser),
        .axi_awqos(axi_dm_slave_awqos),
        .axi_awatop(axi_dm_slave_awatop),
        .axi_awvalid(axi_dm_slave_awvalid),
        .axi_awready(axi_dm_slave_awready),
        .axi_wdata(axi_dm_slave_wdata),
        .axi_wstrb(axi_dm_slave_wstrb),
        .axi_wlast(axi_dm_slave_wlast),
        .axi_wuser(axi_dm_slave_wuser),
        .axi_wvalid(axi_dm_slave_wvalid),
        .axi_wready(axi_dm_slave_wready),
        .axi_bid(axi_dm_slave_bid),
        .axi_bresp(axi_dm_slave_bresp),
        .axi_bvalid(axi_dm_slave_bvalid),
        .axi_buser(axi_dm_slave_buser),
        .axi_bready(axi_dm_slave_bready),
        .axi_arid(axi_dm_slave_arid),
        .axi_araddr(axi_dm_slave_araddr),
        .axi_arlen(axi_dm_slave_arlen),
        .axi_arsize(axi_dm_slave_arsize),
        .axi_arburst(axi_dm_slave_arburst),
        .axi_arlock(axi_dm_slave_arlock),
        .axi_arcache(axi_dm_slave_arcache),
        .axi_arprot(axi_dm_slave_arprot),
        .axi_arregion(axi_dm_slave_arregion),
        .axi_aruser(axi_dm_slave_aruser),
        .axi_arqos(axi_dm_slave_arqos),
        .axi_arvalid(axi_dm_slave_arvalid),
        .axi_arready(axi_dm_slave_arready),
        .axi_rid(axi_dm_slave_rid),
        .axi_rdata(axi_dm_slave_rdata),
        .axi_rresp(axi_dm_slave_rresp),
        .axi_rlast(axi_dm_slave_rlast),
        .axi_ruser(axi_dm_slave_ruser),
        .axi_rvalid(axi_dm_slave_rvalid),
        .axi_rready(axi_dm_slave_rready)
    );

endmodule