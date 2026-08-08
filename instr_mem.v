// =============================================================================
// FILE: instr_mem.v  (MODIFIED)
// DESC: Instruction memory for HINT-BIT static branch prediction.
//
// HINT BIT ENCODING:
//   In standard RISC-V, B-type bit[7] carries imm[11].
//   In our CUSTOM ENCODING for hint-bit:
//   ┌────────────────────────────────────────────────┐
//   │  We REPURPOSE bit[27] of the 32-bit instruction│
//   │  as the HINT BIT for B-type instructions.      │
//   │  Bit[27] is unused (always 0) in standard BEQ/ │
//   │  BNE since rs2 only uses bits[24:20].          │
//   │                                                 │
//   │  hint=1 → compiler predicts TAKEN              │
//   │  hint=0 → compiler predicts NOT TAKEN          │
//   └────────────────────────────────────────────────┘
//
//   The branch TARGET is still computed from standard B-type immediate
//   fields [31,30:25,11:8,7] → sign-extended <<1.
//   Bit[27] being 1 just tells the predictor to prefetch branch_target.
//
// NOTE: All non-branch instructions are identical to baseline.
//       Only BEQ/BNE encodings may have bit[27]=1 for "predict taken".
// =============================================================================
module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:255];
integer i;
    initial begin
        
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013; // NOP

        // ----------------------------------------------------------------
        // FIBONACCI (same as baseline but loop branch has hint=1)
        // Bit[27] set to 1 in the BNE instruction to predict TAKEN
        // ----------------------------------------------------------------
        mem[0]  = 32'h00800093; // addi x1, x0, 8
        mem[1]  = 32'h00000113; // addi x2, x0, 0
        mem[2]  = 32'h00100193; // addi x3, x0, 1
        mem[3]  = 32'h00000293; // addi x5, x0, 0
        mem[4]  = 32'h00000313; // addi x6, x0, 0
        mem[5]  = 32'h00228023; // sw x2, 0(x5)
        mem[6]  = 32'h00130313; // addi x6, x6, 1
        mem[7]  = 32'h00328223; // sw x3, 4(x5)
        mem[8]  = 32'h00130313; // addi x6, x6, 1
        mem[9]  = 32'h003100B3; // add x4, x2, x3
        mem[10] = 32'h00018113; // addi x2, x3, 0
        mem[11] = 32'h00020193; // addi x3, x4, 0
        mem[12] = 32'h00231393; // slli x7, x6, 2
        mem[13] = 32'h00728433; // add x8, x5, x7
        mem[14] = 32'h00340023; // sw x3, 0(x8)
        mem[15] = 32'h00130313; // addi x6, x6, 1
        mem[16] = 32'hFFF08093; // addi x1, x1, -1
        // BNE with HINT=1 (bit[27]=1): FE009CE3 → set bit27 → FE809CE3
        // Standard BNE back 8 instructions:
        // imm = -8*4 = -32 = 0xFFFFFFE0
        // B-type encoding of -32: imm[12|10:5|4:1|11]
        // imm = 111111100000 → [12]=1,[11]=1,[10:5]=111110,[4:1]=0000
        // Standard: 1_111110_00001_00000_001_0000_1_1100011 = FE009CE3
        // Set bit27: FE009CE3 | 0x08000000 = FE809CE3 (hint=TAKEN)
        mem[17] = 32'hFE809CE3; // BNE x1,x0,-32 WITH HINT=1
        mem[18] = 32'h0000006F; // JAL x0, 0 (halt)
    end

    assign instr = mem[addr[31:2]];
endmodule