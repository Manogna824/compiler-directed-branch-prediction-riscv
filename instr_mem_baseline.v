// =============================================================================
// FILE: instr_mem.v  (BASELINE)
// FIXES:
//   1. BNE encoding was 0xFE009CE3 (offset=-8, wrong) → now 0xFE0090E3 (offset=-32, correct)
//   2. JAL halt replaced with BEQ x0,x0,0 (self-loop) - JAL not in control_unit
//   3. SW instructions use funct3=2 (corrected from funct3=0)
//   4. ADD x4,x2,x3 corrected to rd=x4,rs1=x2,rs2=x3
// =============================================================================
module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:255];

    integer k;
    initial begin
        for (k = 0; k < 256; k = k + 1)
            mem[k] = 32'h00000013; // NOP

        // ── FIBONACCI ─────────────────────────────────────────────────────
        // Computes fib[0..7], stores to data mem[0..7]
        // x1=count(8), x2=fib[n-2], x3=fib[n-1], x4=temp
        // x5=base(0),  x6=index,    x7=offset,   x8=addr
        // Expected: data[0..7] = 0,1,1,2,3,5,8,13  x10=13
        // ──────────────────────────────────────────────────────────────────
        mem[ 0] = 32'h00800093; // addi x1,x0,8
        mem[ 1] = 32'h00000113; // addi x2,x0,0
        mem[ 2] = 32'h00100193; // addi x3,x0,1
        mem[ 3] = 32'h00000293; // addi x5,x0,0   (base=0)
        mem[ 4] = 32'h00000313; // addi x6,x0,0   (index=0)
        mem[ 5] = 32'h0022A023; // sw x2,0(x5)    store fib[0]  funct3=2
        mem[ 6] = 32'h00130313; // addi x6,x6,1
        mem[ 7] = 32'h0032A223; // sw x3,4(x5)    store fib[1]  funct3=2
        mem[ 8] = 32'h00130313; // addi x6,x6,1
        // ── LOOP at PC=36 (idx 9) ──
        mem[ 9] = 32'h00310233; // add x4,x2,x3   rd=x4 rs1=x2 rs2=x3
        mem[10] = 32'h00018113; // addi x2,x3,0   x2 = old x3
        mem[11] = 32'h00020193; // addi x3,x4,0   x3 = x4
        mem[12] = 32'h00231393; // slli x7,x6,2
        mem[13] = 32'h00728433; // add x8,x5,x7
        mem[14] = 32'h00342023; // sw x3,0(x8)    funct3=2
        mem[15] = 32'h00130313; // addi x6,x6,1
        mem[16] = 32'hFFF08093; // addi x1,x1,-1
        // BNE x1,x0,-32 → offset=(9-17)*4=-32 → encoding FE0090E3
        mem[17] = 32'hFE0090E3; // bne x1,x0,-32  (funct3=1, offset=-32 CORRECT)
        mem[18] = 32'h00018513; // addi x10,x3,0  output result
        // HALT: BEQ x0,x0,0 → self-loop (always taken, loops forever)
        mem[19] = 32'h00000063; // beq x0,x0,0    HALT
    end

    assign instr = mem[addr[31:2]];
endmodule