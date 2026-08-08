// =============================================================================
// FILE: branch_unit.v  (MODIFIED)
// DESC: HINT-BIT STATIC BRANCH PREDICTION unit.
//
// PREDICTION LOGIC:
//   At ID stage: if (branch|branch_ne) && hint_bit → predict TAKEN
//                                       else → predict NOT TAKEN
//
// AT EX STAGE (this module):
//   Compute actual outcome. Compare with what was predicted.
//   → If mismatch: flush IF and ID (2-cycle penalty), redirect PC.
//
// CASES:
//   Predicted TAKEN  + Actually TAKEN   → no flush, no redirect needed
//   Predicted TAKEN  + Actually NOT TAKEN → FLUSH + redirect to PC+4
//   Predicted NOT TAKEN + Actually TAKEN  → FLUSH + redirect to target
//   Predicted NOT TAKEN + Actually NOT TAKEN → no flush
//
// Note: When predicted TAKEN, the IF stage already fetched branch_target.
//       So the "seq_pc" (PC after branch inst) must be saved in pipeline.
// =============================================================================
module branch_unit (
    input  wire [31:0] ex_pc,
    input  wire [31:0] ex_imm,
    input  wire        ex_branch,
    input  wire        ex_branch_ne,
    input  wire        ex_zero,
    input  wire        ex_predict_taken,  // NEW: hint from decode stage
    // Outputs
    output wire        branch_actual_taken,
    output wire        flush_pipeline,    // flush due to misprediction
    output wire [31:0] correct_pc,        // PC to redirect to on misprediction
    output wire        mispredicted       // performance counter pulse
);
    // Actual branch outcome
    assign branch_actual_taken = (ex_branch & ex_zero) | (ex_branch_ne & ~ex_zero);

    // Is this instruction a branch at all?
    wire is_branch = ex_branch | ex_branch_ne;

    // Branch target and fall-through
    wire [31:0] branch_target  = ex_pc + ex_imm;
    wire [31:0] fall_through   = ex_pc + 32'd4; // next sequential instruction

    // Misprediction: prediction != actual
    assign mispredicted = is_branch & (ex_predict_taken ^ branch_actual_taken);

    // Flush if mispredicted
    assign flush_pipeline = mispredicted;

    // Correct PC:
    //   If predicted TAKEN but not taken → go to fall-through
    //   If predicted NOT TAKEN but taken → go to target
    assign correct_pc = branch_actual_taken ? branch_target : fall_through;

endmodule