// =============================================================================
// FILE: control_unit.v  (BASELINE)
// FIXES:
//   1. Added handling for BEQ x0,x0,0 halt (opcode=1100011, funct3=000)
//   2. branch signal correctly set for funct3=000 (BEQ)
//   3. branch_ne correctly set for funct3=001 (BNE)
// =============================================================================
module control_unit (
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    output reg         reg_write,
    output reg         alu_src,
    output reg         mem_write,
    output reg         mem_read,
    output reg         mem_to_reg,
    output reg         branch,
    output reg         branch_ne,
    output reg  [3:0]  alu_op
);
    always @(*) begin
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_write  = 1'b0;
        mem_read   = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        branch_ne  = 1'b0;
        alu_op     = 4'd0;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                case ({funct7[5], funct3})
                    4'b0000: alu_op = 4'd0; // ADD
                    4'b1000: alu_op = 4'd1; // SUB
                    4'b0111: alu_op = 4'd2; // AND
                    4'b0110: alu_op = 4'd3; // OR
                    4'b0010: alu_op = 4'd4; // SLT
                    4'b0100: alu_op = 4'd5; // XOR
                    default: alu_op = 4'd0;
                endcase
            end
            7'b0010011: begin // I-type ALU
                reg_write = 1'b1;
                alu_src   = 1'b1;
                case (funct3)
                    3'b000: alu_op = 4'd0; // ADDI
                    3'b111: alu_op = 4'd2; // ANDI
                    3'b110: alu_op = 4'd3; // ORI
                    3'b001: alu_op = 4'd6; // SLLI
                    3'b101: alu_op = 4'd7; // SRLI
                    default: alu_op = 4'd0;
                endcase
            end
            7'b0000011: begin // LW
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 4'd0;
            end
            7'b0100011: begin // SW
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 4'd0;
            end
            7'b1100011: begin // BEQ / BNE
                alu_op    = 4'd1; // SUB for comparison
                // funct3=000: BEQ, funct3=001: BNE
                branch    = (funct3 == 3'b000) ? 1'b1 : 1'b0;
                branch_ne = (funct3 == 3'b001) ? 1'b1 : 1'b0;
            end
            default: begin end
        endcase
    end
endmodule