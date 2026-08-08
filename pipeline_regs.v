
// FILE: pipeline_regs.v  (MODIFIED)
// DESC: Pipeline registers. ID/EX adds predict_taken signal.
//       IF/ID, EX/MEM, MEM/WB identical to baseline.
// =============================================================================
module if_id_reg (
    input  wire        clk, rst, stall, flush,
    input  wire [31:0] if_pc, if_instr,
    output reg  [31:0] id_pc, id_instr
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            id_pc <= 32'd0; id_instr <= 32'h00000013;
        end else if (!stall) begin
            id_pc <= if_pc; id_instr <= if_instr;
        end
    end
endmodule

module id_ex_reg (
    input  wire        clk, rst, flush,
    input  wire        id_reg_write, id_alu_src, id_mem_write, id_mem_read,
    input  wire        id_mem_to_reg, id_branch, id_branch_ne,
    input  wire [3:0]  id_alu_op,
    input  wire        id_predict_taken,
    input  wire [31:0] id_pc, id_rd1, id_rd2, id_imm,
    input  wire [4:0]  id_rs1, id_rs2, id_rd,
    output reg         ex_reg_write, ex_alu_src, ex_mem_write, ex_mem_read,
    output reg         ex_mem_to_reg, ex_branch, ex_branch_ne,
    output reg  [3:0]  ex_alu_op,
    output reg         ex_predict_taken,
    output reg  [31:0] ex_pc, ex_rd1, ex_rd2, ex_imm,
    output reg  [4:0]  ex_rs1, ex_rs2, ex_rd
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            ex_reg_write<=0; ex_alu_src<=0; ex_mem_write<=0; ex_mem_read<=0;
            ex_mem_to_reg<=0; ex_branch<=0; ex_branch_ne<=0; ex_alu_op<=0;
            ex_predict_taken<=0;
            ex_pc<=0; ex_rd1<=0; ex_rd2<=0; ex_imm<=0;
            ex_rs1<=0; ex_rs2<=0; ex_rd<=0;
        end else begin
            ex_reg_write<=id_reg_write; ex_alu_src<=id_alu_src;
            ex_mem_write<=id_mem_write; ex_mem_read<=id_mem_read;
            ex_mem_to_reg<=id_mem_to_reg; ex_branch<=id_branch;
            ex_branch_ne<=id_branch_ne; ex_alu_op<=id_alu_op;
            ex_predict_taken<=id_predict_taken;
            ex_pc<=id_pc; ex_rd1<=id_rd1; ex_rd2<=id_rd2; ex_imm<=id_imm;
            ex_rs1<=id_rs1; ex_rs2<=id_rs2; ex_rd<=id_rd;
        end
    end
endmodule

module ex_mem_reg (
    input  wire        clk, rst, flush,
    input  wire        ex_reg_write, ex_mem_write, ex_mem_read, ex_mem_to_reg,
    input  wire [31:0] ex_alu_result, ex_wd,
    input  wire [4:0]  ex_rd,
    input  wire        ex_zero,
    output reg         mem_reg_write, mem_mem_write, mem_mem_read, mem_mem_to_reg,
    output reg  [31:0] mem_alu_result, mem_wd,
    output reg  [4:0]  mem_rd,
    output reg         mem_zero
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            mem_reg_write<=0; mem_mem_write<=0; mem_mem_read<=0; mem_mem_to_reg<=0;
            mem_alu_result<=0; mem_wd<=0; mem_rd<=0; mem_zero<=0;
        end else begin
            mem_reg_write<=ex_reg_write; mem_mem_write<=ex_mem_write;
            mem_mem_read<=ex_mem_read; mem_mem_to_reg<=ex_mem_to_reg;
            mem_alu_result<=ex_alu_result; mem_wd<=ex_wd;
            mem_rd<=ex_rd; mem_zero<=ex_zero;
        end
    end
endmodule

module mem_wb_reg (
    input  wire        clk, rst,
    input  wire        mem_reg_write, mem_mem_to_reg,
    input  wire [31:0] mem_read_data, mem_alu_result,
    input  wire [4:0]  mem_rd,
    output reg         wb_reg_write, wb_mem_to_reg,
    output reg  [31:0] wb_read_data, wb_alu_result,
    output reg  [4:0]  wb_rd
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_reg_write<=0; wb_mem_to_reg<=0;
            wb_read_data<=0; wb_alu_result<=0; wb_rd<=0;
        end else begin
            wb_reg_write<=mem_reg_write; wb_mem_to_reg<=mem_mem_to_reg;
            wb_read_data<=mem_read_data; wb_alu_result<=mem_alu_result;
            wb_rd<=mem_rd;
        end
    end
endmodule