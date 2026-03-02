module pe #(
    parameter DATA_WIDTH = 16,
    parameter PSUM_WIDTH = 32
)(
    // Global inputs
    input logic clk,
    input logic rst,
    input logic en,
    
    // Double buffering control signals
    input logic shift_weight_in,
    input logic load_weight_in,

    // Data inputs
    input logic valid_in,
    input logic signed [DATA_WIDTH-1:0] input_in,
    input logic signed [DATA_WIDTH-1:0] weight_in,
    input logic signed [PSUM_WIDTH-1:0] psum_in,

    // Outputs
    output logic shift_weight_out,
    output logic load_weight_out,
    output logic valid_out,
    output logic signed [DATA_WIDTH-1:0] input_out,
    output logic signed [DATA_WIDTH-1:0] weight_out,
    output logic signed [PSUM_WIDTH-1:0] psum_out
);
    // 1. Weight Registers (Double Buffering)
    logic signed [DATA_WIDTH-1:0] shadow_weight_reg;
    logic signed [DATA_WIDTH-1:0] active_weight_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            shadow_weight_reg <= 16'b0;
            active_weight_reg <= 16'b0;
            shift_weight_out <= 1'b0;
            load_weight_out <= 1'b0;
        end 
        
        else begin
            if (shift_weight_in) shadow_weight_reg <= weight_in;
            if (load_weight_in) active_weight_reg <= shadow_weight_reg; 

            shift_weight_out <= shift_weight_in;
            load_weight_out <= load_weight_in;
        end
    end
    
    assign weight_out = shadow_weight_reg;

    // 2. 2-stage Delay Registers for Data Alignment 
    logic [1:0] valid_pipeline;
    logic signed [DATA_WIDTH-1:0] input_pipeline [1:0];

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_pipeline <= '0;
            input_pipeline[0] <= '0;
            input_pipeline[1] <= '0;
        end else if (en) begin
            valid_pipeline <= {valid_pipeline[0], valid_in};
            input_pipeline[0] <= input_in;
            input_pipeline[1] <= input_pipeline[0];
        end
    end

    // 3. Output Registers
    always_ff @(posedge clk) begin
        if (rst) begin
            input_out <= 16'b0;
            psum_out  <= 32'b0;
            valid_out <= 1'b0;
        end 

        else if (en) begin
            input_out <= input_pipeline[1];
            valid_out <= valid_pipeline[1];

            if (valid_pipeline[1]) begin
                psum_out <= mac_out;
            end 
            
            else begin
                psum_out <= psum_in;
            end
        end
    end
    
    // 4. MAC Operation Data Paths
    logic signed [PSUM_WIDTH-1:0] mult_out;
    logic signed [PSUM_WIDTH-1:0] mac_out;
    logic mult_overflow;
    logic add_overflow;

    fxp_mul_pipe #(
        .WIIA(DATA_WIDTH/2), .WIFA(DATA_WIDTH/2),
        .WIIB(DATA_WIDTH/2), .WIFB(DATA_WIDTH/2),
        .WOI(PSUM_WIDTH/2),  .WOF(PSUM_WIDTH/2),
        .ROUND(1)
    ) mult (
        .clk(clk),
        .rstn(~rst),
        .ina(input_in),
        .inb(active_weight_reg),
        .out(mult_out),
        .overflow(mult_overflow)
    );

    fxp_add #(
        .WIIA(PSUM_WIDTH/2), .WIFA(PSUM_WIDTH/2),
        .WIIB(PSUM_WIDTH/2), .WIFB(PSUM_WIDTH/2),
        .WOI(PSUM_WIDTH/2), .WOF(PSUM_WIDTH/2),
        .ROUND(1)
    ) adder (
        .ina(mult_out),
        .inb(psum_in),
        .out(mac_out),
        .overflow(add_overflow)
    );
endmodule