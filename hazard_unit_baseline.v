// =============================================================================
// FILE: hazard_unit.v  (BASELINE)
// DESC: Detects load-use hazards and generates stall/flush signals.
//
// STALL condition: EX stage has a load (mem_read=1) and its rd matches
//                 the rs1 or rs2 of the instruction in ID stage.
//
// FLUSH on branch: Handled by datapath/top when branch_taken is asserted.
// =============================================================================
module hazard_unit (
    input  wire        ex_mem_read,     // load in EX?
    input  wire [4:0]  ex_rd,           // destination of EX inst
    input  wire [4:0]  id_rs1,          // source1 of ID inst
    input  wire [4:0]  id_rs2,          // source2 of ID inst
    output wire        stall,           // stall IF and ID, insert bubble in EX
    output wire        if_id_stall,     // hold IF/ID reg
    output wire        pc_stall         // hold PC
);
    wire load_use_hazard;

    assign load_use_hazard = ex_mem_read &&
                             ((ex_rd == id_rs1) || (ex_rd == id_rs2)) &&
                             (ex_rd != 5'd0);

    assign stall        = load_use_hazard;
    assign if_id_stall  = load_use_hazard;
    assign pc_stall     = load_use_hazard;
endmodule