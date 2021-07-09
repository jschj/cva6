// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19.03.2017
// Description: Test-harness for Ariane
//              Instantiates an AXI-Bus and memories

module ariane_custom_top #(
    parameter logic[63:0] DebugLength    = 64'h1000,
    parameter logic[63:0] MemLength      = 64'hffff_ffff_ffff_f000,
    parameter logic[63:0] DebugBase      = 64'h0000_0000,
    parameter logic[63:0] MemBase        = 64'h0000_1000,
    parameter int unsigned AXI_USER_WIDTH    = 1,
    parameter int unsigned AXI_ADDRESS_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH    = 64,
    localparam NB_SLAVE = 2,
    localparam NB_MASTER = 2,
    localparam IdWidth = 4,
    localparam IdWidthSlave = IdWidth + $clog2(NB_SLAVE)
) (
    input  logic                         clk,
    input  logic                         rst_n,
    // Core ID, Cluster ID and boot address are considered more or less static
    input  logic [63:0]                  boot_addr_i,  // reset boot address
    input  logic [63:0]                  hart_id_i,    // hart id in a multicore environment (reflected in a CSR)

    // Interrupt inputs
    input  logic [1:0]                   irq_i,        // level sensitive IR lines, mip & sip (async)
    input  logic                         ipi_i,        // inter-processor interrupts (async)
    // Timer facilities
    input  logic                         time_irq_i,   // timer interrupt in (async)

    // DM Interface
    input   logic                                   dmi_req,                // DMI request
    input   logic                                   dmi_wr,                 // DMI write
    input   logic [7-1:0]     dmi_addr,               // DMI address
    input   logic [32-1:0]     dmi_wdata,              // DMI write data
    output  logic [32-1:0]     dmi_rdata,              // DMI read data

    // memory side, AXI Master
    output  logic [5-1:0]                           io_axi_mem_awid,
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
    input   logic [5-1:0]                           io_axi_mem_bid,
    input   logic [1:0]                             io_axi_mem_bresp,
    input   logic                                   io_axi_mem_bvalid,
    input   logic [3:0]                             io_axi_mem_buser,
    output  logic                                   io_axi_mem_bready,
    output  logic [5-1:0]                           io_axi_mem_arid,
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
    input   logic [5-1:0]                           io_axi_mem_rid,
    input   logic [63:0]                            io_axi_mem_rdata,
    input   logic [1:0]                             io_axi_mem_rresp,
    input   logic                                   io_axi_mem_rlast,
    input   logic [3:0]                             io_axi_mem_ruser,
    input   logic                                   io_axi_mem_rvalid,
    output  logic                                   io_axi_mem_rready
);


    logic                         debug_req;  // debug request (async)

    logic clk_i, rst_ni;
    assign clk_i = clk;
    assign rst_ni = rst_n;

    ariane_axi::req_t    axi_ariane_req;
    ariane_axi::resp_t   axi_ariane_resp;

    //localparam logic[63:0] CLINTBase    = 64'h0200_0000;
    //localparam logic[63:0] DRAMBase     = 64'h8000_0000;

    localparam ARIANE_AXI_MASTER_IDX = 0;
    localparam DM_AXI_MASTER_IDX = 1;
    localparam DM_AXI_SLAVE_IDX = 1;
    localparam ROM_AXI_SLAVE_IDX = 0;

    localparam ariane_pkg::ariane_cfg_t ArianeCfg = '{
        RASDepth: 2,
        BTBEntries: 32,
        BHTEntries: 128,
        // idempotent region
        NrNonIdempotentRules:  1,
        NonIdempotentAddrBase: {64'b0},
        //NonIdempotentLength:   {DRAMBase},
        NonIdempotentLength:   {64'b0},
        //NrExecuteRegionRules:  4,
        NrExecuteRegionRules:  2,
        ExecuteRegionAddrBase: {MemBase,   DebugBase},
        ExecuteRegionLength:   {MemLength, DebugLength},
        // cached region
        NrCachedRegionRules:    0,
        //NrCachedRegionRules:    1,
        CachedRegionAddrBase:  {64'b0},
        //CachedRegionAddrBase:  {DRAMBase},
        CachedRegionLength:    {64'b0},
        //CachedRegionLength:    {DRAMLength},
        //  cache config
        Axi64BitCompliant:      1'b1,
        SwapEndianess:          1'b0,
        // debug
        DmBaseAddress:          DebugBase,
        NrPMPEntries:           8
    };


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
        .debug_req_i(debug_req),      // debug request (async)

        // memory side, AXI Master
        .axi_req_o(axi_ariane_req),
        .axi_resp_i(axi_ariane_resp)
    );

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
        .AXI_ID_WIDTH   ( IdWidth ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH      )
    ) slave[NB_SLAVE-1:0]();

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
        .AXI_ID_WIDTH   ( IdWidthSlave ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
    ) master[NB_MASTER-1:0]();

    axi_master_connect i_axi_master_connect_ariane (
        .axi_req_i(axi_ariane_req),
        .axi_resp_o(axi_ariane_resp),
        .master(slave[ARIANE_AXI_MASTER_IDX])
    );

    // DM axi stuff    
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

    // Shady exposed DM interface
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
        .debug_req_o          ( debug_req                   ),
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

    axi2mem #(
        .AXI_ID_WIDTH   ( IdWidthSlave ),
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
    ) i_dm_axi2mem (
        .clk_i      ( clk_i                     ),
        .rst_ni     ( rst_ni                    ),
        .slave      ( master[DM_AXI_SLAVE_IDX] ),
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
        .AXI_ID_WIDTH          ( IdWidth)
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

    axi_master_connect i_dm_axi_master_connect (
        .axi_req_i(dm_axi_master_req),
        .axi_resp_o(dm_axi_master_resp),
        .master(slave[DM_AXI_MASTER_IDX])
    );

    // AXI Interconnect
    localparam NB_REGION = 1;
    axi_node_intf_wrap #(
        .NB_SLAVE           ( NB_SLAVE                   ),
        .NB_MASTER          ( NB_MASTER                  ),
        .NB_REGION          ( NB_REGION                  ),
        .AXI_ADDR_WIDTH     ( AXI_ADDRESS_WIDTH          ),
        .AXI_DATA_WIDTH     ( AXI_DATA_WIDTH             ),
        .AXI_USER_WIDTH     ( AXI_USER_WIDTH             ),
        .AXI_ID_WIDTH       ( IdWidth                    )
        // .MASTER_SLICE_DEPTH ( 0                          ),
        // .SLAVE_SLICE_DEPTH  ( 0                          )
    ) i_axi_xbar (
        .clk          ( clk_i      ),
        .rst_n        ( rst_n ),
        .test_en_i    ( test_en    ),
        .slave        ( slave      ),
        .master       ( master     ),
        .start_addr_i ({
            DebugBase,
            MemBase
        }),
        .end_addr_i   ({
            DebugBase    + DebugLength - 1,
            MemBase      + MemLength - 1
        }),
        .valid_rule_i ({(NB_REGION * NB_MASTER){1'b1}})
    );



    // Connect master 

    ariane_axi::req_t io_axi_slave_req;
    ariane_axi::resp_t io_axi_slave_resp;
    
    axi_slave_connect i_io_axi_slave_connect (
        .axi_req_o(io_axi_slave_req),
        .axi_resp_i(io_axi_slave_resp),
        .slave(master[ROM_AXI_SLAVE_IDX])
    );


    ariane_axi::aw_chan_t io_axi_slave_req_aw;
    ariane_axi::w_chan_t io_axi_slave_req_w;
    ariane_axi::ar_chan_t io_axi_slave_req_ar;

    assign io_axi_slave_req_aw = io_axi_slave_req.aw;
    assign io_axi_slave_req_w = io_axi_slave_req.w;
    assign io_axi_slave_req_ar = io_axi_slave_req.ar;
    assign io_axi_mem_awvalid = io_axi_slave_req.aw_valid;
    assign io_axi_mem_wvalid = io_axi_slave_req.w_valid;
    assign io_axi_mem_bready = io_axi_slave_req.b_ready;
    assign io_axi_mem_arvalid = io_axi_slave_req.ar_valid;
    assign io_axi_mem_rready = io_axi_slave_req.r_ready;

    // io_axi_slave_req_aw aw_chant_t signals

    assign io_axi_mem_awid = io_axi_slave_req_aw.id;
    assign io_axi_mem_awaddr = io_axi_slave_req_aw.addr;
    assign io_axi_mem_awlen = io_axi_slave_req_aw.len;
    assign io_axi_mem_awsize = io_axi_slave_req_aw.size;
    assign io_axi_mem_awburst = io_axi_slave_req_aw.burst;
    assign io_axi_mem_awlock = io_axi_slave_req_aw.lock;
    assign io_axi_mem_awcache = io_axi_slave_req_aw.cache;
    assign io_axi_mem_awprot = io_axi_slave_req_aw.prot;
    assign io_axi_mem_awqos = io_axi_slave_req_aw.qos;
    assign io_axi_mem_awregion = io_axi_slave_req_aw.region;
    assign io_axi_mem_awatop = io_axi_slave_req_aw.atop;
    assign io_axi_mem_awuser = io_axi_slave_req_aw.user;

    // w_chan_t io_axi_slave_req_w
    assign io_axi_mem_wdata = io_axi_slave_req_w.data;
    assign io_axi_mem_wstrb = io_axi_slave_req_w.strb;
    assign io_axi_mem_wlast = io_axi_slave_req_w.last;
    assign io_axi_mem_wuser = io_axi_slave_req_w.user;

    assign io_axi_mem_arid = io_axi_slave_req_ar.id;
    assign io_axi_mem_araddr = io_axi_slave_req_ar.addr;
    assign io_axi_mem_arlen = io_axi_slave_req_ar.len;
    assign io_axi_mem_arsize = io_axi_slave_req_ar.size;
    assign io_axi_mem_arburst = io_axi_slave_req_ar.burst;
    assign io_axi_mem_arlock = io_axi_slave_req_ar.lock;
    assign io_axi_mem_arcache = io_axi_slave_req_ar.cache;
    assign io_axi_mem_arprot = io_axi_slave_req_ar.prot;
    assign io_axi_mem_arqos = io_axi_slave_req_ar.qos;
    assign io_axi_mem_arregion = io_axi_slave_req_ar.region;
    assign io_axi_mem_aruser = io_axi_slave_req_ar.user;

    ariane_axi::b_chan_t io_axi_slave_resp_b_chan;
    assign io_axi_slave_resp_b_chan.id = io_axi_mem_bid;
    assign io_axi_slave_resp_b_chan.resp = io_axi_mem_bresp;
    assign io_axi_slave_resp_b_chan.user = io_axi_mem_buser;

    ariane_axi::r_chan_t io_axi_slave_resp_r_chan;
    assign io_axi_slave_resp_r_chan.id = io_axi_mem_rid;
    assign io_axi_slave_resp_r_chan.data = io_axi_mem_rdata;
    assign io_axi_slave_resp_r_chan.resp = io_axi_mem_rresp;
    assign io_axi_slave_resp_r_chan.last = io_axi_mem_rlast;
    assign io_axi_slave_resp_r_chan.user = io_axi_mem_ruser;

    assign io_axi_slave_resp.aw_ready = io_axi_mem_awready;
    assign io_axi_slave_resp.ar_ready = io_axi_mem_arready;
    assign io_axi_slave_resp.w_ready = io_axi_mem_wready;
    assign io_axi_slave_resp.b_valid = io_axi_mem_bvalid;
    assign io_axi_slave_resp.b = io_axi_slave_resp_b_chan;
    assign io_axi_slave_resp.r_valid = io_axi_mem_rvalid;
    assign io_axi_slave_resp.r = io_axi_slave_resp_r_chan;


endmodule
