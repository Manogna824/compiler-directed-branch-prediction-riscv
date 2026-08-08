
// TESTBENCH - BASELINE
//==============================================================================
module tb_baseline;
 
    // ── signals ──────────────────────────────────────────────────────────────
    reg         clk;
    reg         rst;
    wire [31:0] total_cycles;
    wire [31:0] total_instrs;
    wire [31:0] total_mispred;
    wire [31:0] debug_pc;
    wire [31:0] debug_reg_x10;
 
    // ── DUT ──────────────────────────────────────────────────────────────────
    datapath dut (
        .clk           (clk),
        .rst           (rst),
        .total_cycles  (total_cycles),
        .total_instrs  (total_instrs),
        .total_mispred (total_mispred),
        .debug_pc      (debug_pc),
        .debug_reg_x10 (debug_reg_x10)
    );
 
    // ── CLOCK ─────────────────────────────────────────────────────────────────
    // Start HIGH so that posedge fires at t=0 - no race with initial block.
    // First negedge at t=5ns, second posedge at t=10ns, etc.
    initial clk = 1'b1;
    always  #5  clk = ~clk;
 
    // ── RESET - pure time-delay, never waits on posedge ──────────────────────
    initial begin
        rst = 1'b1;          // assert reset at t=0
        #100;                // hold for 100 ns  (10 clock cycles)
        rst = 1'b0;          // release reset - pipeline starts here
    end
 
    // ── SNAPSHOT printer every 500 cycles ────────────────────────────────────
    // Uses its own always block - safe, never blocked by rst.
    integer cyc_b;
    initial  cyc_b = 0;
    always @(posedge clk) begin
        cyc_b = cyc_b + 1;
        if (cyc_b % 500 == 0) begin
             $display("[BL] clk=%0d  cycles=%0d  instrs=%0d  mispred=%0d  pc=%08X  x10=%0d\n",
                   cyc_b, total_cycles, total_instrs, total_mispred,
                   debug_pc, debug_reg_x10);
           
        end
    end
 
    // ── MAIN CONTROL ──────────────────────────────────────────────────────────
    initial begin
        $display("[BASELINE] t=0: clk=1, rst=1\n");
 
        // Wait for reset to release (100ns) + small margin
        #105;
       $display("[BASELINE] rst released at t=%0t. Running 5000 cycles...\n", $time);
        $fflush();
 
        // Run exactly 5000 clock cycles = 50000 ns
        #50000;
 
        // ── Print results ──
         $display("\n=============================================\n");
         $display("[BASELINE] SIMULATION DONE\n");                      
         $display("  Total Cycles  = %0d\n",   total_cycles);           
        $display("  Total Instrs  = %0d\n",   total_instrs);           
         $display("  Total Mispred = %0d\n",   total_mispred);         
         $display("  Final PC      = 0x%08X\n",debug_pc);              
         $display("  x10 result    = %0d\n",   debug_reg_x10);         
        if (total_cycles > 0) begin
             $display("  IPC           = %0.4f\n",
                   $itor(total_instrs)/$itor(total_cycles));        
        end
        if (total_instrs > 0) begin
             $display("  Mispred Rate  = %0.2f%%\n",
                   100.0*$itor(total_mispred)/$itor(total_instrs));  
        end
        $write("=============================================\n");    $fflush();
 
        $finish(2);   // (2) = print XSim resource stats, forces buffer flush
    end
 
endmodule