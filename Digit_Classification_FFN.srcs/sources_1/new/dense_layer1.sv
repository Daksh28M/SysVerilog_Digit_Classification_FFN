`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 15:20:52
// Design Name: 
// Module Name: dense_layer1
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


module dense_layer1(
    input clk,
    input enable,
    input reset,
    input signed [15:0] pooled_img[0:195],
    output signed [15:0] layer_out[0:31],
    output layer_done
    );

    reg signed [31:0] dense1_res [0:31];    //result of first dense layer ( 32 bit wide outputs for each of 32 neurons )
    reg signed [31:0] relu_result [0:31];

    localparam signed [7:0] B_ARRAY_L2 [0:31] = '{};
        
    localparam signed [7:0] W_ARRAY_L2 [0:31][0:195] = '{
    };
        
    wire dense1_en = enable;
    wire dense1_done;

    dense_layer #(.NEURON_NB(32), .IN_SIZE(196), .WIDTH(8)) dense_layer1(
        .clk(clk),
        .layer_en(dense1_en),
        .reset(reset),
        .in_data(pooled_img),
        .weights(W_ARRAY_L2),
        .biases(B_ARRAY_L2),
        .neuron_out(dense1_res),
        .layer_done(dense1_done)
    );

    // genvar i;
    //     generate
    //         for(i=0;i<32;i=i+1) begin : relu_gen
    //             relu relu_inst(
    //                 .data_in(dense1_res[i]),
    //                 .data_out(relu_result[i])
    //             );
    //         end
    //     endgenerate

    relu relu_inst[0:31](
        .data_in(dense1_res), 
        .data_out(relu_result)
    );

    assign layer_out = relu_result;
    assign layer_done = dense1_done;

endmodule
