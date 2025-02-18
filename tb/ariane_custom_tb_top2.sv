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

module ariane_custom_tb_top2 #(
    parameter int unsigned AXI_USER_WIDTH    = 1,
    parameter int unsigned AXI_ADDRESS_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH    = 64,
    parameter int unsigned NUM_WORDS         = 32768         // memory size
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
    input   logic                                 dmi_req,                // DMI request
    input   logic                                 dmi_wr,                 // DMI write
    input   logic [7-1:0]     dmi_addr,               // DMI address
    input   logic [32-1:0]     dmi_wdata,              // DMI write data
    output  logic [32-1:0]     dmi_rdata              // DMI read data

);

    logic [tapasco_axi::IdWidthSlave-1:0]                io_axi_mem_awid;
    logic [63:0]                            io_axi_mem_awaddr;
    logic [7:0]                             io_axi_mem_awlen;
    logic [2:0]                             io_axi_mem_awsize;
    logic [1:0]                             io_axi_mem_awburst;
    logic                                   io_axi_mem_awlock;
    logic [3:0]                             io_axi_mem_awcache;
    logic [2:0]                             io_axi_mem_awprot;
    logic [3:0]                             io_axi_mem_awregion;
    logic [3:0]                             io_axi_mem_awuser;
    logic [3:0]                             io_axi_mem_awqos;
    logic [5:0]                             io_axi_mem_awatop;
    logic                                   io_axi_mem_awvalid;
    logic                                   io_axi_mem_awready;
    logic [63:0]                            io_axi_mem_wdata;
    logic [7:0]                             io_axi_mem_wstrb;
    logic                                   io_axi_mem_wlast;
    logic [3:0]                             io_axi_mem_wuser;
    logic                                   io_axi_mem_wvalid;
    logic                                   io_axi_mem_wready;
    logic [tapasco_axi::IdWidthSlave-1:0]                io_axi_mem_bid;
    logic [1:0]                             io_axi_mem_bresp;
    logic                                   io_axi_mem_bvalid;
    logic [3:0]                             io_axi_mem_buser;
    logic                                   io_axi_mem_bready;
    logic [tapasco_axi::IdWidthSlave-1:0]                io_axi_mem_arid;
    logic [63:0]                            io_axi_mem_araddr;
    logic [7:0]                             io_axi_mem_arlen;
    logic [2:0]                             io_axi_mem_arsize;
    logic [1:0]                             io_axi_mem_arburst;
    logic                                   io_axi_mem_arlock;
    logic [3:0]                             io_axi_mem_arcache;
    logic [2:0]                             io_axi_mem_arprot;
    logic [3:0]                             io_axi_mem_arregion;
    logic [3:0]                             io_axi_mem_aruser;
    logic [3:0]                             io_axi_mem_arqos;
    logic                                   io_axi_mem_arvalid;
    logic                                   io_axi_mem_arready;
    logic [tapasco_axi::IdWidthSlave-1:0]                io_axi_mem_rid;
    logic [63:0]                            io_axi_mem_rdata;
    logic [1:0]                             io_axi_mem_rresp;
    logic                                   io_axi_mem_rlast;
    logic [3:0]                             io_axi_mem_ruser;
    logic                                   io_axi_mem_rvalid;
    logic                                   io_axi_mem_rready;

    ariane_custom_top core_wrapper_top (
        .clk(clk),
        .rst_n(rst_n),
        .boot_addr_i(boot_addr_i),
        .hart_id_i(hart_id_i),
        .irq_i(irq_i),
        .ipi_i(ipi_i),
        .time_irq_i(time_irq_i),
        .dmi_req(dmi_req),
        .dmi_wr(dmi_wr),
        .dmi_addr(dmi_addr),
        .dmi_wdata(dmi_wdata),
        .dmi_rdata(dmi_rdata),

        // Axi ports
        .io_axi_mem_awid(io_axi_mem_awid),
        .io_axi_mem_awaddr(io_axi_mem_awaddr),
        .io_axi_mem_awlen(io_axi_mem_awlen),
        .io_axi_mem_awsize(io_axi_mem_awsize),
        .io_axi_mem_awburst(io_axi_mem_awburst),
        .io_axi_mem_awlock(io_axi_mem_awlock),
        .io_axi_mem_awcache(io_axi_mem_awcache),
        .io_axi_mem_awprot(io_axi_mem_awprot),
        .io_axi_mem_awregion(io_axi_mem_awregion),
        .io_axi_mem_awuser(io_axi_mem_awuser),
        .io_axi_mem_awqos(io_axi_mem_awqos),
        .io_axi_mem_awatop(io_axi_mem_awatop),
        .io_axi_mem_awvalid(io_axi_mem_awvalid),
        .io_axi_mem_awready(io_axi_mem_awready),
        .io_axi_mem_wdata(io_axi_mem_wdata),
        .io_axi_mem_wstrb(io_axi_mem_wstrb),
        .io_axi_mem_wlast(io_axi_mem_wlast),
        .io_axi_mem_wuser(io_axi_mem_wuser),
        .io_axi_mem_wvalid(io_axi_mem_wvalid),
        .io_axi_mem_wready(io_axi_mem_wready),
        .io_axi_mem_bid(io_axi_mem_bid),
        .io_axi_mem_bresp(io_axi_mem_bresp),
        .io_axi_mem_bvalid(io_axi_mem_bvalid),
        .io_axi_mem_buser(io_axi_mem_buser),
        .io_axi_mem_bready(io_axi_mem_bready),
        .io_axi_mem_arid(io_axi_mem_arid),
        .io_axi_mem_araddr(io_axi_mem_araddr),
        .io_axi_mem_arlen(io_axi_mem_arlen),
        .io_axi_mem_arsize(io_axi_mem_arsize),
        .io_axi_mem_arburst(io_axi_mem_arburst),
        .io_axi_mem_arlock(io_axi_mem_arlock),
        .io_axi_mem_arcache(io_axi_mem_arcache),
        .io_axi_mem_arprot(io_axi_mem_arprot),
        .io_axi_mem_arregion(io_axi_mem_arregion),
        .io_axi_mem_aruser(io_axi_mem_aruser),
        .io_axi_mem_arqos(io_axi_mem_arqos),
        .io_axi_mem_arvalid(io_axi_mem_arvalid),
        .io_axi_mem_arready(io_axi_mem_arready),
        .io_axi_mem_rid(io_axi_mem_rid),
        .io_axi_mem_rdata(io_axi_mem_rdata),
        .io_axi_mem_rresp(io_axi_mem_rresp),
        .io_axi_mem_rlast(io_axi_mem_rlast),
        .io_axi_mem_ruser(io_axi_mem_ruser),
        .io_axi_mem_rvalid(io_axi_mem_rvalid),
        .io_axi_mem_rready(io_axi_mem_rready)
    );

    logic                         req;
    logic                         we;
    logic [AXI_ADDRESS_WIDTH-1:0] addr;
    logic [AXI_DATA_WIDTH/8-1:0]  be;
    logic [AXI_DATA_WIDTH-1:0]    wdata;
    logic [AXI_DATA_WIDTH-1:0]    rdata;

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
        .AXI_ID_WIDTH   ( tapasco_axi::IdWidthSlave ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
    ) axiBus();

    axi2mem #(
        .AXI_ID_WIDTH   ( tapasco_axi::IdWidthSlave ),
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
    ) i_axi2mem (
        .clk_i  ( clk        ),
        .rst_ni ( rst_n   ),
        .slave  ( axiBus.Slave ),
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
        .clk_i      ( clk                                                                       ),
        .rst_ni     ( rst_n                                                                      ),
        .req_i      ( req                                                                         ),
        .we_i       ( we                                                                          ),
        .addr_i     ( addr[$clog2(NUM_WORDS)-1+$clog2(AXI_DATA_WIDTH/8):$clog2(AXI_DATA_WIDTH/8)] ),
        .wdata_i    ( wdata                                                                       ),
        .be_i       ( be                                                                          ),
        .rdata_o    ( rdata                                                                       )
    );

    raw_axi_slave_connect #(
        .AXI_ID_WIDTH(tapasco_axi::IdWidthSlave),
        .req_t(tapasco_axi::req_slv_t),
        .resp_t(tapasco_axi::resp_slv_t)
    ) tbMemConnect (
        .master(axiBus.Master),

        // Raw axi slave signals the given master will be connected to!
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
