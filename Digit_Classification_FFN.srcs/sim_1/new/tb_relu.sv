`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.08.2026 14:28:08
// Design Name: 
// Module Name: tb_relu
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


module tb_relu();

    logic signed [31:0] data_in;
    wire  signed [15:0] data_out;

    relu #( .WIDTH(8), .SHIFT(6) ) dut (
        .data_in (data_in),
        .data_out(data_out)
    );

    task automatic check_relu(
        input logic signed [31:0] stimulus,
        input logic signed [15:0] expected,
        input string test_name
    );
        begin
            data_in = stimulus;
            #1;

            if (data_out !== expected)
                $fatal(
                    1,
                    "FAIL: %s | input=%0d, expected=%0d, got=%0d",
                    test_name, stimulus, expected, data_out
                );

            $display(
                "PASS: %s | input=%0d, output=%0d",
                test_name, stimulus, data_out
            );
        end
    endtask

    initial begin
        // Negative and zero values
        check_relu(-32'sd1,  16'sd0, "negative value clamps to zero");
        check_relu( 32'sd0,  16'sd0, "zero remains zero");

        // Truncating right-shift boundaries, SHIFT = 6
        check_relu( 32'sd63, 16'sd0, "63 shifted by 6 becomes zero");
        check_relu( 32'sd64, 16'sd1, "64 shifted by 6 becomes one");
        check_relu( 32'sd65, 16'sd1, "65 truncates to one");

        // Largest representable positive output
        check_relu(32'sd2_097_151, 16'sd32_767,
                   "largest non-saturated output"); // 2^21-1 

        // 32,768 after shift: must saturate, never wrap negative
        check_relu(32'sd2_097_152, 16'sd32_767,
                   "first saturated output");   //2^21

        // General large-positive saturation
        check_relu(32'sh7fff_ffff, 16'sd32_767,
                   "maximum positive accumulator saturates");

        $display("PASS: all ReLU tests completed.");
        $finish;
    end

endmodule
