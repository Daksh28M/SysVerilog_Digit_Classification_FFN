`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.08.2026 20:20:07
// Design Name: 
// Module Name: tb_dense_layer
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


module tb_dense_layer #(parameter NEURON_NB = 3, IN_SIZE = 4, WIDTH = 8)();
    
    logic clk;
    logic layer_en;
    logic reset;
    logic signed [2*WIDTH-1:0] in_data[0:IN_SIZE-1];
    logic signed [WIDTH-1:0] weights[0:NEURON_NB-1][0:IN_SIZE-1];
    logic signed [WIDTH-1:0] biases[0:NEURON_NB-1];
    logic signed [4*WIDTH-1:0] neuron_out[0:NEURON_NB-1];
    logic layer_done;

    dense_layer #(.NEURON_NB(NEURON_NB), .IN_SIZE(IN_SIZE), .WIDTH(WIDTH)) dut(
        .clk(clk),
        .layer_en(layer_en),
        .reset(reset),
        .in_data(in_data),
        .weights(weights),
        .biases(biases),
        .neuron_out(neuron_out),
        .layer_done(layer_done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Inputs : [10, -3, 20, -7]
        in_data[0] = 16'sd10;
        in_data[1] = -16'sd3;
        in_data[2] = 16'sd20;
        in_data[3] = -16'sd7;

        // Neuron 0: weights [-2,  5, -4, -6]
        // Neuron 1: weights [ 1, -3,  2,  4]
        // Neuron 2: weights [-1, -2,  3, -4]

        weights[0] = {-8'sd2, 8'sd5, -8'sd4, -8'sd6};
        weights[1] = {8'sd1, -8'sd3, 8'sd2, 8'sd4};
        weights[2] = {-8'sd1, -8'sd2, 8'sd3, -8'sd4};

        // biases : [9, -5, 8]
        biases = {8'sd9, -8'sd5, 8'sd8};

        //Expected neuron_out : {-64, 26, 92}        
        reset = 1'b1;
        layer_en = 1'b1;

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;
        layer_en = 1'b1;

        repeat (4) @(posedge clk);  //IN_SIZE = 4
        #1; 

        // if(layer_done != 1'b1)
        //     $fatal(1,"FAIL: layer_done not asserted.");

        if(neuron_out[0] !== -32'sd64 || neuron_out[1] !== 32'sd26 || neuron_out[2] !== 32'sd92)
            $fatal(1,"Fail: expected neuron_out = {-64, 26, 92}. got %0p.",neuron_out);

        $display("PASS: neuron operation and timing working correctly.");

        @(posedge clk);
        #1;
        if(layer_done != 1'b1)
            $fatal(1,"FAIL: layer_done not asserted.");

        @(negedge clk);
        layer_en = 1'b0;
        reset = 1'b1;

        @(posedge clk);
        #1;

        if(layer_done != 1'b0 || (neuron_out[0] !== -32'sd0 || neuron_out[1] !== 32'sd0 || neuron_out[2] !== 32'sd0))
            $fatal(1,"FAIL: reset did not clear neuron states.");
        
        $display("PASS: layer resets correctly for next inference operation.");
        $finish;

    end

endmodule
