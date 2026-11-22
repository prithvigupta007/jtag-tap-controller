# JTAG TAP Controller

A Verilog-based implementation of a JTAG (Joint Test Action Group) Test Access Port (TAP) Controller with instruction decoding, data registers, and boundary-scan functionality.

## Features

- 16-state JTAG TAP Controller FSM
- 4-bit Instruction Register
- Instruction Decoder
- 32-bit IDCODE Register
- 1-bit BYPASS Register
- Boundary Scan Register
- IDCODE, EXTEST, SAMPLE and BYPASS instructions
- Unsupported-instruction fallback to BYPASS
- Asynchronous reset
- Self-checking Verilog testbench

## Architecture

| Module | Description |
|---|---|
| tap_controller.v | Implements the 16-state TAP FSM |
| instruction_register.v | Captures, shifts and updates instructions |
| instruction_decoder.v | Decodes active instructions |
| idcode_register.v | Implements the 32-bit IDCODE register |
| bypass_register.v | Implements the one-bit BYPASS register |
| boundary_scan.v | Implements boundary capture, shift and update |
| jtag_top.v | Integrates all JTAG modules |

## Supported Instructions

| Instruction | Opcode | Function |
|---|---|---|
| IDCODE | 0001 | Reads device identification code |
| EXTEST | 0010 | Tests external connections |
| SAMPLE | 0011 | Captures external pin values |
| BYPASS | 1111 | Provides a one-bit serial bypass path |

Unsupported instructions select BYPASS in this implementation.

## Project Structure

```text
jtag-tap-controller/
├── rtl/
├── tb/
├── docs/
├── simulation/
├── .gitignore
├── LICENSE
└── README.md
```

## Simulation

**Simulator:** QuestaSim / ModelSim

Compile from the project root:

```tcl
vlib work
vlog rtl/tap_controller.v
vlog rtl/instruction_register.v
vlog rtl/instruction_decoder.v
vlog rtl/bypass_register.v
vlog rtl/idcode_register.v
vlog rtl/boundary_scan.v
vlog rtl/jtag_top.v
vlog tb/tb_jtag_top.v
```

Run:

```tcl
vsim work.tb_jtag_top
run -all
```

## Verification Results

| Metric | Result |
|---|---:|
| Total checks | 54 |
| Passed | 54 |
| Failed | 0 |
| Result | PASS |

Verified functionality includes TAP state transitions, asynchronous reset recovery, instruction shifting and updating, EXTEST, BYPASS, IDCODE readback and SAMPLE capture.

## Tools Used

- Verilog HDL
- QuestaSim / ModelSim
- Git and GitHub

## Scope

This is an educational RTL implementation. Passing the included simulation tests does not establish complete IEEE 1149.1 compliance or physical hardware validation.

## Author

Prithvi Gupta
