// =============================================================================
// FILE: alu.v  (BASELINE + MODIFIED - shared)
// FIX: Added SLLI (4'd6) and SRLI (4'd7) which were missing
//      and caused slli x7,x6,2 to produce 0 → wrong addresses → wrong stores
// =============================================================================
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);
    always @(*) begin
        case (alu_ctrl)
            4'd0: result = a + b;
            4'd1: result = a - b;
            4'd2: result = a & b;
            4'd3: result = a | b;
            4'd4: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'd5: result = a ^ b;
            4'd6: result = a << b[4:0];   // SLLI
            4'd7: result = a >> b[4:0];   // SRLI
            default: result = 32'd0;
        endcase
    end
    assign zero = (result == 32'd0);
endmodule