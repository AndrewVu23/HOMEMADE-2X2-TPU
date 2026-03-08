module systolic_array #(
    parameter DATA_WIDTH = 16,
    parameter PSUM_WIDTH = 32
)(
    input logic clk,
    input logic rst,
    input logic en,

    // Left signals
    input logic [1:0] load_weight_in,
    input logic [1:0] valid_in,
    input logic signed [DATA_WIDTH-1:0] input_in_r0,
    input logic signed [DATA_WIDTH-1:0] input_in_r1,

    // Top signals
    input logic [1:0] shift_weight_in,
    input logic signed [DATA_WIDTH-1:0] weight_in_c0,
    input logic signed [DATA_WIDTH-1:0] weight_in_c1,
    
    // Initial partial sums
    input logic signed [PSUM_WIDTH-1:0] psum_in_c0,
    input logic signed [PSUM_WIDTH-1:0] psum_in_c1,

    // Right outputs
    output logic signed [DATA_WIDTH-1:0] input_out_r0,
    output logic signed [DATA_WIDTH-1:0] input_out_r1,
    output logic [1:0] valid_out,

    // Final partial sums
    output logic signed [PSUM_WIDTH-1:0] psum_out_c0,
    output logic signed [PSUM_WIDTH-1:0] psum_out_c1
);
    // 1. Wires connecting PEs
    // PE00 to PE01 (Row 0)
    logic r0_c0_to_c1_load_weight;
    logic r0_c0_to_c1_valid;
    logic signed [DATA_WIDTH-1:0] r0_c0_to_c1_input;

    // PE10 to PE11 (Row 1)
    logic r1_c0_to_c1_load_weight;
    logic r1_c0_to_c1_valid;
    logic signed [DATA_WIDTH-1:0] r1_c0_to_c1_input;

    // PE00 to PE10 (Col 0)
    logic c0_r0_to_r1_shift_weight;
    logic signed [DATA_WIDTH-1:0] c0_r0_to_r1_weight;
    logic signed [PSUM_WIDTH-1:0] c0_r0_to_r1_psum;

    // PE01 to PE11 (Col 1)
    logic c1_r0_to_r1_shift_weight;
    logic signed [DATA_WIDTH-1:0] c1_r0_to_r1_weight;
    logic signed [PSUM_WIDTH-1:0] c1_r0_to_r1_psum;

    // 2. PE Instantiations
    // Top-Left PE00 (Row 0, Col 0)
    pe #(.DATA_WIDTH(DATA_WIDTH), .PSUM_WIDTH(PSUM_WIDTH)) 
    pe00 (
        .clk(clk),
        .rst(rst),
        .en(en),
        
        // Inputs
        .shift_weight_in(shift_weight_in[0]),
        .load_weight_in(load_weight_in[0]),
        .valid_in(valid_in[0]),
        .input_in(input_in_r0),
        .weight_in(weight_in_c0),
        .psum_in(psum_in_c0),
        
        // Outputs
        .shift_weight_out(c0_r0_to_r1_shift_weight), // To PE10
        .load_weight_out(r0_c0_to_c1_load_weight), // To PE01
        .valid_out(r0_c0_to_c1_valid), // To PE01
        .input_out(r0_c0_to_c1_input), // To PE01
        .weight_out(c0_r0_to_r1_weight), // To PE10
        .psum_out(c0_r0_to_r1_psum) // To PE10
    );

    // Top-Right PE (Row 0, Col 1)
    pe #(.DATA_WIDTH(DATA_WIDTH), .PSUM_WIDTH(PSUM_WIDTH))  
    pe01 (
        .clk(clk),
        .rst(rst),
        .en(en),
        
        // Inputs
        .shift_weight_in(shift_weight_in[1]),
        .load_weight_in(r0_c0_to_c1_load_weight), // From PE00
        .valid_in(r0_c0_to_c1_valid), // From PE00
        .input_in(r0_c0_to_c1_input), // From PE00
        .weight_in(weight_in_c1),
        .psum_in(psum_in_c1),
        
        // Outputs
        .shift_weight_out(c1_r0_to_r1_shift_weight), // To PE11
        .load_weight_out(), 
        .valid_out(valid_out[0]), 
        .input_out(input_out_r0), 
        .weight_out(c1_r0_to_r1_weight), // To PE11
        .psum_out(c1_r0_to_r1_psum) // To PE11
    );

    // Bottom-Left PE (Row 1, Col 0)
    pe #(.DATA_WIDTH(DATA_WIDTH), .PSUM_WIDTH(PSUM_WIDTH)) 
    pe10 (
        .clk(clk),
        .rst(rst),
        .en(en),
        
        // Inputs
        .shift_weight_in(c0_r0_to_r1_shift_weight), // From PE00
        .load_weight_in(load_weight_in[1]), 
        .valid_in(valid_in[1]),
        .input_in(input_in_r1),
        .weight_in(c0_r0_to_r1_weight), // From PE00
        .psum_in(c0_r0_to_r1_psum) // From PE00
        
        // Outputs
        .shift_weight_out(), 
        .load_weight_out(r1_c0_to_c1_load_weight), // To PE11
        .valid_out(r1_c0_to_c1_valid), // To PE11
        .input_out(r1_c0_to_c1_input), // To PE11
        .weight_out(), 
        .psum_out(psum_out_c0)
    );

    // Bottom-Right PE (Row 1, Col 1)
    pe #(.DATA_WIDTH(DATA_WIDTH), .PSUM_WIDTH(PSUM_WIDTH)) 
    pe11 (
        .clk(clk),
        .rst(rst),
        .en(en),
        
        // Inputs
        .shift_weight_in(c1_r0_to_r1_shift_weight), // From PE01
        .load_weight_in(r1_c0_to_c1_load_weight), // From PE10
        .valid_in(r1_c0_to_c1_valid), // From PE10
        .input_in(r1_c0_to_c1_input), // From PE10
        .weight_in(c1_r0_to_r1_weight), // From PE01
        .psum_in(c1_r0_to_r1_psum) // From PE01
        
        // Outputs
        .shift_weight_out(), 
        .load_weight_out(), 
        .valid_out(valid_out[1]), 
        .input_out(input_out_r1), 
        .weight_out(), 
        .psum_out(psum_out_c1)
    );

endmodule
