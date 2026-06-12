`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 16:35:23
// Design Name: 
// Module Name: dense_layer2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dense_layer2(
    input clk,
    input enable,
    input reset,
    input signed [15:0] in_data[0:31],
    output signed [15:0] layer_out[0:9],
    output layer_done
    );

    reg signed [31:0] dense2_res [0:9];    //result of second dense layer ( 32 bit wide outputs for each of 10 neurons )
    reg signed [15:0] relu_result [0:9];

    localparam signed [7:0] B_ARRAY_L3 [0:9] = '{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
        
    localparam signed [7:0] W_ARRAY_L3 [0:9][0:31] = '{
        { -33, -124, -16, -76, 56, -98, -84, 44, 2, 83, 55, -1, 30, -128, 78, 30, -128, -11, -107, 55, 33, -10, 68, 20, -7, -128, 56, -66, 20, 59, -21, -36 },
        { 80, 127, 102, -81, 71, 96, 17, -79, -57, 2, -3, 109, -128, -109, -25, 68, 75, 46, 35, -86, -27, 62, 72, 33, -128, 67, -128, -128, 14, -101, -9, -83 },
        { -51, -117, 77, -128, 18, 6, 8, -128, 98, 116, 76, -52, -24, 14, 30, 29, 30, 80, 79, 2, -128, 87, 63, -103, 25, 60, -83, -45, -15, -41, 74, 51 },
        { -128, -56, 30, 92, 38, -6, 38, -4, 27, 75, 73, 78, 1, -1, -122, 42, 24, 114, -77, -47, 32, 17, 14, -115, 38, 90, 15, -32, 64, -89, -60, -81 },
        { 45, 86, -37, -17, -128, -60, 27, -15, 9, -128, -17, 50, 103, -92, 85, 53, 56, -47, -74, 83, -128, 84, -128, 55, -111, -94, -44, -18, 102, 11, -29, 36 },
        { -104, 64, 53, 115, 67, -116, -103, 83, 39, 76, -44, -128, 79, -119, -74, -128, -9, -128, 52, -83, 31, 71, 7, 127, -9, 87, 0, 53, 94, 66, -14, -82 },
        { 67, 16, 66, 3, -1, 101, 52, 64, 55, 37, 43, -71, 97, -128, -36, -128, -128, -108, -116, 16, 42, 83, 59, -49, -128, -121, -55, -128, 15, 67, 28, -33 },
        { -57, 66, 127, -96, -87, 74, 20, -89, 55, 126, -82, 81, 28, -39, 91, 2, -118, 4, 28, -78, -15, 67, -12, 58, 26, -75, 41, 34, -128, -55, -128, -25 },
        { 56, -14, 43, -6, 41, -102, -51, 8, -128, -20, 48, -2, 99, 58, -72, 19, 42, -128, -28, -29, -54, 69, 34, -72, -59, -17, 51, -4, 54, -30, 21, 23 },
        { -42, -1, 26, 4, 6, -4, 25, -54, -43, 15, 6, -7, -46, -31, 34, -45, -12, 34, 41, -51, -37, -16, 12, -29, -47, -30, -13, -47, -24, 1, -32, -13 }   
    };
        
    wire dense2_en = enable;
    wire dense2_done;

    dense_layer #(.NEURON_NB(10), .IN_SIZE(32), .WIDTH(8)) dense_layer2(
        .clk(clk),
        .layer_en(dense2_en),
        .reset(reset),
        .in_data(in_data),
        .weights(W_ARRAY_L3),
        .biases(B_ARRAY_L3),
        .neuron_out(dense2_res),
        .layer_done(dense2_done)
    );

    genvar i;
        generate
            for(i=0;i<10;i=i+1) begin : relu_gen
                relu relu_inst(
                    .data_in(dense2_res[i]),
                    .data_out(relu_result[i])
                );
            end
        endgenerate

    // relu relu_inst[0:9](
    //     .data_in(dense2_res), 
    //     .data_out(relu_result)
    // );

    assign layer_out = relu_result;
    assign layer_done = dense2_done;

endmodule
