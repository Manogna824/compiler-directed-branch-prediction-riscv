// =============================================================================
// FILE: top_baseline.v  (BASELINE)
// DESC: Top-level module for BASELINE predict-not-taken RISC-V pipeline.
//       Wraps datapath. Exposes performance counters and debug outputs.
//       Compatible with Zybo Z7-10 FPGA.
//
// CLOCK: 125 MHz input from Zybo XTAL → divided to 25 MHz for pipeline.
// RESET: Active-HIGH, connected to BTN0 on Zybo.
// =============================================================================
module top_baseline (
    input  wire        clk_125mhz,    // 125 MHz system clock (Zybo oscillator)
    input  wire        rst_btn,       // BTN0 = reset (active high)
    // LEDs for debug output (lower 4 bits of total_mispred)
    output wire [3:0]  led,
    // UART-like serial output not included; use ILA or simulation instead
    // Expose perf counters to ILA / chipscope
    output wire [31:0] total_cycles,
    output wire [31:0] total_instrs,
    output wire [31:0] total_mispred
);
    // ---- Clock divider: 125MHz → ~25MHz ----
    reg [2:0] clk_div;
    reg       clk_25mhz;

    always @(posedge clk_125mhz or posedge rst_btn) begin
        if (rst_btn) begin
            clk_div   <= 3'd0;
            clk_25mhz <= 1'b0;
        end else begin
            if (clk_div == 3'd4) begin
                clk_div   <= 3'd0;
                clk_25mhz <= ~clk_25mhz;
            end else
                clk_div <= clk_div + 3'd1;
        end
    end

    wire [31:0] debug_pc;
    wire [31:0] debug_reg_x10;

    datapath u_datapath (
        .clk           (clk_25mhz),
        .rst           (rst_btn),
        .total_cycles  (total_cycles),
        .total_instrs  (total_instrs),
        .total_mispred (total_mispred),
        .debug_pc      (debug_pc),
        .debug_reg_x10 (debug_reg_x10)
    );

    // Lower 4 bits of misprediction counter → LEDs
    assign led = total_mispred[3:0];

endmodule