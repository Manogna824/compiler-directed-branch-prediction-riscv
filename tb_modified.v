`timescale 1ns / 1ps
// TESTBENCH - MODIFIED
//==============================================================================
module tb_modified;
 
    reg         clk;
    reg         rst;
    wire [31:0] total_cycles;
    wire [31:0] total_instrs;
    wire [31:0] total_mispred;
    wire [31:0] debug_pc;
    wire [31:0] debug_reg_x10;
 
    datapath dut (
        .clk           (clk),
        .rst           (rst),
        .total_cycles  (total_cycles),
        .total_instrs  (total_instrs),
        .total_mispred (total_mispred),
        .debug_pc      (debug_pc),
        .debug_reg_x10 (debug_reg_x10)
    );
 
    initial clk = 1'b1;
    always  #5  clk = ~clk;
 
    initial begin
        rst = 1'b1;
        #100;
        rst = 1'b0;
    end
 
    integer cyc_m;
    initial  cyc_m = 0;
    always @(posedge clk) begin
        cyc_m = cyc_m + 1;
        if (cyc_m % 500 == 0) begin
            $write("[MD] clk=%0d  cycles=%0d  instrs=%0d  mispred=%0d  pc=%08X  x10=%0d\n",
                   cyc_m, total_cycles, total_instrs, total_mispred,
                   debug_pc, debug_reg_x10);
            $fflush();
        end
    end
 
    initial begin
        $write("[MODIFIED] t=0: clk=1, rst=1\n"); $fflush();
 
        #105;
        $write("[MODIFIED] rst released at t=%0t. Running 5000 cycles...\n", $time);
        $fflush();
 
        #50000;
 
        $write("\n=============================================\n"); $fflush();
        $write("[MODIFIED] SIMULATION DONE\n");                      $fflush();
        $write("  Total Cycles  = %0d\n",   total_cycles);           $fflush();
        $write("  Total Instrs  = %0d\n",   total_instrs);           $fflush();
        $write("  Total Mispred = %0d\n",   total_mispred);          $fflush();
        $write("  Final PC      = 0x%08X\n",debug_pc);               $fflush();
        $write("  x10 result    = %0d\n",   debug_reg_x10);          $fflush();
        if (total_cycles > 0) begin
            $write("  IPC           = %0.4f\n",
                   $itor(total_instrs)/$itor(total_cycles));          $fflush();
        end
        if (total_instrs > 0) begin
            $write("  Mispred Rate  = %0.2f%%\n",
                   100.0*$itor(total_mispred)/$itor(total_instrs));   $fflush();
        end
        $write("=============================================\n");    $fflush();
 
        $finish(2);
    end
 
endmodule