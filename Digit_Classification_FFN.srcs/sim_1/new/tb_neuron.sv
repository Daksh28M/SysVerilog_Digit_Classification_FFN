`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.08.2026 14:45:34
// Design Name: 
// Module Name: tb_neuron
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


module tb_neuron();
    logic clk;
    logic reset;
    logic en;

    logic signed [15:0] in_data [0:3];
    logic signed [7:0] weight [0:3];
    logic signed [7:0] bias;

    wire signed [31:0] neuron_out;
    wire neuron_done;

    neuron #(.IN_SIZE(4), .WIDTH(8)) dut(
        .clk(clk),
        .reset(reset),
        .en(en),
        .in_data(in_data),
        .weight(weight),
        .bias(bias),
        .neuron_out(neuron_out),
        .neuron_done(neuron_done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Inputs : [10, -3, 20, -7]
        in_data[0] = 16'sd10;
        in_data[1] = -16'sd3;
        in_data[2] = 16'sd20;
        in_data[3] = -16'sd7;

        //Weights: [-2, 5, -4, -6]
        weight[0] = -8'sd2;
        weight[1] = 8'sd5;
        weight[2] = -8'sd4;
        weight[3] = -8'sd6;

        bias = 8'sd9;

        //Expected neuron_out : -64
        reset = 1'b1;
        en = 1'b0;

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;
        en = 1'b1;

        repeat (4) @(posedge clk);  //IN_SIZE = 4
        #1;

        if(neuron_done != 1'b1)
            $fatal(1,"FAIL: neuron_done not asserted.");

        if(neuron_out !== -32'sd64)
            $fatal(1,"Fail: expected neuron_out = -64. got %0d.",neuron_out);

        $display("PASS: neuron operation and timing working correctly.");

        @(negedge clk);
        en = 1'b0;
        reset = 1'b1;

        @(posedge clk);
        #1;

        if(neuron_done != 1'b0 || neuron_out !== 32'sd0)
            $fatal(1,"FAIL: reset did not clear neuron state.");
        
        $display("PASS: neuron resets correctly for next MAC operation.");
        $finish;

    end
    
endmodule
