// FILE: perf_counters.v  (MODIFIED)
module perf_counters (
    input  wire        clk,
    input  wire        rst,
    input  wire        instr_retired,
    input  wire        mispredicted,
    output reg  [31:0] total_cycles,
    output reg  [31:0] total_instrs,
    output reg  [31:0] total_mispred
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            total_cycles  <= 32'd0;
            total_instrs  <= 32'd0;
            total_mispred <= 32'd0;
        end else begin
            total_cycles  <= total_cycles + 32'd1;
            if (instr_retired) total_instrs  <= total_instrs  + 32'd1;
            if (mispredicted)  total_mispred <= total_mispred + 32'd1;
        end
    end
endmodule