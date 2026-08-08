// =============================================================================
// FILE: data_mem.v  (BASELINE)
// DESC: Data memory 256 words (1 KB), byte-addressed, word-aligned access.
//       Synchronous write, asynchronous read.
// =============================================================================
module data_mem (
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wd,
    output wire [31:0] rd
);
    reg [31:0] mem [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'd0;

        // Pre-init data for strlen test (ASCII "HELLO" = 72,69,76,76,79,0)
        // Stored word-by-word for simplicity (each byte in a word)
        mem[64] = 32'h48; // 'H'
        mem[65] = 32'h45; // 'E'
        mem[66] = 32'h4C; // 'L'
        mem[67] = 32'h4C; // 'L'
        mem[68] = 32'h4F; // 'O'
        mem[69] = 32'h00; // null terminator

        // Pre-init data for selection sort (8 elements at offset 128)
        mem[128] = 32'd64;
        mem[129] = 32'd25;
        mem[130] = 32'd12;
        mem[131] = 32'd99;
        mem[132] = 32'd3;
        mem[133] = 32'd87;
        mem[134] = 32'd41;
        mem[135] = 32'd7;

        // Pre-init for matrix multiply A[2x2] at 200, B[2x2] at 204
        // A = [[1,2],[3,4]], B = [[5,6],[7,8]]
        mem[200] = 32'd1; mem[201] = 32'd2;
        mem[202] = 32'd3; mem[203] = 32'd4;
        mem[204] = 32'd5; mem[205] = 32'd6;
        mem[206] = 32'd7; mem[207] = 32'd8;
    end

    always @(posedge clk) begin
        if (we)
            mem[addr[31:2]] <= wd;
    end

    assign rd = mem[addr[31:2]];
endmodule