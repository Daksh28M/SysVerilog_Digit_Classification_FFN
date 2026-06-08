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
    reg signed [31:0] relu_result [0:9];

    localparam signed [7:0] B_ARRAY_L3 [0:9] = '{};
        
    localparam signed [7:0] W_ARRAY_L3 [0:9][0:31] = '{
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

    // genvar i;
    //     generate
    //         for(i=0;i<10;i=i+1) begin : relu_gen
    //             relu relu_inst(
    //                 .data_in(dense2_res[i]),
    //                 .data_out(relu_result[i])
    //             );
    //         end
    //     endgenerate

    relu relu_inst[0:9](
        .data_in(dense2_res), 
        .data_out(relu_result)
    );

    assign layer_out = relu_result;
    assign layer_done = dense2_done;

endmodule
