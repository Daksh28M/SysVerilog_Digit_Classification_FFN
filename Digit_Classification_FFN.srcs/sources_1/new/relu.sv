`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 16:53:52
// Design Name: 
// Module Name: relu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - Parameterized shift
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module relu #(parameter WIDTH = 8, SHIFT = 6)(
    input signed [4*WIDTH-1:0] data_in,
    output signed [2*WIDTH-1:0] data_out
    );

    localparam IN_WIDTH  = 4 * WIDTH;
    localparam OUT_WIDTH = 2 * WIDTH;

    localparam signed [IN_WIDTH-1:0] MAX_OUTPUT = (1 <<< (OUT_WIDTH - 1)) - 1;

    wire signed [IN_WIDTH-1:0] relu_value;
    wire signed [IN_WIDTH-1:0] scaled_value;

    assign relu_value   = (data_in > 0) ? data_in : '0;
    assign scaled_value = relu_value >>> SHIFT;

    assign data_out = (scaled_value > MAX_OUTPUT) ? MAX_OUTPUT[OUT_WIDTH-1:0] : scaled_value[OUT_WIDTH-1:0];

endmodule
