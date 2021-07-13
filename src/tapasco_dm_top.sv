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
    // As this might trigger to often, use add edge detection to trigger a single request
    logic prev_dmi_req;
    always_ff @(posedge clk_i) begin
        prev_dmi_req <= dmi_req;
    end
    // Only issue a request on the posedge of dmi_req
    assign dmi_req_valid = ~prev_dmi_req && dmi_req;
    //assign dmi_req_valid = dmi_req;

    assign dmi_req_i.op = dmi_req ? (dmi_wr ? dm::DTM_WRITE : dm::DTM_READ) : dm::DTM_NOP;
    assign dmi_req_i.addr = dmi_addr;
    assign dmi_req_i.data = dmi_wdata;

    logic                  dmi_resp_valid;
    logic                  dmi_resp_ready;
    assign dmi_resp_ready = 1'b1;
    dm::dmi_resp_t         dmi_resp;
    // use flopping to preserve the last valid value
    always_ff @(posedge clk_i) begin
        if (dmi_resp_valid) begin
           dmi_rdata <= dmi_resp.data;
        end
    end

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
        .slave      ( master.Slave ),
        .req_o      ( dm_slave_req              ),
        .we_o       ( dm_slave_we               ),
        .addr_o     ( dm_slave_addr             ),
        .be_o       ( dm_slave_be               ),
        .data_o     ( dm_slave_wdata            ),
        .data_i     ( dm_slave_rdata            )
    );


    ariane_axi::req_t dm_axi_master_req;
    ariane_axi::resp_t dm_axi_master_resp;

    axi_adapter #(
        .DATA_WIDTH            ( AXI_DATA_WIDTH            ),
        .AXI_ID_WIDTH          (AXI_MASTER_ID_WIDTH)
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
    raw_axi_master_struct_connect #(
        .AXI_ID_WIDTH(AXI_MASTER_ID_WIDTH)
    ) dmMasterConnect (
        .master_req_i(dm_axi_master_req),
        .resp_o(dm_axi_master_resp),

        .axi_awid(axi_dm_master_awid),
        .axi_awaddr(axi_dm_master_awaddr),
        .axi_awlen(axi_dm_master_awlen),
        .axi_awsize(axi_dm_master_awsize),
        .axi_awburst(axi_dm_master_awburst),
        .axi_awlock(axi_dm_master_awlock),
        .axi_awcache(axi_dm_master_awcache),
        .axi_awprot(axi_dm_master_awprot),
        .axi_awregion(axi_dm_master_awregion),
        .axi_awuser(axi_dm_master_awuser),
        .axi_awqos(axi_dm_master_awqos),
        .axi_awatop(axi_dm_master_awatop),
        .axi_awvalid(axi_dm_master_awvalid),
        .axi_awready(axi_dm_master_awready),
        .axi_wdata(axi_dm_master_wdata),
        .axi_wstrb(axi_dm_master_wstrb),
        .axi_wlast(axi_dm_master_wlast),
        .axi_wuser(axi_dm_master_wuser),
        .axi_wvalid(axi_dm_master_wvalid),
        .axi_wready(axi_dm_master_wready),
        .axi_bid(axi_dm_master_bid),
        .axi_bresp(axi_dm_master_bresp),
        .axi_bvalid(axi_dm_master_bvalid),
        .axi_buser(axi_dm_master_buser),
        .axi_bready(axi_dm_master_bready),
        .axi_arid(axi_dm_master_arid),
        .axi_araddr(axi_dm_master_araddr),
        .axi_arlen(axi_dm_master_arlen),
        .axi_arsize(axi_dm_master_arsize),
        .axi_arburst(axi_dm_master_arburst),
        .axi_arlock(axi_dm_master_arlock),
        .axi_arcache(axi_dm_master_arcache),
        .axi_arprot(axi_dm_master_arprot),
        .axi_arregion(axi_dm_master_arregion),
        .axi_aruser(axi_dm_master_aruser),
        .axi_arqos(axi_dm_master_arqos),
        .axi_arvalid(axi_dm_master_arvalid),
        .axi_arready(axi_dm_master_arready),
        .axi_rid(axi_dm_master_rid),
        .axi_rdata(axi_dm_master_rdata),
        .axi_rresp(axi_dm_master_rresp),
        .axi_rlast(axi_dm_master_rlast),
        .axi_ruser(axi_dm_master_ruser),
        .axi_rvalid(axi_dm_master_rvalid),
        .axi_rready(axi_dm_master_rready)
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
