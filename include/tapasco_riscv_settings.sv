`ifndef TAPASCO_RISCV_SETTINGS_SV
`define TAPASCO_RISCV_SETTINGS_SV

/*
    File to set global defines which are required to use this core as PE for TaPaSCo.
    A script is run to ensure that this file is included in EVERY other file.
*/

// Select the correct cache
`define WT_DCACHE

// This define is intended to disable/comment certain code that breaks compilation with vivado
`define TAPASCO_DISABLE_FOR_VIVADO

`endif
