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
    input  logic [3:0]                             axi_dm_awid,
    input  logic [63:0]                            axi_dm_awaddr,
    input  logic [7:0]                             axi_dm_awlen,
    input  logic [2:0]                             axi_dm_awsize,
    input  logic [1:0]                             axi_dm_awburst,
    input  logic                                   axi_dm_awlock,
    input  logic [3:0]                             axi_dm_awcache,
    input  logic [2:0]                             axi_dm_awprot,
    input  logic [3:0]                             axi_dm_awregion,
    input  logic [3:0]                             axi_dm_awuser,
    input  logic [3:0]                             axi_dm_awqos,
    input  logic [5:0]                             axi_dm_awatop,
    input  logic                                   axi_dm_awvalid,
    output logic                                   axi_dm_awready,
    input  logic [63:0]                            axi_dm_wdata,
    input  logic [7:0]                             axi_dm_wstrb,
    input  logic                                   axi_dm_wlast,
    input  logic [3:0]                             axi_dm_wuser,
    input  logic                                   axi_dm_wvalid,
    output logic                                   axi_dm_wready,
    output logic [3:0]                             axi_dm_bid,
    output logic [1:0]                             axi_dm_bresp,
    output logic                                   axi_dm_bvalid,
    output logic [3:0]                             axi_dm_buser,
    input  logic                                   axi_dm_bready,
    input  logic [3:0]                             axi_dm_arid,
    input  logic [63:0]                            axi_dm_araddr,
    input  logic [7:0]                             axi_dm_arlen,
    input  logic [2:0]                             axi_dm_arsize,
    input  logic [1:0]                             axi_dm_arburst,
    input  logic                                   axi_dm_arlock,
    input  logic [3:0]                             axi_dm_arcache,
    input  logic [2:0]                             axi_dm_arprot,
    input  logic [3:0]                             axi_dm_arregion,
    input  logic [3:0]                             axi_dm_aruser,
    input  logic [3:0]                             axi_dm_arqos,
    input  logic                                   axi_dm_arvalid,
    output logic                                   axi_dm_arready,
    output logic [3:0]                             axi_dm_rid,
    output logic [63:0]                            axi_dm_rdata,
    output logic [1:0]                             axi_dm_rresp,
    output logic                                   axi_dm_rlast,
    output logic [3:0]                             axi_dm_ruser,
    output logic                                   axi_dm_rvalid,
    input  logic                                   axi_dm_rready
);

    /*
        OUTPUT
    */
    ariane_axi::req_t dm_axi_m_req;
    ariane_axi::aw_chan_t dm_axi_m_req_aw;
    ariane_axi::w_chan_t dm_axi_m_req_w;
    ariane_axi::ar_chan_t dm_axi_m_req_ar;

    assign dm_axi_m_req.aw = dm_axi_m_req_aw;
    assign dm_axi_m_req.w = dm_axi_m_req_w;
    assign dm_axi_m_req.ar = dm_axi_m_req_ar;
    assign dm_axi_m_req.aw_valid = axi_dm_awvalid;
    assign dm_axi_m_req.w_valid = axi_dm_wvalid;
    assign dm_axi_m_req.b_ready = axi_dm_bready;
    assign dm_axi_m_req.ar_valid = axi_dm_arvalid;
    assign dm_axi_m_req.r_ready = axi_dm_rready;

    // dm_axi_m_req_aw aw_chant_t signals

    assign dm_axi_m_req_aw.id = axi_dm_awid;
    assign dm_axi_m_req_aw.addr = axi_dm_awaddr;
    assign dm_axi_m_req_aw.len = axi_dm_awlen;
    assign dm_axi_m_req_aw.size = axi_dm_awsize;
    assign dm_axi_m_req_aw.burst = axi_dm_awburst;
    assign dm_axi_m_req_aw.lock = axi_dm_awlock;
    assign dm_axi_m_req_aw.cache = axi_dm_awcache;
    assign dm_axi_m_req_aw.prot = axi_dm_awprot;
    assign dm_axi_m_req_aw.qos = axi_dm_awqos;
    assign dm_axi_m_req_aw.region = axi_dm_awregion;
    assign dm_axi_m_req_aw.atop = axi_dm_awatop;
    assign dm_axi_m_req_aw.user = axi_dm_awuser;

    // w_chan_t dm_axi_m_req_w
    assign dm_axi_m_req_w.data = axi_dm_wdata;
    assign dm_axi_m_req_w.strb = axi_dm_wstrb;
    assign dm_axi_m_req_w.last = axi_dm_wlast;
    assign dm_axi_m_req_w.user = axi_dm_wuser;

    assign dm_axi_m_req_ar.id = axi_dm_arid;
    assign dm_axi_m_req_ar.addr = axi_dm_araddr;
    assign dm_axi_m_req_ar.len = axi_dm_arlen;
    assign dm_axi_m_req_ar.size = axi_dm_arsize;
    assign dm_axi_m_req_ar.burst = axi_dm_arburst;
    assign dm_axi_m_req_ar.lock = axi_dm_arlock;
    assign dm_axi_m_req_ar.cache = axi_dm_arcache;
    assign dm_axi_m_req_ar.prot = axi_dm_arprot;
    assign dm_axi_m_req_ar.qos = axi_dm_arqos;
    assign dm_axi_m_req_ar.region = axi_dm_arregion;
    assign dm_axi_m_req_ar.user = axi_dm_aruser;

    /*
        INPUT
    */
    ariane_axi::b_chan_t dm_axi_m_resp_b_chan;
    assign axi_dm_bid = dm_axi_m_resp_b_chan.id;
    assign axi_dm_bresp = dm_axi_m_resp_b_chan.resp;
    assign axi_dm_buser = dm_axi_m_resp_b_chan.user;

    ariane_axi::r_chan_t dm_axi_m_resp_r_chan;
    assign axi_dm_rid = dm_axi_m_resp_r_chan.id;
    assign axi_dm_rdata = dm_axi_m_resp_r_chan.data;
    assign axi_dm_rresp = dm_axi_m_resp_r_chan.resp;
    assign axi_dm_rlast = dm_axi_m_resp_r_chan.last;
    assign axi_dm_ruser = dm_axi_m_resp_r_chan.user;

    ariane_axi::resp_t dm_axi_m_resp;
    assign axi_dm_awready = dm_axi_m_resp.aw_ready;
    assign axi_dm_arready = dm_axi_m_resp.ar_ready;
    assign axi_dm_wready = dm_axi_m_resp.w_ready;
    assign axi_dm_bvalid = dm_axi_m_resp.b_valid;
    assign dm_axi_m_resp_b_chan = dm_axi_m_resp.b;
    assign axi_dm_rvalid = dm_axi_m_resp.r_valid;
    assign dm_axi_m_resp_r_chan = dm_axi_m_resp.r;

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
