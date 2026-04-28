// RUN: circt-verilog --reset=rst_n --reset-active-low %s | FileCheck %s --check-prefix=RESET
// RUN: circt-verilog --reset=rst_n %s | FileCheck %s --check-prefix=MISMATCH
// RUN: not circt-verilog --reset-active-low %s 2>&1 | FileCheck %s --check-prefix=ERROR
// REQUIRES: slang
// UNSUPPORTED: valgrind

// ERROR: error: `--reset-active-low` requires `--reset`

// RESET-LABEL: hw.module @external_sync_reset
// RESET: [[RST:%.+]] = comb.xor %rst_n, %true : i1
// RESET: seq.firreg %d clock {{%.+}} reset sync [[RST]], %c-6_i4 : i4
module external_sync_reset(input logic clk, input logic rst_n,
                           input logic [3:0] d, output logic [3:0] q);
  always @(posedge clk) begin
    if (!rst_n) q <= 4'ha;
    else q <= d;
  end
endmodule

// RESET-LABEL: hw.module @external_async_reset
// RESET: [[RST:%.+]] = comb.xor %rst_n, %true : i1
// RESET: seq.firreg %d clock {{%.+}} reset async [[RST]], %c-6_i4 : i4

// MISMATCH-LABEL: hw.module @external_async_reset
// MISMATCH: llhd.process
// MISMATCH-NOT: seq.firreg
// MISMATCH-LABEL: hw.module @external_wire_reset
module external_async_reset(input logic clk, input logic rst_n,
                            input logic [3:0] d, output logic [3:0] q);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 4'ha;
    else q <= d;
  end
endmodule

// RESET-LABEL: hw.module @external_wire_reset
// RESET: [[MUX:%.+]] = comb.mux {{.*}} : i4
// RESET: seq.firreg [[MUX]] clock {{%.+}} : i4
module external_wire_reset(input logic clk, input logic rst_n_in,
                           input logic [3:0] d, output logic [3:0] q);
  wire rst_n = rst_n_in;
  always @(posedge clk) begin
    if (!rst_n) q <= 4'ha;
    else q <= d;
  end
endmodule
