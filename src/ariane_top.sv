module ariane_top #(
    parameter logic[63:0] DEBUG_LENGTH    = 64'h1000,
    parameter logic[63:0] IMEM_LENGTH      = 64'h04000,
    parameter logic[63:0] CLINT_LENGTH    = 64'hC0000,
    parameter logic[63:0] DMEM_LENGTH     = 64'h04000,
    //parameter logic[63:0] DRAM_LENGTH     = 64'h04000,

    parameter logic[63:0] DEBUG_BASE    = 64'h0000_0000,
    parameter logic[63:0] IMEM_BASE      = 64'h0000_0000,
    parameter logic[63:0] CLINT_BASE    = 64'h0200_0000,
    //parameter logic[63:0] DRAM_BASE     = 64'h0004_0000,
    parameter logic[63:0] DMEM_BASE     = 64'h0004_0000,
    parameter int unsigned AXI_ID_WIDTH   = 4
)(
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
    output  logic [AXI_ID_WIDTH-1:0]                             io_axi_mem_awid,
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
    input   logic [AXI_ID_WIDTH-1:0]                             io_axi_mem_bid,
    input   logic [1:0]                             io_axi_mem_bresp,
    input   logic                                   io_axi_mem_bvalid,
    input   logic [3:0]                             io_axi_mem_buser,
    output  logic                                   io_axi_mem_bready,
    output  logic [AXI_ID_WIDTH-1:0]                             io_axi_mem_arid,
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
    input   logic [AXI_ID_WIDTH-1:0]                             io_axi_mem_rid,
    input   logic [63:0]                            io_axi_mem_rdata,
    input   logic [1:0]                             io_axi_mem_rresp,
    input   logic                                   io_axi_mem_rlast,
    input   logic [3:0]                             io_axi_mem_ruser,
    input   logic                                   io_axi_mem_rvalid,
    output  logic                                   io_axi_mem_rready
);

    localparam ariane_pkg::ariane_cfg_t ArianeCfg = '{
        RASDepth: 2,
        BTBEntries: 32,
        BHTEntries: 128,
        // idempotent region
        NrNonIdempotentRules:  1,
        NonIdempotentAddrBase: {64'b0},
        //NonIdempotentLength:   {DRAM_BASE},
        NonIdempotentLength:   {64'b0},
        //NrExecuteRegionRules:  4,
        NrExecuteRegionRules:  3,
        ExecuteRegionAddrBase: {DMEM_BASE,   IMEM_BASE,   DEBUG_BASE},
        //ExecuteRegionAddrBase: {DRAM_BASE,   DMEM_BASE,   IMEM_BASE,   DEBUG_BASE},
        ExecuteRegionLength:   {DMEM_LENGTH, IMEM_LENGTH, DEBUG_LENGTH},
        //ExecuteRegionLength:   {DRAM_LENGTH, DMEM_LENGTH, IMEM_LENGTH, DEBUG_LENGTH},
        // cached region
        NrCachedRegionRules:    0,
        //NrCachedRegionRules:    1,
        CachedRegionAddrBase:  {64'b0},
        //CachedRegionAddrBase:  {DRAM_BASE},
        CachedRegionLength:    {64'b0},
        //CachedRegionLength:    {DRAM_LENGTH},
        //  cache config
        Axi64BitCompliant:      1'b1,
        SwapEndianess:          1'b0,
        // debug
        DmBaseAddress:          DEBUG_BASE,
        NrPMPEntries:           8
    };

    ariane_axi::req_t axi_req_o;
    ariane_axi::resp_t axi_resp_i;

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

    raw_axi_master_struct_connect arianeAxiMasterCon (
        .master_req_i(axi_req_o),
        .resp_o(axi_resp_i),
        .axi_awid(io_axi_mem_awid),
        .axi_awaddr(io_axi_mem_awaddr),
        .axi_awlen(io_axi_mem_awlen),
        .axi_awsize(io_axi_mem_awsize),
        .axi_awburst(io_axi_mem_awburst),
        .axi_awlock(io_axi_mem_awlock),
        .axi_awcache(io_axi_mem_awcache),
        .axi_awprot(io_axi_mem_awprot),
        .axi_awregion(io_axi_mem_awregion),
        .axi_awuser(io_axi_mem_awuser),
        .axi_awqos(io_axi_mem_awqos),
        .axi_awatop(io_axi_mem_awatop),
        .axi_awvalid(io_axi_mem_awvalid),
        .axi_awready(io_axi_mem_awready),
        .axi_wdata(io_axi_mem_wdata),
        .axi_wstrb(io_axi_mem_wstrb),
        .axi_wlast(io_axi_mem_wlast),
        .axi_wuser(io_axi_mem_wuser),
        .axi_wvalid(io_axi_mem_wvalid),
        .axi_wready(io_axi_mem_wready),
        .axi_bid(io_axi_mem_bid),
        .axi_bresp(io_axi_mem_bresp),
        .axi_bvalid(io_axi_mem_bvalid),
        .axi_buser(io_axi_mem_buser),
        .axi_bready(io_axi_mem_bready),
        .axi_arid(io_axi_mem_arid),
        .axi_araddr(io_axi_mem_araddr),
        .axi_arlen(io_axi_mem_arlen),
        .axi_arsize(io_axi_mem_arsize),
        .axi_arburst(io_axi_mem_arburst),
        .axi_arlock(io_axi_mem_arlock),
        .axi_arcache(io_axi_mem_arcache),
        .axi_arprot(io_axi_mem_arprot),
        .axi_arregion(io_axi_mem_arregion),
        .axi_aruser(io_axi_mem_aruser),
        .axi_arqos(io_axi_mem_arqos),
        .axi_arvalid(io_axi_mem_arvalid),
        .axi_arready(io_axi_mem_arready),
        .axi_rid(io_axi_mem_rid),
        .axi_rdata(io_axi_mem_rdata),
        .axi_rresp(io_axi_mem_rresp),
        .axi_rlast(io_axi_mem_rlast),
        .axi_ruser(io_axi_mem_ruser),
        .axi_rvalid(io_axi_mem_rvalid),
        .axi_rready(io_axi_mem_rready)
    );

endmodule