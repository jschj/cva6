module tapasco_dm_top #(
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 5,
    parameter int unsigned AXI_USER_WIDTH = 4,
    parameter int unsigned AXI_MASTER_ID_WIDTH   = AXI_ID_WIDTH - 1
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

    // DM Master connection
    output  logic [AXI_MASTER_ID_WIDTH-1:0]                             axi_dm_master_awid,
    output  logic [63:0]                            axi_dm_master_awaddr,
    output  logic [7:0]                             axi_dm_master_awlen,
    output  logic [2:0]                             axi_dm_master_awsize,
    output  logic [1:0]                             axi_dm_master_awburst,
    output  logic                                   axi_dm_master_awlock,
    output  logic [3:0]                             axi_dm_master_awcache,
    output  logic [2:0]                             axi_dm_master_awprot,
    output  logic [3:0]                             axi_dm_master_awregion,
    output  logic [AXI_USER_WIDTH-1:0]                             axi_dm_master_awuser,
    output  logic [3:0]                             axi_dm_master_awqos,
    output  logic [5:0]                             axi_dm_master_awatop,
    output  logic                                   axi_dm_master_awvalid,
    input   logic                                   axi_dm_master_awready,
    output  logic [63:0]                            axi_dm_master_wdata,
    output  logic [7:0]                             axi_dm_master_wstrb,
    output  logic                                   axi_dm_master_wlast,
    output  logic [AXI_USER_WIDTH-1:0]                             axi_dm_master_wuser,
    output  logic                                   axi_dm_master_wvalid,
    input   logic                                   axi_dm_master_wready,
    input   logic [AXI_MASTER_ID_WIDTH-1:0]                             axi_dm_master_bid,
    input   logic [1:0]                             axi_dm_master_bresp,
    input   logic                                   axi_dm_master_bvalid,
    input   logic [AXI_USER_WIDTH-1:0]                             axi_dm_master_buser,
    output  logic                                   axi_dm_master_bready,
    output  logic [AXI_MASTER_ID_WIDTH-1:0]                             axi_dm_master_arid,
    output  logic [63:0]                            axi_dm_master_araddr,
    output  logic [7:0]                             axi_dm_master_arlen,
    output  logic [2:0]                             axi_dm_master_arsize,
    output  logic [1:0]                             axi_dm_master_arburst,
    output  logic                                   axi_dm_master_arlock,
    output  logic [3:0]                             axi_dm_master_arcache,
    output  logic [2:0]                             axi_dm_master_arprot,
    output  logic [3:0]                             axi_dm_master_arregion,
    output  logic [AXI_USER_WIDTH-1:0]                             axi_dm_master_aruser,
    output  logic [3:0]                             axi_dm_master_arqos,
    output  logic                                   axi_dm_master_arvalid,
    input   logic                                   axi_dm_master_arready,
    input   logic [AXI_MASTER_ID_WIDTH-1:0]                             axi_dm_master_rid,
    input   logic [63:0]                            axi_dm_master_rdata,
    input   logic [1:0]                             axi_dm_master_rresp,
    input   logic                                   axi_dm_master_rlast,
    input   logic [AXI_USER_WIDTH-1:0]                             axi_dm_master_ruser,
    input   logic                                   axi_dm_master_rvalid,
    output  logic                                   axi_dm_master_rready,

    // DM Slave connection
    input  logic [AXI_ID_WIDTH-1:0]                             axi_dm_slave_awid,
    input  logic [63:0]                            axi_dm_slave_awaddr,
    input  logic [7:0]                             axi_dm_slave_awlen,
    input  logic [2:0]                             axi_dm_slave_awsize,
    input  logic [1:0]                             axi_dm_slave_awburst,
    input  logic                                   axi_dm_slave_awlock,
    input  logic [3:0]                             axi_dm_slave_awcache,
    input  logic [2:0]                             axi_dm_slave_awprot,
    input  logic [3:0]                             axi_dm_slave_awregion,
    input  logic [AXI_USER_WIDTH-1:0]                             axi_dm_slave_awuser,
    input  logic [3:0]                             axi_dm_slave_awqos,
    input  logic [5:0]                             axi_dm_slave_awatop,
    input  logic                                   axi_dm_slave_awvalid,
    output logic                                   axi_dm_slave_awready,
    input  logic [63:0]                            axi_dm_slave_wdata,
    input  logic [7:0]                             axi_dm_slave_wstrb,
    input  logic                                   axi_dm_slave_wlast,
    input  logic [AXI_USER_WIDTH-1:0]                             axi_dm_slave_wuser,
    input  logic                                   axi_dm_slave_wvalid,
    output logic                                   axi_dm_slave_wready,
    output logic [AXI_ID_WIDTH-1:0]                             axi_dm_slave_bid,
    output logic [1:0]                             axi_dm_slave_bresp,
    output logic                                   axi_dm_slave_bvalid,
    output logic [AXI_USER_WIDTH-1:0]                             axi_dm_slave_buser,
    input  logic                                   axi_dm_slave_bready,
    input  logic [AXI_ID_WIDTH-1:0]                             axi_dm_slave_arid,
    input  logic [63:0]                            axi_dm_slave_araddr,
    input  logic [7:0]                             axi_dm_slave_arlen,
    input  logic [2:0]                             axi_dm_slave_arsize,
    input  logic [1:0]                             axi_dm_slave_arburst,
    input  logic                                   axi_dm_slave_arlock,
    input  logic [3:0]                             axi_dm_slave_arcache,
    input  logic [2:0]                             axi_dm_slave_arprot,
    input  logic [3:0]                             axi_dm_slave_arregion,
    input  logic [AXI_USER_WIDTH-1:0]                             axi_dm_slave_aruser,
    input  logic [3:0]                             axi_dm_slave_arqos,
    input  logic                                   axi_dm_slave_arvalid,
    output logic                                   axi_dm_slave_arready,
    output logic [AXI_ID_WIDTH-1:0]                             axi_dm_slave_rid,
    output logic [63:0]                            axi_dm_slave_rdata,
    output logic [1:0]                             axi_dm_slave_rresp,
    output logic                                   axi_dm_slave_rlast,
    output logic [AXI_USER_WIDTH-1:0]                             axi_dm_slave_ruser,
    output logic                                   axi_dm_slave_rvalid,
    input  logic                                   axi_dm_slave_rready
);


    ariane_axi::req_t dm_axi_master_req;
    ariane_axi::resp_t dm_axi_master_resp;

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

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH        ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
    ) master();

    axi2mem #(
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH ),
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH        ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
    ) i_dm_axi2mem (
        .clk_i      ( clk_i                     ),
        .rst_ni     ( rst_ni                    ),
        .slave      ( master ),
        .req_o      ( dm_slave_req              ),
        .we_o       ( dm_slave_we               ),
        .addr_o     ( dm_slave_addr             ),
        .be_o       ( dm_slave_be               ),
        .data_o     ( dm_slave_wdata            ),
        .data_i     ( dm_slave_rdata            )
    );

    ariane_axi::req_t dm_axi_slave_req;
    ariane_axi::resp_t dm_axi_slave_resp;
    axi_slave_connect i_axi_slave_connect_clint (
        .dm_axi_slave_req(dm_axi_slave_req),
        .dm_axi_slave_resp(axi_clint_resp),
        .slave(master)
    );

    axi_adapter #(
        .DATA_WIDTH            ( AXI_DATA_WIDTH            ),
        .AXI_ID_WIDTH(AXI_MASTER_ID_WIDTH)
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
        .axi_req_o             ( dm_axi_master_req         ),
        .axi_resp_i            ( dm_axi_master_resp        )
    );

    // Connect master pins
    ariane_axi::aw_chan_t dm_axi_master_req_aw;
    ariane_axi::w_chan_t dm_axi_master_req_w;
    ariane_axi::ar_chan_t dm_axi_master_req_ar;

    assign dm_axi_master_req_aw = dm_axi_master_req.aw;
    assign dm_axi_master_req_w = dm_axi_master_req.w;
    assign dm_axi_master_req_ar = dm_axi_master_req.ar;
    assign axi_dm_master_awvalid = dm_axi_master_req.aw_valid;
    assign axi_dm_master_wvalid = dm_axi_master_req.w_valid;
    assign axi_dm_master_bready = dm_axi_master_req.b_ready;
    assign axi_dm_master_arvalid = dm_axi_master_req.ar_valid;
    assign axi_dm_master_rready = dm_axi_master_req.r_ready;

    // dm_axi_master_req_aw aw_chant_t signals

    assign axi_dm_master_awid = dm_axi_master_req_aw.id;
    assign axi_dm_master_awaddr = dm_axi_master_req_aw.addr;
    assign axi_dm_master_awlen = dm_axi_master_req_aw.len;
    assign axi_dm_master_awsize = dm_axi_master_req_aw.size;
    assign axi_dm_master_awburst = dm_axi_master_req_aw.burst;
    assign axi_dm_master_awlock = dm_axi_master_req_aw.lock;
    assign axi_dm_master_awcache = dm_axi_master_req_aw.cache;
    assign axi_dm_master_awprot = dm_axi_master_req_aw.prot;
    assign axi_dm_master_awqos = dm_axi_master_req_aw.qos;
    assign axi_dm_master_awregion = dm_axi_master_req_aw.region;
    assign axi_dm_master_awatop = dm_axi_master_req_aw.atop;
    assign axi_dm_master_awuser = dm_axi_master_req_aw.user;

    // w_chan_t dm_axi_master_req_w
    assign axi_dm_master_wdata = dm_axi_master_req_w.data;
    assign axi_dm_master_wstrb = dm_axi_master_req_w.strb;
    assign axi_dm_master_wlast = dm_axi_master_req_w.last;
    assign axi_dm_master_wuser = dm_axi_master_req_w.user;

    assign axi_dm_master_arid = dm_axi_master_req_ar.id;
    assign axi_dm_master_araddr = dm_axi_master_req_ar.addr;
    assign axi_dm_master_arlen = dm_axi_master_req_ar.len;
    assign axi_dm_master_arsize = dm_axi_master_req_ar.size;
    assign axi_dm_master_arburst = dm_axi_master_req_ar.burst;
    assign axi_dm_master_arlock = dm_axi_master_req_ar.lock;
    assign axi_dm_master_arcache = dm_axi_master_req_ar.cache;
    assign axi_dm_master_arprot = dm_axi_master_req_ar.prot;
    assign axi_dm_master_arqos = dm_axi_master_req_ar.qos;
    assign axi_dm_master_arregion = dm_axi_master_req_ar.region;
    assign axi_dm_master_aruser = dm_axi_master_req_ar.user;

    ariane_axi::b_chan_t dm_axi_master_resp_b_chan;
    assign dm_axi_master_resp_b_chan.id = axi_dm_master_bid;
    assign dm_axi_master_resp_b_chan.resp = axi_dm_master_bresp;
    assign dm_axi_master_resp_b_chan.user = axi_dm_master_buser;

    ariane_axi::r_chan_t dm_axi_master_resp_r_chan;
    assign dm_axi_master_resp_r_chan.id = axi_dm_master_rid;
    assign dm_axi_master_resp_r_chan.data = axi_dm_master_rdata;
    assign dm_axi_master_resp_r_chan.resp = axi_dm_master_rresp;
    assign dm_axi_master_resp_r_chan.last = axi_dm_master_rlast;
    assign dm_axi_master_resp_r_chan.user = axi_dm_master_ruser;

    assign dm_axi_master_resp.aw_ready = axi_dm_master_awready;
    assign dm_axi_master_resp.ar_ready = axi_dm_master_arready;
    assign dm_axi_master_resp.w_ready = axi_dm_master_wready;
    assign dm_axi_master_resp.b_valid = axi_dm_master_bvalid;
    assign dm_axi_master_resp.b = dm_axi_master_resp_b_chan;
    assign dm_axi_master_resp.r_valid = axi_dm_master_rvalid;
    assign dm_axi_master_resp.r = dm_axi_master_resp_r_chan;


    // Connect slave pins
    
    /*
        OUTPUT
    */
    ariane_axi::aw_chan_t dm_axi_slave_req_aw;
    ariane_axi::w_chan_t dm_axi_slave_req_w;
    ariane_axi::ar_chan_t dm_axi_slave_req_ar;

    assign dm_axi_slave_req.aw = dm_axi_slave_req_aw;
    assign dm_axi_slave_req.w = dm_axi_slave_req_w;
    assign dm_axi_slave_req.ar = dm_axi_slave_req_ar;
    assign dm_axi_slave_req.aw_valid = axi_dm_slave_awvalid;
    assign dm_axi_slave_req.w_valid = axi_dm_slave_wvalid;
    assign dm_axi_slave_req.b_ready = axi_dm_slave_bready;
    assign dm_axi_slave_req.ar_valid = axi_dm_slave_arvalid;
    assign dm_axi_slave_req.r_ready = axi_dm_slave_rready;

    // dm_axi_slave_req_aw aw_chant_t signals

    assign dm_axi_slave_req_aw.id = axi_dm_slave_awid;
    assign dm_axi_slave_req_aw.addr = axi_dm_slave_awaddr;
    assign dm_axi_slave_req_aw.len = axi_dm_slave_awlen;
    assign dm_axi_slave_req_aw.size = axi_dm_slave_awsize;
    assign dm_axi_slave_req_aw.burst = axi_dm_slave_awburst;
    assign dm_axi_slave_req_aw.lock = axi_dm_slave_awlock;
    assign dm_axi_slave_req_aw.cache = axi_dm_slave_awcache;
    assign dm_axi_slave_req_aw.prot = axi_dm_slave_awprot;
    assign dm_axi_slave_req_aw.qos = axi_dm_slave_awqos;
    assign dm_axi_slave_req_aw.region = axi_dm_slave_awregion;
    assign dm_axi_slave_req_aw.atop = axi_dm_slave_awatop;
    assign dm_axi_slave_req_aw.user = axi_dm_slave_awuser;

    // w_chan_t dm_axi_slave_req_w
    assign dm_axi_slave_req_w.data = axi_dm_slave_wdata;
    assign dm_axi_slave_req_w.strb = axi_dm_slave_wstrb;
    assign dm_axi_slave_req_w.last = axi_dm_slave_wlast;
    assign dm_axi_slave_req_w.user = axi_dm_slave_wuser;

    assign dm_axi_slave_req_ar.id = axi_dm_slave_arid;
    assign dm_axi_slave_req_ar.addr = axi_dm_slave_araddr;
    assign dm_axi_slave_req_ar.len = axi_dm_slave_arlen;
    assign dm_axi_slave_req_ar.size = axi_dm_slave_arsize;
    assign dm_axi_slave_req_ar.burst = axi_dm_slave_arburst;
    assign dm_axi_slave_req_ar.lock = axi_dm_slave_arlock;
    assign dm_axi_slave_req_ar.cache = axi_dm_slave_arcache;
    assign dm_axi_slave_req_ar.prot = axi_dm_slave_arprot;
    assign dm_axi_slave_req_ar.qos = axi_dm_slave_arqos;
    assign dm_axi_slave_req_ar.region = axi_dm_slave_arregion;
    assign dm_axi_slave_req_ar.user = axi_dm_slave_aruser;

    /*
        INPUT
    */
    ariane_axi::b_chan_t dm_axi_slave_resp_b_chan;
    assign axi_dm_slave_bid = dm_axi_slave_resp_b_chan.id;
    assign axi_dm_slave_bresp = dm_axi_slave_resp_b_chan.resp;
    assign axi_dm_slave_buser = dm_axi_slave_resp_b_chan.user;

    ariane_axi::r_chan_t dm_axi_slave_resp_r_chan;
    assign axi_dm_slave_rid = dm_axi_slave_resp_r_chan.id;
    assign axi_dm_slave_rdata = dm_axi_slave_resp_r_chan.data;
    assign axi_dm_slave_rresp = dm_axi_slave_resp_r_chan.resp;
    assign axi_dm_slave_rlast = dm_axi_slave_resp_r_chan.last;
    assign axi_dm_slave_ruser = dm_axi_slave_resp_r_chan.user;

    assign axi_dm_slave_awready = dm_axi_slave_resp.aw_ready;
    assign axi_dm_slave_arready = dm_axi_slave_resp.ar_ready;
    assign axi_dm_slave_wready = dm_axi_slave_resp.w_ready;
    assign axi_dm_slave_bvalid = dm_axi_slave_resp.b_valid;
    assign dm_axi_slave_resp_b_chan = dm_axi_slave_resp.b;
    assign axi_dm_slave_rvalid = dm_axi_slave_resp.r_valid;
    assign dm_axi_slave_resp_r_chan = dm_axi_slave_resp.r;


endmodule
