module datapath (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] total_cycles,
    output wire [31:0] total_instrs,
    output wire [31:0] total_mispred,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_reg_x10
);

    // ================= IF =================
    reg  [31:0] pc_reg;
    wire [31:0] if_instr;
    wire [31:0] if_pc = pc_reg;

    // ================= IF/ID =================
    wire [31:0] id_pc, id_instr;

    // ================= ID =================
    wire [6:0] id_opcode = id_instr[6:0];
    wire [4:0] id_rd_f   = id_instr[11:7];
    wire [2:0] id_funct3 = id_instr[14:12];
    wire [4:0] id_rs1    = id_instr[19:15];
    wire [4:0] id_rs2    = id_instr[24:20];
    wire [6:0] id_funct7 = id_instr[31:25];
    wire       hint_bit  = id_instr[27];

    wire id_reg_write, id_alu_src, id_mem_write, id_mem_read;
    wire id_mem_to_reg, id_branch, id_branch_ne;
    wire [3:0] id_alu_op;
    wire id_predict_taken;
    wire [31:0] id_rd1, id_rd2, id_imm;

    // ================= ID/EX =================
    wire ex_reg_write, ex_alu_src, ex_mem_write, ex_mem_read;
    wire ex_mem_to_reg, ex_branch, ex_branch_ne;
    wire [3:0] ex_alu_op;
    wire ex_predict_taken;
    wire [31:0] ex_pc, ex_rd1, ex_rd2, ex_imm;
    wire [4:0] ex_rs1, ex_rs2, ex_rd;

    // ================= EX =================
    wire [1:0] fwd_a, fwd_b;
    wire [31:0] ex_fwd_a, ex_fwd_b, ex_alu_b;
    wire [31:0] ex_alu_result;
    wire ex_zero;

    wire branch_actual_taken;
    wire flush_pipeline;
    wire [31:0] correct_pc;
    wire mispredicted;

    // ================= MEM =================
    wire mem_reg_write, mem_mem_write, mem_mem_read, mem_mem_to_reg;
    wire [31:0] mem_alu_result, mem_wd;
    wire [4:0] mem_rd;

    wire [31:0] mem_read_data;

    // ================= WB =================
    wire wb_reg_write, wb_mem_to_reg;
    wire [31:0] wb_read_data, wb_alu_result;
    wire [4:0] wb_rd;
    wire [31:0] wb_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;
    wire [31:0] dbg_x10_wire;

    // ================= HAZARD =================
    wire stall, if_id_stall, pc_stall;

    // ================= PC LOGIC =================
    wire id_is_branch = id_branch | id_branch_ne;
    wire [31:0] id_branch_target = id_pc + id_imm;

    wire [31:0] pc_next =
        flush_pipeline ? correct_pc :
        pc_stall       ? pc_reg :
        (id_is_branch && id_predict_taken) ? id_branch_target :
        pc_reg + 32'd4;

    // ✅ FIXED FLUSH LOGIC
    wire flush_ifid = flush_pipeline;
    wire flush_idex = flush_pipeline | stall;

    always @(posedge clk or posedge rst) begin
        if (rst) pc_reg <= 32'd0;
        else     pc_reg <= pc_next;
    end

    assign debug_pc = pc_reg;

    // ================= IMEM =================
    instr_mem u_imem (.addr(if_pc), .instr(if_instr));

    // ================= IF/ID =================
    if_id_reg u_if_id (
        .clk(clk), .rst(rst), .stall(if_id_stall), .flush(flush_ifid),
        .if_pc(if_pc), .if_instr(if_instr),
        .id_pc(id_pc), .id_instr(id_instr)
    );

    // ================= CONTROL =================
    control_unit u_ctrl (
        .opcode(id_opcode), .funct3(id_funct3), .funct7(id_funct7),
        .hint_bit(hint_bit),
        .reg_write(id_reg_write), .alu_src(id_alu_src),
        .mem_write(id_mem_write), .mem_read(id_mem_read),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch), .branch_ne(id_branch_ne),
        .alu_op(id_alu_op),
        .predict_taken(id_predict_taken)
    );

    // ================= REG FILE =================
    register_file u_rf (
        .clk(clk), .we(wb_reg_write),
        .rs1(id_rs1), .rs2(id_rs2),
        .rd(wb_rd), .wd(wb_data),
        .rd1(id_rd1), .rd2(id_rd2),
        .dbg_x10(dbg_x10_wire)
    );

    assign debug_reg_x10 = dbg_x10_wire;

    // ================= IMM =================
    imm_gen u_immgen (.instr(id_instr), .imm(id_imm));

    // ================= HAZARD =================
    hazard_unit u_hazard (
        .ex_mem_read(ex_mem_read), .ex_rd(ex_rd),
        .id_rs1(id_rs1), .id_rs2(id_rs2),
        .stall(stall), .if_id_stall(if_id_stall), .pc_stall(pc_stall)
    );

    // ================= ID/EX =================
    id_ex_reg u_id_ex (
        .clk(clk), .rst(rst), .flush(flush_idex),
        .id_reg_write(id_reg_write), .id_alu_src(id_alu_src),
        .id_mem_write(id_mem_write), .id_mem_read(id_mem_read),
        .id_mem_to_reg(id_mem_to_reg),
        .id_branch(id_branch), .id_branch_ne(id_branch_ne),
        .id_alu_op(id_alu_op),
        .id_predict_taken(id_predict_taken),
        .id_pc(id_pc), .id_rd1(id_rd1), .id_rd2(id_rd2), .id_imm(id_imm),
        .id_rs1(id_rs1), .id_rs2(id_rs2), .id_rd(id_rd_f),
        .ex_reg_write(ex_reg_write), .ex_alu_src(ex_alu_src),
        .ex_mem_write(ex_mem_write), .ex_mem_read(ex_mem_read),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_branch(ex_branch), .ex_branch_ne(ex_branch_ne),
        .ex_alu_op(ex_alu_op),
        .ex_predict_taken(ex_predict_taken),
        .ex_pc(ex_pc), .ex_rd1(ex_rd1), .ex_rd2(ex_rd2), .ex_imm(ex_imm),
        .ex_rs1(ex_rs1), .ex_rs2(ex_rs2), .ex_rd(ex_rd)
    );

    // ================= FORWARD =================
    forwarding_unit u_fwd (
        .ex_rs1(ex_rs1), .ex_rs2(ex_rs2),
        .mem_rd(mem_rd), .mem_reg_write(mem_reg_write),
        .wb_rd(wb_rd), .wb_reg_write(wb_reg_write),
        .fwd_a(fwd_a), .fwd_b(fwd_b)
    );

    assign ex_fwd_a = (fwd_a==2'b10) ? mem_alu_result :
                      (fwd_a==2'b01) ? wb_data : ex_rd1;

    assign ex_fwd_b = (fwd_b==2'b10) ? mem_alu_result :
                      (fwd_b==2'b01) ? wb_data : ex_rd2;

    assign ex_alu_b = ex_alu_src ? ex_imm : ex_fwd_b;

    // ================= ALU =================
    alu u_alu (
        .a(ex_fwd_a), .b(ex_alu_b),
        .alu_ctrl(ex_alu_op),
        .result(ex_alu_result), .zero(ex_zero)
    );

    // ================= BRANCH =================
    branch_unit u_branch (
        .ex_pc(ex_pc), .ex_imm(ex_imm),
        .ex_branch(ex_branch), .ex_branch_ne(ex_branch_ne),
        .ex_zero(ex_zero),
        .ex_predict_taken(ex_predict_taken),
        .branch_actual_taken(branch_actual_taken),
        .flush_pipeline(flush_pipeline),
        .correct_pc(correct_pc),
        .mispredicted(mispredicted)
    );

    // ================= EX/MEM =================
    ex_mem_reg u_ex_mem (
        .clk(clk), .rst(rst), .flush(1'b0),
        .ex_reg_write(ex_reg_write), .ex_mem_write(ex_mem_write),
        .ex_mem_read(ex_mem_read), .ex_mem_to_reg(ex_mem_to_reg),
        .ex_alu_result(ex_alu_result), .ex_wd(ex_fwd_b),
        .ex_rd(ex_rd),
        .mem_reg_write(mem_reg_write), .mem_mem_write(mem_mem_write),
        .mem_mem_read(mem_mem_read), .mem_mem_to_reg(mem_mem_to_reg),
        .mem_alu_result(mem_alu_result), .mem_wd(mem_wd),
        .mem_rd(mem_rd)
    );

    // ================= DATA MEM =================
    data_mem u_dmem (
        .clk(clk), .we(mem_mem_write),
        .addr(mem_alu_result), .wd(mem_wd), .rd(mem_read_data)
    );

    // ================= MEM/WB =================
    mem_wb_reg u_mem_wb (
        .clk(clk), .rst(rst),
        .mem_reg_write(mem_reg_write), .mem_mem_to_reg(mem_mem_to_reg),
        .mem_read_data(mem_read_data), .mem_alu_result(mem_alu_result),
        .mem_rd(mem_rd),
        .wb_reg_write(wb_reg_write), .wb_mem_to_reg(wb_mem_to_reg),
        .wb_read_data(wb_read_data), .wb_alu_result(wb_alu_result),
        .wb_rd(wb_rd)
    );

    // ================= PERF =================
    wire instr_retired = wb_reg_write | mem_mem_write;

    perf_counters u_perf (
        .clk(clk), .rst(rst),
        .instr_retired(instr_retired),
        .mispredicted(mispredicted),
        .total_cycles(total_cycles),
        .total_instrs(total_instrs),
        .total_mispred(total_mispred)
    );

endmodule