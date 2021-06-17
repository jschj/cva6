module tapasco_dm_top #(
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 10,
    parameter int unsigned NR_CORES       = 1 // Number of cores therefore also the number of timecmp registers and timer interrupts
)(
    input  logic                         clk_i,
    input  logic                         rst_ni,
    output logic                         debug_req_core_o,
    // DM Interface
    input   logic                                   dmi_req,  // DMI request
    input   logic                                   dmi_wr,   // DMI write
    input   logic [7-1:0]                           dmi_addr, // DMI address
    input   logic [32-1:0]                          dmi_wdata,// DMI write data
    output  logic [32-1:0]                          dmi_rdata, // DMI read data

    // memory side, AXI Master
    output  logic [3:0]                             axi_dm_awid,
    output  logic [63:0]                            axi_dm_awaddr,
    output  logic [7:0]                             axi_dm_awlen,
    output  logic [2:0]                             axi_dm_awsize,
    output  logic [1:0]                             axi_dm_awburst,
    output  logic                                   axi_dm_awlock,
    output  logic [3:0]                             axi_dm_awcache,
    output  logic [2:0]                             axi_dm_awprot,
    output  logic [3:0]                             axi_dm_awregion,
    output  logic [3:0]                             axi_dm_awuser,
    output  logic [3:0]                             axi_dm_awqos,
    output  logic [5:0]                             axi_dm_awatop,
    output  logic                                   axi_dm_awvalid,
    input   logic                                   axi_dm_awready,
    output  logic [63:0]                            axi_dm_wdata,
    output  logic [7:0]                             axi_dm_wstrb,
    output  logic                                   axi_dm_wlast,
    output  logic [3:0]                             axi_dm_wuser,
    output  logic                                   axi_dm_wvalid,
    input   logic                                   axi_dm_wready,
    input   logic [3:0]                             axi_dm_bid,
    input   logic [1:0]                             axi_dm_bresp,
    input   logic                                   axi_dm_bvalid,
    input   logic [3:0]                             axi_dm_buser,
    output  logic                                   axi_dm_bready,
    output  logic [3:0]                             axi_dm_arid,
    output  logic [63:0]                            axi_dm_araddr,
    output  logic [7:0]                             axi_dm_arlen,
    output  logic [2:0]                             axi_dm_arsize,
    output  logic [1:0]                             axi_dm_arburst,
    output  logic                                   axi_dm_arlock,
    output  logic [3:0]                             axi_dm_arcache,
    output  logic [2:0]                             axi_dm_arprot,
    output  logic [3:0]                             axi_dm_arregion,
    output  logic [3:0]                             axi_dm_aruser,
    output  logic [3:0]                             axi_dm_arqos,
    output  logic                                   axi_dm_arvalid,
    input   logic                                   axi_dm_arready,
    input   logic [3:0]                             axi_dm_rid,
    input   logic [63:0]                            axi_dm_rdata,
    input   logic [1:0]                             axi_dm_rresp,
    input   logic                                   axi_dm_rlast,
    input   logic [3:0]                             axi_dm_ruser,
    input   logic                                   axi_dm_rvalid,
    output  logic                                   axi_dm_rready
);


    ariane_axi::req_t dm_axi_m_req;
    ariane_axi::aw_chan_t dm_axi_m_req_aw;
    ariane_axi::w_chan_t dm_axi_m_req_w;
    ariane_axi::ar_chan_t dm_axi_m_req_ar;

    assign dm_axi_m_req_aw = dm_axi_m_req.aw;
    assign dm_axi_m_req_w = dm_axi_m_req.w;
    assign dm_axi_m_req_ar = dm_axi_m_req.ar;
    assign axi_dm_awvalid = dm_axi_m_req.aw_valid;
    assign axi_dm_wvalid = dm_axi_m_req.w_valid;
    assign axi_dm_bready = dm_axi_m_req.b_ready;
    assign axi_dm_arvalid = dm_axi_m_req.ar_valid;
    assign axi_dm_rready = dm_axi_m_req.r_ready;

    // dm_axi_m_req_aw aw_chant_t signals

    assign axi_dm_awid = dm_axi_m_req_aw.id;
    assign axi_dm_awaddr = dm_axi_m_req_aw.addr;
    assign axi_dm_awlen = dm_axi_m_req_aw.len;
    assign axi_dm_awsize = dm_axi_m_req_aw.size;
    assign axi_dm_awburst = dm_axi_m_req_aw.burst;
    assign axi_dm_awlock = dm_axi_m_req_aw.lock;
    assign axi_dm_awcache = dm_axi_m_req_aw.cache;
    assign axi_dm_awprot = dm_axi_m_req_aw.prot;
    assign axi_dm_awqos = dm_axi_m_req_aw.qos;
    assign axi_dm_awregion = dm_axi_m_req_aw.region;
    assign axi_dm_awatop = dm_axi_m_req_aw.atop;
    assign axi_dm_awuser = dm_axi_m_req_aw.user;

    // w_chan_t dm_axi_m_req_w
    assign axi_dm_wdata = dm_axi_m_req_w.data;
    assign axi_dm_wstrb = dm_axi_m_req_w.strb;
    assign axi_dm_wlast = dm_axi_m_req_w.last;
    assign axi_dm_wuser = dm_axi_m_req_w.user;

    assign axi_dm_arid = dm_axi_m_req_ar.id;
    assign axi_dm_araddr = dm_axi_m_req_ar.addr;
    assign axi_dm_arlen = dm_axi_m_req_ar.len;
    assign axi_dm_arsize = dm_axi_m_req_ar.size;
    assign axi_dm_arburst = dm_axi_m_req_ar.burst;
    assign axi_dm_arlock = dm_axi_m_req_ar.lock;
    assign axi_dm_arcache = dm_axi_m_req_ar.cache;
    assign axi_dm_arprot = dm_axi_m_req_ar.prot;
    assign axi_dm_arqos = dm_axi_m_req_ar.qos;
    assign axi_dm_arregion = dm_axi_m_req_ar.region;
    assign axi_dm_aruser = dm_axi_m_req_ar.user;

    ariane_axi::b_chan_t dm_axi_m_resp_b_chan;
    assign dm_axi_m_resp_b_chan.id = axi_dm_bid;
    assign dm_axi_m_resp_b_chan.resp = axi_dm_bresp;
    assign dm_axi_m_resp_b_chan.user = axi_dm_buser;

    ariane_axi::r_chan_t dm_axi_m_resp_r_chan;
    assign dm_axi_m_resp_r_chan.id = axi_dm_rid;
    assign dm_axi_m_resp_r_chan.data = axi_dm_rdata;
    assign dm_axi_m_resp_r_chan.resp = axi_dm_rresp;
    assign dm_axi_m_resp_r_chan.last = axi_dm_rlast;
    assign dm_axi_m_resp_r_chan.user = axi_dm_ruser;

    ariane_axi::resp_t dm_axi_m_resp;
    assign dm_axi_m_resp.aw_ready = axi_dm_awready;
    assign dm_axi_m_resp.ar_ready = axi_dm_arready;
    assign dm_axi_m_resp.w_ready = axi_dm_wready;
    assign dm_axi_m_resp.b_valid = axi_dm_bvalid;
    assign dm_axi_m_resp.b = dm_axi_m_resp_b_chan;
    assign dm_axi_m_resp.r_valid = axi_dm_rvalid;
    assign dm_axi_m_resp.r = dm_axi_m_resp_r_chan;

    logic                dm_slave_req;
    logic                dm_slave_we;
    logic [64-1:0]       dm_slave_addr;
    logic [64/8-1:0]     dm_slave_be;
    logic [64-1:0]       dm_slave_wdata;
    logic [64-1:0]       dm_slave_rdata;

    logic                dm_master_req;
    logic [64-1:0]       dm_master_add;
    logic                dm_master_we;
    logic [64-1:0]       dm_master_wdata;
    logic [64/8-1:0]     dm_master_be;
    logic                dm_master_gnt;
    logic                dm_master_r_valid;
    logic [64-1:0]       dm_master_r_rdata;

    logic                test_en;
    assign test_en = 1'b0;

    logic                  dmi_req_valid;
    logic                  dmi_req_ready;
    dm::dmi_req_t          dmi_req_i;
    // TODO this might trigger to often... add edge detection for triggering a single request?
    assign dmi_req_valid = dmi_req;
    assign dmi_req_i.op = dmi_req ? (dmi_wr ? dm::DTM_WRITE : dm::DTM_READ) : dm::DTM_NOP;
    assign dmi_req_i.addr = dmi_addr;
    assign dmi_req_i.data = dmi_wdata;

    logic                  dmi_resp_valid;
    logic                  dmi_resp_ready;
    dm::dmi_resp_t         dmi_resp;
    //TODO might need flopping to preserve the last valid value
    assign dmi_rdata = dmi_resp.data;

    // debug module
    dm_top #(
        .NrHarts              ( 1                           ),
        .BusWidth             ( AXI_DATA_WIDTH              ),
        .SelectableHarts      ( 1'b1                        )
    ) i_dm_top (
        .clk_i                ( clk_i                       ),
        .rst_ni               ( rst_ni                      ), // PoR
        .testmode_i           ( test_en                     ),
        .ndmreset_o           (), // Removed...
        .dmactive_o           (                             ), // active debug session
        .debug_req_o          ( debug_req_core_o            ),
        .unavailable_i        ( '0                          ),
        .hartinfo_i           ( {ariane_pkg::DebugHartInfo} ),
        .slave_req_i          ( dm_slave_req                ),
        .slave_we_i           ( dm_slave_we                 ),
        .slave_addr_i         ( dm_slave_addr               ),
        .slave_be_i           ( dm_slave_be                 ),
        .slave_wdata_i        ( dm_slave_wdata              ),
        .slave_rdata_o        ( dm_slave_rdata              ),
        .master_req_o         ( dm_master_req               ),
        .master_add_o         ( dm_master_add               ),
        .master_we_o          ( dm_master_we                ),
        .master_wdata_o       ( dm_master_wdata             ),
        .master_be_o          ( dm_master_be                ),
        .master_gnt_i         ( dm_master_gnt               ),
        .master_r_valid_i     ( dm_master_r_valid           ),
        .master_r_rdata_i     ( dm_master_r_rdata           ),
        .dmi_rst_ni           ( rst_ni                      ),
        .dmi_req_valid_i      ( dmi_req_valid               ),
        .dmi_req_ready_o      ( dmi_req_ready               ),
        .dmi_req_i            ( dmi_req_i                   ),
        .dmi_resp_valid_o     ( dmi_resp_valid              ),
        .dmi_resp_ready_i     ( dmi_resp_ready              ),
        .dmi_resp_o           ( dmi_resp                    )
    );

    axi_adapter #(
        .DATA_WIDTH            ( AXI_DATA_WIDTH            )
    ) i_dm_axi_master (
        .clk_i                 ( clk_i                     ),
        .rst_ni                ( rst_ni                    ),
        .req_i                 ( dm_master_req             ),
        .type_i                ( ariane_axi::SINGLE_REQ    ),
        .gnt_o                 ( dm_master_gnt             ),
        .gnt_id_o              (                           ),
        .addr_i                ( dm_master_add             ),
        .we_i                  ( dm_master_we              ),
        .wdata_i               ( dm_master_wdata           ),
        .be_i                  ( dm_master_be              ),
        .size_i                ( 2'b11                     ), // always do 64bit here and use byte enables to gate
        .id_i                  ( '0                        ),
        .valid_o               ( dm_master_r_valid         ),
        .rdata_o               ( dm_master_r_rdata         ),
        .id_o                  (                           ),
        .critical_word_o       (                           ),
        .critical_word_valid_o (                           ),
        .axi_req_o             ( dm_axi_m_req              ),
        .axi_resp_i            ( dm_axi_m_resp             )
    );

endmodule
