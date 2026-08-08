# RISC-V Compiler-Directed Static Branch Prediction (Hint-Bit)

Design and hardware-level evaluation of a compiler-directed static branch prediction mechanism for a 5-stage pipelined RISC-V processor, implemented and validated on FPGA.

## Overview

Deeply pipelined processors pay a control-hazard penalty every time a branch is mispredicted — in a standard 5-stage RISC-V pipeline, this costs 2 cycles per misprediction. Dynamic predictors (BHTs, BTBs) fix this but cost silicon area and power. This project explores a lighter-weight alternative: **repurposing bit[27] of the RISC-V B-type instruction as a static "hint bit"**, allowing the compiler to tell the hardware whether a branch is likely taken — with zero new opcodes and zero code-size overhead.

**Research question:** How much IPC improvement is achievable without dynamic hardware, and at what code-size cost?

The baseline (fixed predict-not-taken) and modified (hint-bit) pipelines were both implemented in structural Verilog, verified in simulation, and validated on real hardware using an Integrated Logic Analyzer (ILA).

## Key Results (Fibonacci benchmark)

| Metric | Baseline | Modified (Hint-Bit) | Improvement |
|---|---|---|---|
| Total Instructions | 64 | 64 | — |
| Total Cycles | 90 | 78 | 13.3% fewer |
| Mispredictions | 7 | 1 | **85.7% reduction** |
| Misprediction Rate | 10.94% | 1.56% | 85.7% reduction |
| IPC | 0.711 | 0.821 | **15.4% improvement** |
| Code-size overhead | — | — | **0%** |

The hint bit converted 6 of 7 mispredicted branches into correctly-predicted taken paths, each saving a 2-cycle pipeline flush — with no runtime state, no warm-up time, and fully deterministic behavior.

## How It Works

- **Baseline:** Fixed predict-not-taken. Every taken branch costs a 2-cycle stall, regardless of predictability.
- **Modified:** Bit[27] of the B-type instruction (normally part of the branch immediate) is repurposed as a 1-bit static prediction flag:
  - `HINT = 1` → predict taken, PC redirected to target in the **IF** stage
  - `HINT = 0` → predict not taken, sequential `PC + 4` fetch
- The **Branch Unit** in the EX stage validates the prediction against the actual ALU-resolved outcome. On a match, execution continues uninterrupted; on a mismatch, a standard pipeline flush and redirect occurs — identical in cost to the baseline's flush.
- The hint bit is propagated through `IF/ID` and `ID/EX` pipeline registers to keep validation synchronized with the correct instruction. No changes were required in MEM or WB.



## Baseline Performance Across Kernels

The baseline architecture (predict-not-taken) was characterized across five standard kernels to establish a comparison floor:

| Program | Cycles | Instructions | Mispredictions | IPC |
|---|---|---|---|---|
| Fibonacci | 90 | 64 | 7 | 0.711 |
| Selection Sort | 91 | 67 | 6 | 0.736 |
| Bitcount | 91 | 59 | 15 | 0.648 |
| Strlen | 91 | 39 | 20 | 0.429 |
| Matrix Multiply | 91 | 40 | 14 | 0.711 |

> **Scope note:** The hint-bit modified architecture has currently been implemented and benchmarked against the baseline for the **Fibonacci** kernel only. Extending the hint-bit comparison to selection sort, bitcount, strlen, and matrix multiply is planned as future work.

## Hardware Validation (Zybo Z7-10 FPGA)

Functional correctness was verified first in simulation (Xilinx XSim), then validated on physical silicon using a Digilent **Zybo Z7-10** (Zynq-7010 SoC). An Integrated Logic Analyzer (ILA) core was instantiated in the top-level wrapper, triggered on the halt instruction (`jal x0, 0`), and used to probe internal performance counters (`total_cycles`, `total_instrs`, `total_mispred`, `debug_pc`) in real time.

The captured hardware waveform confirmed the PC correctly jumping backward on hint-predicted taken branches, and showed `total_mispred` remaining stable through nearly the entire loop — matching simulation results exactly and proving cycle-accurate behavior at real clock speeds.


## Area & Timing (Post-Implementation)

| Resource | Used | Available | Utilization |
|---|---|---|---|
| Slice LUTs | 2,493 | 17,600 | 14.16% |
| Slice Registers | 3,924 | 35,200 | 11.15% |
| Block RAM Tiles | 14.5 | 60 | 24.17% (mostly ILA debug core) |

- Target clock: 8.000 ns (125 MHz)
- Worst Negative Slack (WNS): **−0.700 ns**
- Max operating frequency (Fmax): **~94.3 MHz**
- Critical path: ALU combinational logic → PC muxing for static branch redirection

The hint-bit logic added **less than 0.1%** additional hardware resource usage over the baseline.

## Repository Structure

```
riscv-static-branch-prediction/
├── baseline/
│   ├── src/                   # Baseline pipeline (predict-not-taken) source
│   ├── constraints/            # .xdc pin/clock constraints
│   └── reports/
│       ├── timing_report.txt
│       └── utilization_report.txt
├── modified/
│   ├── src/                  
│   ├── constraints/
│   └── reports/
│       ├── timing_report.txt
│       └── utilization_report.txt
├── benchmarks/
│   └── fibonacci.s           
│   ├── ila_data.csv
│   ├── iladata.ila
│   └── images/               
├── images/
│   ├── pipeline_architecture.png
│   └── ila_waveform.png
├── LICENSE
└── README.md
```

## Tools & Setup

- **HDL:** Structural Verilog
- **Toolchain:** Xilinx Vivado Design Suite (version: _fill in your version, e.g. 2023.2_)
- **Simulator:** Xilinx XSim
- **Target board:** Digilent Zybo Z7-10 (Zynq-7010 SoC)
- **Debug core:** Xilinx Integrated Logic Analyzer (ILA)

## Limitations & Future Work

- The hint-bit approach is **static** — for branches with data-dependent, unpredictable behavior (e.g. searches over random data), the hint offers no advantage over the default policy.
- Repurposing bit[27] slightly reduces maximum branch displacement range; not an issue for this benchmark suite, but could matter for very large monolithic programs.
- Hint-bit comparison is currently validated on Fibonacci only. Extending to selection sort, bitcount, strlen, and matrix multiply (all already benchmarked under the baseline policy) is the immediate next step.

## Acknowledgment

Baseline RISC-V pipeline environment provided by course instructors. Implementation and FPGA validation performed using Xilinx Vivado.

## Author

**Golla Manogna**
School of Computing and Electrical Engineering, IIT Mandi
