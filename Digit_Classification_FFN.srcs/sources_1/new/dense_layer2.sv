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

    localparam signed [7:0] B_ARRAY_L3 [0:9] = '{ -17, 12, 3, -9, 4, 23, -7, 9, -13, -9 };
        
    localparam signed [7:0] W_ARRAY_L3 [0:9][0:31] = '{
        { -80, 23, 4, 4, -9, -75, -73, 17, -48, 27, 15, -27, 18, 11, 5, -22, -16, 2, 23, -31, 5, 41, -31, 3, -35, -18, 11, 0, -27, 0, 51, -3 },
        { 12, -47, -53, -4, -74, 42, -61, 8, 20, -1, 26, -8, 3, 29, 19, 8, -14, 3, -86, -38, -102, -24, 26, 4, 3, 4, -1, 27, 31, -61, 17, -7 },
        { -58, 40, 10, 27, 8, 27, 35, -22, -10, 12, 29, -37, 8, 30, -127, 19, 11, -1, -10, 23, -44, -14, 35, 18, 0, -28, -3, 16, -79, 29, 1, 19 },
        { 6, -26, 29, 3, -51, 28, 34, 15, 18, 3, -59, -5, 38, -87, -34, 22, -11, -1, 26, -39, -15, 12, 2, -50, -1, 30, 44, -5, -30, -5, -54, 33 },
        { 22, -13, -59, -28, -12, 5, 41, 22, 4, -57, 66, -24, 11, 10, 28, -81, -13, 12, -9, 3, 20, -87, -74, 15, 28, -38, -69, -2, -15, -32, 44, 9 },
        { 20, -24, 21, -15, 11, -3, 40, -68, -40, 31, -11, 17, -15, 17, 36, 12, -14, -4, -14, -83, 28, 35, -13, -14, 4, -17, 48, -114, 40, 6, -86, -105 },
        { -45, 12, -85, 21, 21, -83, -32, -30, 7, -18, -9, -14, 16, -9, 19, 9, 0, 2, -9, 27, 34, 4, 18, 3, 1, 32, 32, -90, 44, -84, -6, -80 },
        { 9, -50, -3, 6, -9, -3, 3, 24, -22, -54, 71, 14, 18, -17, -9, -32, -16, 14, -31, 8, -30, 5, 53, -37, -65, 9, 6, 25, -38, 54, -12, 41 },
        { -14, -56, -7, -13, -1, -36, -37, 9, 33, 8, -56, 30, -59, 34, -35, 18, 12, 2, 39, 20, 6, -27, 1, 0, 12, -20, -58, -42, 5, -19, -18, 9 },
        { 7, 37, 24, -105, 36, -13, 5, 28, 34, -10, -53, -7, -105, -16, 39, -60, 14, 9, 2, 9, 18, 1, -100, -44, -22, 17, -27, 25, 11, 0, 32, -1 }    
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
