// =============================================================================
// FILE: branch_unit.v  (BASELINE)
// DESC: PREDICT-NOT-TAKEN branch unit.
//       Branch outcome resolved in EX stage.
//       If branch is actually TAKEN → flush IF and ID (2-cycle penalty).
//
// branch_taken logic:
//   BEQ: branch_taken = branch    & zero
//   BNE: branch_taken = branch_ne & ~zero
// =============================================================================
module branch_unit (
    input  wire [31:0] ex_pc,
    input  wire [31:0] ex_imm,
    input  wire        ex_branch,
    input  wire        ex_branch_ne,
    input  wire        ex_zero,
    // Outputs
    output wire        branch_taken,
    output wire [31:0] branch_target,
    // Performance counter output
    output wire        mispredicted  // always 1 when branch_taken (PNT policy)
);
    assign branch_taken  = (ex_branch & ex_zero) | (ex_branch_ne & ~ex_zero);
    assign branch_target = ex_pc + ex_imm;
    assign mispredicted  = branch_taken; // PNT: taken = misprediction
endmodule