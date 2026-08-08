// =============================================================================
// FILE: register_file.v
// DESC: 32x32 register file. x0 always reads 0.
//       Synchronous write, asynchronous read.
//       dbg_x10: hardwired read of register x10 for testbench (no hierarchy ref).
// =============================================================================
module register_file (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2,
    output wire [31:0] dbg_x10   // always reads x10, no hierarchical ref needed
);
    reg [31:0] regs [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'd0;
    end

    always @(posedge clk) begin
        if (we && rd != 5'd0)
            regs[rd] <= wd;
    end

    assign rd1     = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign rd2     = (rs2 == 5'd0) ? 32'd0 : regs[rs2];
    assign dbg_x10 = regs[10];
endmodule