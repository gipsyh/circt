# [ImportVerilog][LLHD] Add external reset hint support for deseq

## Motivation

This PR adds an explicit external reset hint to the Verilog import pipeline so that reset behavior written in Verilog can be preserved as reset semantics on `seq.firreg`.

Today, some reset patterns are lowered into data-path muxes before or during desequentialization. This is functionally correct, but it makes the generated IR less friendly for later formal analysis.

The goal is to let users tell `circt-verilog` which module input should be treated as the reset signal, for example:

```sh
circt-verilog --reset=rst_n --reset-active-low input.sv
```

This gives the LLHD deseq pass enough information to preserve synchronous reset behavior explicitly.

## Implementation

- Adds `external-reset` and `external-reset-active-low` options to the
  LLHD-to-core pipeline.
- Exposes those options in `circt-verilog` as `--reset=<input>` and
  `--reset-active-low`.
- Threads the options into `llhd-deseq`.
- Resolves the requested reset as a one-bit module input and records aliases
  created by the Verilog import pipeline's direct signal/probe pattern.
- Extends deseq's boolean data-flow model with an optional external reset term.
- First preserves the existing asynchronous reset inference path. If an
  external reset is requested for an async-reset process, the inferred reset must
  match the requested input and polarity.
- Adds synchronous reset matching for single-clock-trigger processes when an
  external reset hint is available.
- Extends `ResetInfo` with `isAsync` so `seq.firreg` can be emitted with either
  `reset async` or `reset sync`.

## Tests

Adds `test/circt-verilog/external-reset.sv`, covering:

- active-low external synchronous reset lowered to `seq.firreg reset sync`;
- active-low asynchronous reset still lowered to `seq.firreg reset async`;
- polarity mismatch does not incorrectly force async reset lowering;
- a reset routed through a wire is handled conservatively.

## Notes

The reset hint is intentionally a hint, not a request to rewrite module interfaces. If the named input does not exist, is not `i1`, or the process does not match a supported reset pattern, deseq falls back to the existing reset-less register detection behavior.
