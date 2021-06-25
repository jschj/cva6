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

    ariane_axi_soc::req_t    axi_ariane_req;
    ariane_axi_soc::resp_t   axi_ariane_resp;

    localparam logic[63:0] DebugLength    = 64'h1000;
    localparam logic[63:0] ROMLength      = 64'h04000;
    localparam logic[63:0] CLINTLength    = 64'hC0000;
    localparam logic[63:0] DMEMLength     = 64'h04000;
    //localparam logic[63:0] DRAMLength     = 64'h04000;

    localparam logic[63:0] DebugBase = 64'h1200_0000;
    localparam logic[63:0] ROMBase      = 64'h0000_0000;
    localparam logic[63:0] CLINTBase    = 64'h0200_0000;
    //localparam logic[63:0] DRAMBase     = 64'h0004_0000;
    localparam logic[63:0] DMEMBase     = 64'h0004_0000;


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
        NrExecuteRegionRules:  3,
        ExecuteRegionAddrBase: {DMEMBase,   ROMBase,   DebugBase},
        //ExecuteRegionAddrBase: {DRAMBase,   DMEMBase,   ROMBase,   DebugBase},
        ExecuteRegionLength:   {DMEMLength, ROMLength, DebugLength},
        //ExecuteRegionLength:   {DRAMLength, DMEMLength, ROMLength, DebugLength},
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

    localparam IdWidth   = 4;
    localparam IdWidthSlave   = 5; //TODO

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
        .AXI_ID_WIDTH   ( IdWidth ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH      )
    ) slave[2-1:0]();

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
        .AXI_ID_WIDTH   ( IdWidthSlave ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
    ) master[2-1:0]();

    axi_master_connect i_axi_master_connect_ariane (
        .axi_req_i(axi_ariane_req),
        .axi_resp_o(axi_ariane_resp),
        .master(slave[0])
    );

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
        .slave  ( master[1] ),
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
    // TODO this might trigger to often... add edge detection for triggering a single request?
    assign dmi_req_valid = dmi_req;
    assign dmi_req_i.op = dmi_req ? (dmi_wr ? dm::DTM_WRITE : dm::DTM_READ) : dm::DTM_NOP;
    assign dmi_req_i.addr = dmi_addr;
    assign dmi_req_i.data = dmi_wdata;

    logic                  dmi_resp_valid;
    logic                  dmi_resp_ready;
    assign dmi_resp_ready = 1'b1;
    dm::dmi_resp_t         dmi_resp;
    //TODO might need flopping to preserve the last valid value
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
        .slave      ( master[0] ),
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
        .master(slave[1])
    );

    // AXI Interconnect
    axi_node_intf_wrap #(
        .NB_SLAVE           ( 2                          ),
        .NB_MASTER          ( 2                          ),
        .NB_REGION          ( 2                          ),
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
        .valid_rule_i ({{2 * 2}{1'b1}})
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

