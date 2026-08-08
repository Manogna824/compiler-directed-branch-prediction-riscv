// =============================================================================
// FILE: alu.v  (BASELINE)
// DESC: Arithmetic Logic Unit for RISC-V subset
// OPS : ADD, SUB, AND, OR, SLT, XOR  (selected via alu_ctrl)
// =============================================================================
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,  // 0=ADD,1=SUB,2=AND,3=OR,4=SLT,5=XOR
    output reg  [31:0] result,
    output wire        zero
);
    always @(*) begin
        case (alu_ctrl)
            4'd0: result = a + b;                          // ADD
            4'd1: result = a - b;                          // SUB
            4'd2: result = a & b;                          // AND
            4'd3: result = a | b;                          // OR
            4'd4: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'd5: result = a ^ b;                          // XOR
            default: result = 32'd0;
        endcase
    end
    assign zero = (result == 32'd0);
endmodule