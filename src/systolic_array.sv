module systolic_array #(
    parameter DATA_WIDTH = 16,
    parameter PSUM_WIDTH = 32
)(
    input logic clk,
    input logic rst,
    input logic en,

    // Global signals entering the left edges of row 0 and row 1
    input logic [1:0] load_weight_in,
    input logic [1:0] valid_in,
    input logic signed [DATA_WIDTH-1:0] input_in_r0,
    input logic signed [DATA_WIDTH-1:0] input_in_r1,

    // Global signals entering the top edges of col 0 and col 1
    input logic [1:0] shift_weight_in,
    input logic signed [DATA_WIDTH-1:0] weight_in_c0,
    input logic signed [DATA_WIDTH-1:0] weight_in_c1,
    
    // Initial partial sums entering the top (usually 0)
    input logic signed [PSUM_WIDTH-1:0] psum_in_c0,
    input logic signed [PSUM_WIDTH-1:0] psum_in_c1,

    // Final outputs emerging from the right edges (Row 0 and Row 1)
    output logic signed [DATA_WIDTH-1:0] input_out_r0,
    output logic signed [DATA_WIDTH-1:0] input_out_r1,
    output logic [1:0] valid_out,

    // Final partial sums emerging from the bottom edges (Col 0 and Col 1)
    output logic signed [PSUM_WIDTH-1:0] psum_out_c0,
    output logic signed [PSUM_WIDTH-1:0] psum_out_c1
);
    // 1. Wires connecting PEs
    // Wires passing signals Horizontally from PE00 to PE01 (Row 0)
    logic r0_c0_to_c1_load_weight;
    logic r0_c0_to_c1_valid;
    logic signed [DATA_WIDTH-1:0] r0_c0_to_c1_input;

    // Wires passing signals Horizontally from PE10 to PE11 (Row 1)
    logic r1_c0_to_c1_load_weight;
    logic r1_c0_to_c1_valid;
    logic signed [DATA_WIDTH-1:0] r1_c0_to_c1_input;

    // Wires passing signals Vertically from PE00 to PE10 (Col 0)
    logic c0_r0_to_r1_shift_weight;
    logic signed [DATA_WIDTH-1:0] c0_r0_to_r1_weight;
    logic signed [PSUM_WIDTH-1:0] c0_r0_to_r1_psum;

    // Wires passing signals Vertically from PE01 to PE11 (Col 1)
    logic c1_r0_to_r1_shift_weight;
    logic signed [DATA_WIDTH-1:0] c1_r0_to_r1_weight;
    logic signed [PSUM_WIDTH-1:0] c1_r0_to_r1_psum;

    // 2. PE Instantiations
    // Top-Left PE (Row 0, Col 0)
    pe #(.DATA_WIDTH(DATA_WIDTH), .PSUM_WIDTH(PSUM_WIDTH)) 
    pe00 (
        .clk(clk),
        .rst(rst),
        .en(en),
        
        // Inputs coming from the external boundaries
        .shift_weight_in(shift_weight_in[0]),
        .load_weight_in(load_weight_in[0]),
        .valid_in(valid_in[0]),
        .input_in(input_in_r0),
        .weight_in(weight_in_c0),
        .psum_in(psum_in_c0),
        
        // Outputs routing to neighboring PEs
        .shift_weight_out(c0_r0_to_r1_shift_weight), // Going South
        .load_weight_out(r0_c0_to_c1_load_weight), // Going East
        .valid_out(r0_c0_to_c1_valid), // Going East
        .input_out(r0_c0_to_c1_input), // Going East
        .weight_out(c0_r0_to_r1_weight), // Going South
        .psum_out(c0_r0_to_r1_psum) // Going South
    );

    // Top-Right PE (Row 0, Col 1)
    pe #(.DATA_WIDTH(DATA_WIDTH), .PSUM_WIDTH(PSUM_WIDTH))  
    pe01 (
        .clk(clk),
        .rst(rst),
        .en(en),
        
        // Inputs coming from PE00 (West) and external boundary (North)
        .shift_weight_in(shift_weight_in[1]),
        .load_weight_in(r0_c0_to_c1_load_weight), // From PE00
        .valid_in(r0_c0_to_c1_valid), // From PE00
        .input_in(r0_c0_to_c1_input), // From PE00
        .weight_in(weight_in_c1),
        .psum_in(psum_in_c1),
        
        // Outputs routing to the right external boundary and South PE
        .shift_weight_out(c1_r0_to_r1_shift_weight), // Going South
        .load_weight_out(), // Dead end (Edge of array)
        .valid_out(valid_out[0]), // Exit array
        .input_out(input_out_r0), // Exit array
        .weight_out(c1_r0_to_r1_weight), // Going South
        .psum_out(c1_r0_to_r1_psum) // Going South
    );

    // Bottom-Left PE (Row 1, Col 0)
    pe #(.DATA_WIDTH(DATA_WIDTH), .PSUM_WIDTH(PSUM_WIDTH)) 
    pe10 (
        .clk(clk),
        .rst(rst),
        .en(en),
        
        // Inputs coming from external boundary (West) and PE00 (North)
        .shift_weight_in(c0_r0_to_r1_shift_weight), // From PE00
        .load_weight_in(load_weight_in[1]), 
        .valid_in(valid_in[1]),
        .input_in(input_in_r1),
        .weight_in(c0_r0_to_r1_weight), // From PE00
        .psum_in(c0_r0_to_r1_psum) // From PE00
        
        // Outputs routing to East PE and bottom external boundary
        .shift_weight_out(), // Dead end (Edge of array)
        .load_weight_out(r1_c0_to_c1_load_weight), // Going East
        .valid_out(r1_c0_to_c1_valid), // Going East
        .input_out(r1_c0_to_c1_input), // Going East
        .weight_out(), // Dead end (Edge of array)
        .psum_out(psum_out_c0) // Exit array
    );

    // Bottom-Right PE (Row 1, Col 1)
    pe #(.DATA_WIDTH(DATA_WIDTH), .PSUM_WIDTH(PSUM_WIDTH)) 
    pe11 (
        .clk(clk),
        .rst(rst),
        .en(en),
        
        // Inputs coming entirely from neighboring PEs (PE10 West, PE01 North)
        .shift_weight_in(c1_r0_to_r1_shift_weight), // From PE01
        .load_weight_in(r1_c0_to_c1_load_weight), // From PE10
        .valid_in(r1_c0_to_c1_valid), // From PE10
        .input_in(r1_c0_to_c1_input), // From PE10
        .weight_in(c1_r0_to_r1_weight), // From PE01
        .psum_in(c1_r0_to_r1_psum) // From PE01
        
        // Outputs routing to right and bottom boundaries
        .shift_weight_out(), // Dead end
        .load_weight_out(), // Dead end
        .valid_out(valid_out[1]), // Exit array
        .input_out(input_out_r1), // Exit array
        .weight_out(), // Dead end
        .psum_out(psum_out_c1) // Exit array
    );

endmodule
