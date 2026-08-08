// =============================================================================
// FILE: pipeline_regs.v  (BASELINE)
// DESC: All four pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB
//       Each has flush and stall control inputs.
// =============================================================================

// -----------------------------------------------------------------------
// IF/ID Pipeline Register
// -----------------------------------------------------------------------
module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        flush,
    input  wire [31:0] if_pc,
    input  wire [31:0] if_instr,
    output reg  [31:0] id_pc,
    output reg  [31:0] id_instr
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            id_pc    <= 32'd0;
            id_instr <= 32'h00000013; // NOP
        end else if (!stall) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
        end
    end
endmodule

// -----------------------------------------------------------------------
// ID/EX Pipeline Register
// -----------------------------------------------------------------------
module id_ex_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    // Control signals
    input  wire        id_reg_write,
    input  wire        id_alu_src,
    input  wire        id_mem_write,
    input  wire        id_mem_read,
    input  wire        id_mem_to_reg,
    input  wire        id_branch,
    input  wire        id_branch_ne,
    input  wire [3:0]  id_alu_op,
    // Data
    input  wire [31:0] id_pc,
    input  wire [31:0] id_rd1,
    input  wire [31:0] id_rd2,
    input  wire [31:0] id_imm,
    input  wire [4:0]  id_rs1,
    input  wire [4:0]  id_rs2,
    input  wire [4:0]  id_rd,
    // Outputs
    output reg         ex_reg_write,
    output reg         ex_alu_src,
    output reg         ex_mem_write,
    output reg         ex_mem_read,
    output reg         ex_mem_to_reg,
    output reg         ex_branch,
    output reg         ex_branch_ne,
    output reg  [3:0]  ex_alu_op,
    output reg  [31:0] ex_pc,
    output reg  [31:0] ex_rd1,
    output reg  [31:0] ex_rd2,
    output reg  [31:0] ex_imm,
    output reg  [4:0]  ex_rs1,
    output reg  [4:0]  ex_rs2,
    output reg  [4:0]  ex_rd
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            ex_reg_write  <= 1'b0;
            ex_alu_src    <= 1'b0;
            ex_mem_write  <= 1'b0;
            ex_mem_read   <= 1'b0;
            ex_mem_to_reg <= 1'b0;
            ex_branch     <= 1'b0;
            ex_branch_ne  <= 1'b0;
            ex_alu_op     <= 4'd0;
            ex_pc         <= 32'd0;
            ex_rd1        <= 32'd0;
            ex_rd2        <= 32'd0;
            ex_imm        <= 32'd0;
            ex_rs1        <= 5'd0;
            ex_rs2        <= 5'd0;
            ex_rd         <= 5'd0;
        end else begin
            ex_reg_write  <= id_reg_write;
            ex_alu_src    <= id_alu_src;
            ex_mem_write  <= id_mem_write;
            ex_mem_read   <= id_mem_read;
            ex_mem_to_reg <= id_mem_to_reg;
            ex_branch     <= id_branch;
            ex_branch_ne  <= id_branch_ne;
            ex_alu_op     <= id_alu_op;
            ex_pc         <= id_pc;
            ex_rd1        <= id_rd1;
            ex_rd2        <= id_rd2;
            ex_imm        <= id_imm;
            ex_rs1        <= id_rs1;
            ex_rs2        <= id_rs2;
            ex_rd         <= id_rd;
        end
    end
endmodule

// -----------------------------------------------------------------------
// EX/MEM Pipeline Register
// -----------------------------------------------------------------------
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    // Control
    input  wire        ex_reg_write,
    input  wire        ex_mem_write,
    input  wire        ex_mem_read,
    input  wire        ex_mem_to_reg,
    // Data
    input  wire [31:0] ex_alu_result,
    input  wire [31:0] ex_wd,          // store data
    input  wire [4:0]  ex_rd,
    input  wire        ex_zero,
    // Outputs
    output reg         mem_reg_write,
    output reg         mem_mem_write,
    output reg         mem_mem_read,
    output reg         mem_mem_to_reg,
    output reg  [31:0] mem_alu_result,
    output reg  [31:0] mem_wd,
    output reg  [4:0]  mem_rd,
    output reg         mem_zero
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            mem_reg_write  <= 1'b0;
            mem_mem_write  <= 1'b0;
            mem_mem_read   <= 1'b0;
            mem_mem_to_reg <= 1'b0;
            mem_alu_result <= 32'd0;
            mem_wd         <= 32'd0;
            mem_rd         <= 5'd0;
            mem_zero       <= 1'b0;
        end else begin
            mem_reg_write  <= ex_reg_write;
            mem_mem_write  <= ex_mem_write;
            mem_mem_read   <= ex_mem_read;
            mem_mem_to_reg <= ex_mem_to_reg;
            mem_alu_result <= ex_alu_result;
            mem_wd         <= ex_wd;
            mem_rd         <= ex_rd;
            mem_zero       <= ex_zero;
        end
    end
endmodule

// -----------------------------------------------------------------------
// MEM/WB Pipeline Register
// -----------------------------------------------------------------------
module mem_wb_reg (
    input  wire        clk,
    input  wire        rst,
    // Control
    input  wire        mem_reg_write,
    input  wire        mem_mem_to_reg,
    // Data
    input  wire [31:0] mem_read_data,
    input  wire [31:0] mem_alu_result,
    input  wire [4:0]  mem_rd,
    // Outputs
    output reg         wb_reg_write,
    output reg         wb_mem_to_reg,
    output reg  [31:0] wb_read_data,
    output reg  [31:0] wb_alu_result,
    output reg  [4:0]  wb_rd
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_reg_write  <= 1'b0;
            wb_mem_to_reg <= 1'b0;
            wb_read_data  <= 32'd0;
            wb_alu_result <= 32'd0;
            wb_rd         <= 5'd0;
        end else begin
            wb_reg_write  <= mem_reg_write;
            wb_mem_to_reg <= mem_mem_to_reg;
            wb_read_data  <= mem_read_data;
            wb_alu_result <= mem_alu_result;
            wb_rd         <= mem_rd;
        end
    end
endmodule