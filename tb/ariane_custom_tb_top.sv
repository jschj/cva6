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

module ariane_custom_tb_top #(
    parameter int unsigned AXI_USER_WIDTH    = 1,
    parameter int unsigned AXI_ADDRESS_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH    = 64,
    parameter int unsigned NUM_WORDS         = 32768,         // memory size
    parameter bit          StallRandomOutput = 1'b0,
    parameter bit          StallRandomInput  = 1'b0
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
    output  logic [32-1:0]     dmi_rdata              // DMI read data

);


    logic                         debug_req;  // debug request (async)

    logic clk_i, rst_ni;
    assign clk_i = clk;
    assign rst_ni = rst_n;
   logic                test_en;
   assign test_en = 1'b0;


    localparam ARIANE_AXI_MASTER_IDX = 0;
    localparam DM_AXI_MASTER_IDX = 1;
    localparam DM_AXI_SLAVE_IDX = 1;
    localparam ROM_AXI_SLAVE_IDX = 0;

    localparam logic[63:0] DebugLength    = 64'h1000;
    localparam logic[63:0] ROMLength      = 64'h04000;
    localparam logic[63:0] DMEMLength     = 64'h04000;
    localparam logic[63:0] DebugBase = 64'h1200_0000;
    localparam logic[63:0] ROMBase      = 64'h0000_0000;
    localparam logic[63:0] DMEMBase     = 64'h0000_4000;

    localparam NB_SLAVE = 2;
    localparam NB_MASTER = 2;
    localparam IdWidth = 4;
    localparam IdWidthSlave = IdWidth + $clog2(NB_SLAVE);

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

    logic                         req;
    logic                         we;
    logic [AXI_ADDRESS_WIDTH-1:0] addr;
    logic [AXI_DATA_WIDTH/8-1:0]  be;
    logic [AXI_DATA_WIDTH-1:0]    wdata;
    logic [AXI_DATA_WIDTH-1:0]    rdata;

    axi2mem #(
        .AXI_ID_WIDTH   ( IdWidthSlave ),
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
    ) i_axi2mem (
        .clk_i  ( clk_i        ),
        .rst_ni ( rst_ni   ),
        .slave  ( master[ROM_AXI_SLAVE_IDX] ),
        .req_o  ( req          ),
        .we_o   ( we           ),
        .addr_o ( addr         ),
        .be_o   ( be           ),
        .data_o ( wdata        ),
        .data_i ( rdata        )
    );

    tb_sram #(
        .DATA_WIDTH ( AXI_DATA_WIDTH ),
        .NUM_WORDS  ( NUM_WORDS      )
    ) i_sram (
        .clk_i      ( clk_i                                                                       ),
        .rst_ni     ( rst_ni                                                                      ),
        .req_i      ( req                                                                         ),
        .we_i       ( we                                                                          ),
        .addr_i     ( addr[$clog2(NUM_WORDS)-1+$clog2(AXI_DATA_WIDTH/8):$clog2(AXI_DATA_WIDTH/8)] ),
        .wdata_i    ( wdata                                                                       ),
        .be_i       ( be                                                                          ),
        .rdata_o    ( rdata                                                                       )
    );

    // Ariane Core
    logic [IdWidth-1:0]                     cva6_axi_awid;
    logic [63:0]                            cva6_axi_awaddr;
    logic [7:0]                             cva6_axi_awlen;
    logic [2:0]                             cva6_axi_awsize;
    logic [1:0]                             cva6_axi_awburst;
    logic                                   cva6_axi_awlock;
    logic [3:0]                             cva6_axi_awcache;
    logic [2:0]                             cva6_axi_awprot;
    logic [3:0]                             cva6_axi_awregion;
    logic [3:0]                             cva6_axi_awuser;
    logic [3:0]                             cva6_axi_awqos;
    logic [5:0]                             cva6_axi_awatop;
    logic                                   cva6_axi_awvalid;
    logic                                   cva6_axi_awready;
    logic [63:0]                            cva6_axi_wdata;
    logic [7:0]                             cva6_axi_wstrb;
    logic                                   cva6_axi_wlast;
    logic [3:0]                             cva6_axi_wuser;
    logic                                   cva6_axi_wvalid;
    logic                                   cva6_axi_wready;
    logic [IdWidth-1:0]                     cva6_axi_bid;
    logic [1:0]                             cva6_axi_bresp;
    logic                                   cva6_axi_bvalid;
    logic [3:0]                             cva6_axi_buser;
    logic                                   cva6_axi_bready;
    logic [IdWidth-1:0]                     cva6_axi_arid;
    logic [63:0]                            cva6_axi_araddr;
    logic [7:0]                             cva6_axi_arlen;
    logic [2:0]                             cva6_axi_arsize;
    logic [1:0]                             cva6_axi_arburst;
    logic                                   cva6_axi_arlock;
    logic [3:0]                             cva6_axi_arcache;
    logic [2:0]                             cva6_axi_arprot;
    logic [3:0]                             cva6_axi_arregion;
    logic [3:0]                             cva6_axi_aruser;
    logic [3:0]                             cva6_axi_arqos;
    logic                                   cva6_axi_arvalid;
    logic                                   cva6_axi_arready;
    logic [IdWidth-1:0]                     cva6_axi_rid;
    logic [63:0]                            cva6_axi_rdata;
    logic [1:0]                             cva6_axi_rresp;
    logic                                   cva6_axi_rlast;
    logic [3:0]                             cva6_axi_ruser;
    logic                                   cva6_axi_rvalid;
    logic                                   cva6_axi_rready;

    ariane_top #(
        .DEBUG_LENGTH(DebugLength),
        .IMEM_LENGTH(ROMLength),
        .DMEM_LENGTH(DMEMLength),
        .DEBUG_BASE(DebugBase),
        .IMEM_BASE(ROMBase),
        .DMEM_BASE(DMEMBase)
    ) wrappedCore (
        .clk_i(clk_i),
        .rst_ni(rst_n),
        .boot_addr_i(boot_addr_i),
        .hart_id_i(hart_id_i),
        .irq_i(irq_i),
        .ipi_i(ipi_i),
        .time_irq_i(time_irq_i),
        .debug_req_i(debug_req),

        .io_axi_mem_awid(cva6_axi_awid),
        .io_axi_mem_awaddr(cva6_axi_awaddr),
        .io_axi_mem_awlen(cva6_axi_awlen),
        .io_axi_mem_awsize(cva6_axi_awsize),
        .io_axi_mem_awburst(cva6_axi_awburst),
        .io_axi_mem_awlock(cva6_axi_awlock),
        .io_axi_mem_awcache(cva6_axi_awcache),
        .io_axi_mem_awprot(cva6_axi_awprot),
        .io_axi_mem_awregion(cva6_axi_awregion),
        .io_axi_mem_awuser(cva6_axi_awuser),
        .io_axi_mem_awqos(cva6_axi_awqos),
        .io_axi_mem_awatop(cva6_axi_awatop),
        .io_axi_mem_awvalid(cva6_axi_awvalid),
        .io_axi_mem_awready(cva6_axi_awready),
        .io_axi_mem_wdata(cva6_axi_wdata),
        .io_axi_mem_wstrb(cva6_axi_wstrb),
        .io_axi_mem_wlast(cva6_axi_wlast),
        .io_axi_mem_wuser(cva6_axi_wuser),
        .io_axi_mem_wvalid(cva6_axi_wvalid),
        .io_axi_mem_wready(cva6_axi_wready),
        .io_axi_mem_bid(cva6_axi_bid),
        .io_axi_mem_bresp(cva6_axi_bresp),
        .io_axi_mem_bvalid(cva6_axi_bvalid),
        .io_axi_mem_buser(cva6_axi_buser),
        .io_axi_mem_bready(cva6_axi_bready),
        .io_axi_mem_arid(cva6_axi_arid),
        .io_axi_mem_araddr(cva6_axi_araddr),
        .io_axi_mem_arlen(cva6_axi_arlen),
        .io_axi_mem_arsize(cva6_axi_arsize),
        .io_axi_mem_arburst(cva6_axi_arburst),
        .io_axi_mem_arlock(cva6_axi_arlock),
        .io_axi_mem_arcache(cva6_axi_arcache),
        .io_axi_mem_arprot(cva6_axi_arprot),
        .io_axi_mem_arregion(cva6_axi_arregion),
        .io_axi_mem_aruser(cva6_axi_aruser),
        .io_axi_mem_arqos(cva6_axi_arqos),
        .io_axi_mem_arvalid(cva6_axi_arvalid),
        .io_axi_mem_arready(cva6_axi_arready),
        .io_axi_mem_rid(cva6_axi_rid),
        .io_axi_mem_rdata(cva6_axi_rdata),
        .io_axi_mem_rresp(cva6_axi_rresp),
        .io_axi_mem_rlast(cva6_axi_rlast),
        .io_axi_mem_ruser(cva6_axi_ruser),
        .io_axi_mem_rvalid(cva6_axi_rvalid),
        .io_axi_mem_rready(cva6_axi_rready)
    );

    raw_axi_slave_connect #(
        .AXI_ID_WIDTH(tapasco_axi::IdWidth),
        .req_t(tapasco_axi::req_t),
        .resp_t(tapasco_axi::resp_t)
    ) cva6AxiConnect (
        .master(slave[ARIANE_AXI_MASTER_IDX].Master),

        // Raw axi slave signals the given master will be connected to!
        .axi_awid(cva6_axi_awid),
        .axi_awaddr(cva6_axi_awaddr),
        .axi_awlen(cva6_axi_awlen),
        .axi_awsize(cva6_axi_awsize),
        .axi_awburst(cva6_axi_awburst),
        .axi_awlock(cva6_axi_awlock),
        .axi_awcache(cva6_axi_awcache),
        .axi_awprot(cva6_axi_awprot),
        .axi_awregion(cva6_axi_awregion),
        .axi_awuser(cva6_axi_awuser),
        .axi_awqos(cva6_axi_awqos),
        .axi_awatop(cva6_axi_awatop),
        .axi_awvalid(cva6_axi_awvalid),
        .axi_awready(cva6_axi_awready),
        .axi_wdata(cva6_axi_wdata),
        .axi_wstrb(cva6_axi_wstrb),
        .axi_wlast(cva6_axi_wlast),
        .axi_wuser(cva6_axi_wuser),
        .axi_wvalid(cva6_axi_wvalid),
        .axi_wready(cva6_axi_wready),
        .axi_bid(cva6_axi_bid),
        .axi_bresp(cva6_axi_bresp),
        .axi_bvalid(cva6_axi_bvalid),
        .axi_buser(cva6_axi_buser),
        .axi_bready(cva6_axi_bready),
        .axi_arid(cva6_axi_arid),
        .axi_araddr(cva6_axi_araddr),
        .axi_arlen(cva6_axi_arlen),
        .axi_arsize(cva6_axi_arsize),
        .axi_arburst(cva6_axi_arburst),
        .axi_arlock(cva6_axi_arlock),
        .axi_arcache(cva6_axi_arcache),
        .axi_arprot(cva6_axi_arprot),
        .axi_arregion(cva6_axi_arregion),
        .axi_aruser(cva6_axi_aruser),
        .axi_arqos(cva6_axi_arqos),
        .axi_arvalid(cva6_axi_arvalid),
        .axi_arready(cva6_axi_arready),
        .axi_rid(cva6_axi_rid),
        .axi_rdata(cva6_axi_rdata),
        .axi_rresp(cva6_axi_rresp),
        .axi_rlast(cva6_axi_rlast),
        .axi_ruser(cva6_axi_ruser),
        .axi_rvalid(cva6_axi_rvalid),
        .axi_rready(cva6_axi_rready)
    );

    // DM axi stuff
    // master[DM_AXI_SLAVE_IDX]
    // slave[DM_AXI_MASTER_IDX]

    logic [IdWidth-1:0]                     axi_dm_master_awid;
    logic [63:0]                            axi_dm_master_awaddr;
    logic [7:0]                             axi_dm_master_awlen;
    logic [2:0]                             axi_dm_master_awsize;
    logic [1:0]                             axi_dm_master_awburst;
    logic                                   axi_dm_master_awlock;
    logic [3:0]                             axi_dm_master_awcache;
    logic [2:0]                             axi_dm_master_awprot;
    logic [3:0]                             axi_dm_master_awregion;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_master_awuser;
    logic [3:0]                             axi_dm_master_awqos;
    logic [5:0]                             axi_dm_master_awatop;
    logic                                   axi_dm_master_awvalid;
    logic                                   axi_dm_master_awready;
    logic [63:0]                            axi_dm_master_wdata;
    logic [7:0]                             axi_dm_master_wstrb;
    logic                                   axi_dm_master_wlast;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_master_wuser;
    logic                                   axi_dm_master_wvalid;
    logic                                   axi_dm_master_wready;
    logic [IdWidth-1:0]                     axi_dm_master_bid;
    logic [1:0]                             axi_dm_master_bresp;
    logic                                   axi_dm_master_bvalid;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_master_buser;
    logic                                   axi_dm_master_bready;
    logic [IdWidth-1:0]                     axi_dm_master_arid;
    logic [63:0]                            axi_dm_master_araddr;
    logic [7:0]                             axi_dm_master_arlen;
    logic [2:0]                             axi_dm_master_arsize;
    logic [1:0]                             axi_dm_master_arburst;
    logic                                   axi_dm_master_arlock;
    logic [3:0]                             axi_dm_master_arcache;
    logic [2:0]                             axi_dm_master_arprot;
    logic [3:0]                             axi_dm_master_arregion;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_master_aruser;
    logic [3:0]                             axi_dm_master_arqos;
    logic                                   axi_dm_master_arvalid;
    logic                                   axi_dm_master_arready;
    logic [IdWidth-1:0]                     axi_dm_master_rid;
    logic [63:0]                            axi_dm_master_rdata;
    logic [1:0]                             axi_dm_master_rresp;
    logic                                   axi_dm_master_rlast;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_master_ruser;
    logic                                   axi_dm_master_rvalid;
    logic                                   axi_dm_master_rready;

    logic [IdWidthSlave-1:0]                axi_dm_slave_awid;
    logic [63:0]                            axi_dm_slave_awaddr;
    logic [7:0]                             axi_dm_slave_awlen;
    logic [2:0]                             axi_dm_slave_awsize;
    logic [1:0]                             axi_dm_slave_awburst;
    logic                                   axi_dm_slave_awlock;
    logic [3:0]                             axi_dm_slave_awcache;
    logic [2:0]                             axi_dm_slave_awprot;
    logic [3:0]                             axi_dm_slave_awregion;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_slave_awuser;
    logic [3:0]                             axi_dm_slave_awqos;
    logic [5:0]                             axi_dm_slave_awatop;
    logic                                   axi_dm_slave_awvalid;
    logic                                   axi_dm_slave_awready;
    logic [63:0]                            axi_dm_slave_wdata;
    logic [7:0]                             axi_dm_slave_wstrb;
    logic                                   axi_dm_slave_wlast;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_slave_wuser;
    logic                                   axi_dm_slave_wvalid;
    logic                                   axi_dm_slave_wready;
    logic [IdWidthSlave-1:0]                axi_dm_slave_bid;
    logic [1:0]                             axi_dm_slave_bresp;
    logic                                   axi_dm_slave_bvalid;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_slave_buser;
    logic                                   axi_dm_slave_bready;
    logic [IdWidthSlave-1:0]                axi_dm_slave_arid;
    logic [63:0]                            axi_dm_slave_araddr;
    logic [7:0]                             axi_dm_slave_arlen;
    logic [2:0]                             axi_dm_slave_arsize;
    logic [1:0]                             axi_dm_slave_arburst;
    logic                                   axi_dm_slave_arlock;
    logic [3:0]                             axi_dm_slave_arcache;
    logic [2:0]                             axi_dm_slave_arprot;
    logic [3:0]                             axi_dm_slave_arregion;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_slave_aruser;
    logic [3:0]                             axi_dm_slave_arqos;
    logic                                   axi_dm_slave_arvalid;
    logic                                   axi_dm_slave_arready;
    logic [IdWidthSlave-1:0]                axi_dm_slave_rid;
    logic [63:0]                            axi_dm_slave_rdata;
    logic [1:0]                             axi_dm_slave_rresp;
    logic                                   axi_dm_slave_rlast;
    logic [AXI_USER_WIDTH-1:0]              axi_dm_slave_ruser;
    logic                                   axi_dm_slave_rvalid;
    logic                                   axi_dm_slave_rready;

    tapasco_dm_top wrappedDM (
        .clk_i(clk_i),
        .rst_ni(rst_n),
        .debug_req_core_o(debug_req),
        // DM Interface
        .dmi_req(dmi_req),
        .dmi_wr(dmi_wr),
        .dmi_addr(dmi_addr),
        .dmi_wdata(dmi_wdata),
        .dmi_rdata(dmi_rdata),

        // DM Master connection
        .axi_dm_master_awid(axi_dm_master_awid),
        .axi_dm_master_awaddr(axi_dm_master_awaddr),
        .axi_dm_master_awlen(axi_dm_master_awlen),
        .axi_dm_master_awsize(axi_dm_master_awsize),
        .axi_dm_master_awburst(axi_dm_master_awburst),
        .axi_dm_master_awlock(axi_dm_master_awlock),
        .axi_dm_master_awcache(axi_dm_master_awcache),
        .axi_dm_master_awprot(axi_dm_master_awprot),
        .axi_dm_master_awregion(axi_dm_master_awregion),
        .axi_dm_master_awuser(axi_dm_master_awuser),
        .axi_dm_master_awqos(axi_dm_master_awqos),
        .axi_dm_master_awatop(axi_dm_master_awatop),
        .axi_dm_master_awvalid(axi_dm_master_awvalid),
        .axi_dm_master_awready(axi_dm_master_awready),
        .axi_dm_master_wdata(axi_dm_master_wdata),
        .axi_dm_master_wstrb(axi_dm_master_wstrb),
        .axi_dm_master_wlast(axi_dm_master_wlast),
        .axi_dm_master_wuser(axi_dm_master_wuser),
        .axi_dm_master_wvalid(axi_dm_master_wvalid),
        .axi_dm_master_wready(axi_dm_master_wready),
        .axi_dm_master_bid(axi_dm_master_bid),
        .axi_dm_master_bresp(axi_dm_master_bresp),
        .axi_dm_master_bvalid(axi_dm_master_bvalid),
        .axi_dm_master_buser(axi_dm_master_buser),
        .axi_dm_master_bready(axi_dm_master_bready),
        .axi_dm_master_arid(axi_dm_master_arid),
        .axi_dm_master_araddr(axi_dm_master_araddr),
        .axi_dm_master_arlen(axi_dm_master_arlen),
        .axi_dm_master_arsize(axi_dm_master_arsize),
        .axi_dm_master_arburst(axi_dm_master_arburst),
        .axi_dm_master_arlock(axi_dm_master_arlock),
        .axi_dm_master_arcache(axi_dm_master_arcache),
        .axi_dm_master_arprot(axi_dm_master_arprot),
        .axi_dm_master_arregion(axi_dm_master_arregion),
        .axi_dm_master_aruser(axi_dm_master_aruser),
        .axi_dm_master_arqos(axi_dm_master_arqos),
        .axi_dm_master_arvalid(axi_dm_master_arvalid),
        .axi_dm_master_arready(axi_dm_master_arready),
        .axi_dm_master_rid(axi_dm_master_rid),
        .axi_dm_master_rdata(axi_dm_master_rdata),
        .axi_dm_master_rresp(axi_dm_master_rresp),
        .axi_dm_master_rlast(axi_dm_master_rlast),
        .axi_dm_master_ruser(axi_dm_master_ruser),
        .axi_dm_master_rvalid(axi_dm_master_rvalid),
        .axi_dm_master_rready(axi_dm_master_rready),

        // DM Slave connection
        .axi_dm_slave_awid(axi_dm_slave_awid),
        .axi_dm_slave_awaddr(axi_dm_slave_awaddr),
        .axi_dm_slave_awlen(axi_dm_slave_awlen),
        .axi_dm_slave_awsize(axi_dm_slave_awsize),
        .axi_dm_slave_awburst(axi_dm_slave_awburst),
        .axi_dm_slave_awlock(axi_dm_slave_awlock),
        .axi_dm_slave_awcache(axi_dm_slave_awcache),
        .axi_dm_slave_awprot(axi_dm_slave_awprot),
        .axi_dm_slave_awregion(axi_dm_slave_awregion),
        .axi_dm_slave_awuser(axi_dm_slave_awuser),
        .axi_dm_slave_awqos(axi_dm_slave_awqos),
        .axi_dm_slave_awatop(axi_dm_slave_awatop),
        .axi_dm_slave_awvalid(axi_dm_slave_awvalid),
        .axi_dm_slave_awready(axi_dm_slave_awready),
        .axi_dm_slave_wdata(axi_dm_slave_wdata),
        .axi_dm_slave_wstrb(axi_dm_slave_wstrb),
        .axi_dm_slave_wlast(axi_dm_slave_wlast),
        .axi_dm_slave_wuser(axi_dm_slave_wuser),
        .axi_dm_slave_wvalid(axi_dm_slave_wvalid),
        .axi_dm_slave_wready(axi_dm_slave_wready),
        .axi_dm_slave_bid(axi_dm_slave_bid),
        .axi_dm_slave_bresp(axi_dm_slave_bresp),
        .axi_dm_slave_bvalid(axi_dm_slave_bvalid),
        .axi_dm_slave_buser(axi_dm_slave_buser),
        .axi_dm_slave_bready(axi_dm_slave_bready),
        .axi_dm_slave_arid(axi_dm_slave_arid),
        .axi_dm_slave_araddr(axi_dm_slave_araddr),
        .axi_dm_slave_arlen(axi_dm_slave_arlen),
        .axi_dm_slave_arsize(axi_dm_slave_arsize),
        .axi_dm_slave_arburst(axi_dm_slave_arburst),
        .axi_dm_slave_arlock(axi_dm_slave_arlock),
        .axi_dm_slave_arcache(axi_dm_slave_arcache),
        .axi_dm_slave_arprot(axi_dm_slave_arprot),
        .axi_dm_slave_arregion(axi_dm_slave_arregion),
        .axi_dm_slave_aruser(axi_dm_slave_aruser),
        .axi_dm_slave_arqos(axi_dm_slave_arqos),
        .axi_dm_slave_arvalid(axi_dm_slave_arvalid),
        .axi_dm_slave_arready(axi_dm_slave_arready),
        .axi_dm_slave_rid(axi_dm_slave_rid),
        .axi_dm_slave_rdata(axi_dm_slave_rdata),
        .axi_dm_slave_rresp(axi_dm_slave_rresp),
        .axi_dm_slave_rlast(axi_dm_slave_rlast),
        .axi_dm_slave_ruser(axi_dm_slave_ruser),
        .axi_dm_slave_rvalid(axi_dm_slave_rvalid),
        .axi_dm_slave_rready(axi_dm_slave_rready)
    );

    raw_axi_slave_connect #(
        .AXI_ID_WIDTH(tapasco_axi::IdWidth),
        .req_t(tapasco_axi::req_t),
        .resp_t(tapasco_axi::resp_t)
    ) dmMasterConnect (
        .master(slave[DM_AXI_MASTER_IDX].Master),

        // Raw axi slave signals the given master will be connected to!
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

    // Connect master 
    raw_axi_master_connect #(
        .AXI_ID_WIDTH(IdWidthSlave),
        .req_t(tapasco_axi::req_slv_t),
        .resp_t(tapasco_axi::resp_slv_t)
    ) axiMemConnector (
        .slave(master[DM_AXI_SLAVE_IDX].Slave),

        // Raw axi slave signals the given master will be connected to!
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
            ROMBase
        }),
        .end_addr_i   ({
            DebugBase    + DebugLength - 1,
            ROMBase      + ROMLength - 1
        }),
        .valid_rule_i ({(NB_REGION * NB_MASTER){1'b1}})
    );

endmodule

module tb_sram #(
    int unsigned DATA_WIDTH = 64,
    int unsigned NUM_WORDS  = 8096
)(
   input  logic                          clk_i,
   input  logic                          rst_ni,

   input  logic                          req_i,
   input  logic                          we_i,
   input  logic [$clog2(NUM_WORDS)-1:0]  addr_i,
   input  logic [DATA_WIDTH-1:0]         wdata_i,
   input  logic [DATA_WIDTH/8-1:0]       be_i,
   output logic [DATA_WIDTH-1:0]         rdata_o
);
    localparam ADDR_WIDTH = $clog2(NUM_WORDS);

    logic [DATA_WIDTH-1:0] ram [NUM_WORDS-1:0];
    logic [ADDR_WIDTH-1:0] raddr_q;

    initial begin
        ram[2048] = 64'h00000000_00000539;
        ram[78] = 64'h00000000_00008067;
        ram[77] = 64'h02010113_01812403;
        ram[76] = 64'h01c12083_00078513;
        ram[75] = 64'h00000793_ef1ff0ef;
        ram[74] = 64'he6dff0ef_00400513;
        ram[73] = 64'h00078593_00f707b3;
        ram[72] = 64'hfec42783_53900713;
        ram[71] = 64'h00e7a023_eef70713;
        ram[70] = 64'hdeadc737_fe842783;
        ram[69] = 64'hfef42423_000107b7;
        ram[68] = 64'hfef42623_02a00793;
        ram[67] = 64'hf99ff0ef_02010413;
        ram[66] = 64'h00812c23_00112e23;
        ram[65] = 64'hfe010113_00008067;
        ram[64] = 64'h02010113_01812403;
        ram[63] = 64'h01c12083_00000013;
        ram[62] = 64'hf55ff0ef_ed1ff0ef;
        ram[61] = 64'h00400513_fff00593;
        ram[60] = 64'h00f70a63_fec42783;
        ram[59] = 64'hfe842703_fef42423;
        ram[58] = 64'h305027f3_30579073;
        ram[57] = 64'hfec42783_fef42623;
        ram[56] = 64'h18000793_02010413;
        ram[55] = 64'h00812c23_00112e23;
        ram[54] = 64'hfe010113_00008067;
        ram[53] = 64'h01010113_00812403;
        ram[52] = 64'h00c12083_00000013;
        ram[51] = 64'hfadff0ef_f29ff0ef;
        ram[50] = 64'h00400513_ffe00593;
        ram[49] = 64'h01010413_00812423;
        ram[48] = 64'h00112623_ff010113;
        ram[47] = 64'h00000013_0000006f;
        ram[46] = 64'h00e7a023_00100713;
        ram[45] = 64'hfe842783_fef42423;
        ram[44] = 64'h00f707b3_000047b7;
        ram[43] = 64'hfec42703_fef42623;
        ram[42] = 64'h110007b7_02010413;
        ram[41] = 64'h00812e23_fe010113;
        ram[40] = 64'h00008067_03010113;
        ram[39] = 64'h02c12403_00078513;
        ram[38] = 64'h0007a783_00f707b3;
        ram[37] = 64'hfec42703_00279793;
        ram[36] = 64'hfdc42783_fef42623;
        ram[35] = 64'h110007b7_fca42e23;
        ram[34] = 64'h03010413_02812623;
        ram[33] = 64'hfd010113_00008067;
        ram[32] = 64'h03010113_02c12403;
        ram[31] = 64'h00000013_00e7a023;
        ram[30] = 64'hfd842703_fe842783;
        ram[29] = 64'hfef42423_00f707b3;
        ram[28] = 64'hfec42703_00279793;
        ram[27] = 64'hfdc42783_fef42623;
        ram[26] = 64'h110007b7_fcb42c23;
        ram[25] = 64'hfca42e23_03010413;
        ram[24] = 64'h02812623_fd010113;
        ram[16] = 64'h188000ef_00010113;
        ram[15] = 64'h00008137_00000f93;
        ram[14] = 64'h00000f13_00000e93;
        ram[13] = 64'h00000e13_00000d93;
        ram[12] = 64'h00000d13_00000c93;
        ram[11] = 64'h00000c13_00000b93;
        ram[10] = 64'h00000b13_00000a93;
        ram[9] = 64'h00000a13_00000993;
        ram[8] = 64'h00000913_00000893;
        ram[7] = 64'h00000813_00000793;
        ram[6] = 64'h00000713_00000693;
        ram[5] = 64'h00000613_00000593;
        ram[4] = 64'h00000513_00000493;
        ram[3] = 64'h00000413_00000393;
        ram[2] = 64'h00000313_00000293;
        ram[1] = 64'h00000213_00000193;
        ram[0] = 64'h00000113_00000093;
    end

    always_ff @(posedge clk_i) begin
        if (req_i) begin
            if (!we_i) begin
                raddr_q <= addr_i;
            end else begin
                for (int i = 0; i < DATA_WIDTH / 8; i++)
                    if (be_i[i]) ram[addr_i][i*8 +: 8] <= wdata_i[i*8 +: 8];
            end
        end
    end

    assign rdata_o = ram[raddr_q];

endmodule

