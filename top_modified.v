
// FILE: top_modified.v  (FINAL WITH ILA)
// =============================================================================
`timescale 1ns / 1ps
module top_modified (
    input  wire clk_125mhz,
    input  wire rst_btn,
    output wire [3:0] led
);

    // ============================================================
    // MARK DEBUG SIGNALS (IMPORTANT FOR ILA)
    // ============================================================
    (* mark_debug = "true" *) wire [31:0] total_cycles;
    (* mark_debug = "true" *) wire [31:0] total_instrs;
    (* mark_debug = "true" *) wire [31:0] total_mispred;
    (* mark_debug = "true" *) wire [31:0] debug_pc;
    (* mark_debug = "true" *) wire [31:0] debug_reg_x10;

    // ============================================================
    // CPU INSTANCE
    // ============================================================
    datapath u_datapath (
        .clk           (clk_125mhz),
        .rst           (1'b0),   // 🔥 disable reset for stable debug
        .total_cycles  (total_cycles),
        .total_instrs  (total_instrs),
        .total_mispred (total_mispred),
        .debug_pc      (debug_pc),
        .debug_reg_x10 (debug_reg_x10)
    );

    // ============================================================
    // SLOW COUNTER (FOR HUMAN-VISIBLE LEDS)
    // ============================================================
    reg [26:0] slow_counter;

    always @(posedge clk_125mhz) begin
        slow_counter <= slow_counter + 1;
    end

    // ============================================================
    // LED OUTPUT (VISIBLE DEBUG)
    // ============================================================
    assign led[0] = slow_counter[26];      // heartbeat
    assign led[1] = total_cycles[22];      // cycles activity
    assign led[2] = total_instrs[10];      // instructions
    assign led[3] = total_mispred[0];      // misprediction

    // ============================================================
    // ILA INSTANCE
    // ============================================================
    ila_0 u_ila (
        .clk(clk_125mhz),
        .probe0(total_cycles),
        .probe1(total_instrs),
        .probe2(total_mispred),
        .probe3(debug_pc)
    );

endmodule