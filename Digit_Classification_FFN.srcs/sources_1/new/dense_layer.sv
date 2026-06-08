`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 12:57:38
// Design Name: 
// Module Name: dense_layer
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


module dense_layer #(parameter NEURON_NB = 32, IN_SIZE = 196, WIDTH = 8)(
    input clk,
    input layer_en,
    input reset,
    input signed [2*WIDTH-1:0] in_data[0:IN_SIZE-1],
    input signed [WIDTH-1:0] weights[0:NEURON_NB-1][0:IN_SIZE-1], //3d memory array of weight vectors for all neurons ( 32 neurons x  196 weights x 8 bits )
    input signed [WIDTH-1:0] biases[0:NEURON_NB-1],
    output signed [4*WIDTH-1:0] neuron_out[0:NEURON_NB-1],
    output layer_done   
    );

    reg [0:NEURON_NB-1] neuron_done;
    reg done;

    neuron #(.IN_SIZE(IN_SIZE), .WIDTH(WIDTH)) dense_neuron[0:NEURON_NB-1](
        .clk(clk),
        .en(layer_en),
        .reset(reset),
        .in_data(in_data),
        .weight(weights),
        .bias(biases),
        .neuron_out(neuron_out),
        .neuron_done(neuron_done)
    );

    always @(posedge clk) begin
        if(reset) begin
            done <= 1'b0;
        end
        else if(&neuron_done) begin
            done <= 1'b1;
        end
    end

    assign layer_done = done;
endmodule
