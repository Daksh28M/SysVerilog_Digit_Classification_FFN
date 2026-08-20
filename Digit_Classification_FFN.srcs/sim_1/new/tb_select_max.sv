`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.08.2026 15:30:11
// Design Name: 
// Module Name: tb_select_max
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


module tb_select_max();

    logic clk;
    logic enable;
    logic reset;

    logic signed [15:0] in_data [0:3];
    wire [7:0] digit;
    wire layer_done;

    select_max #(.NEURON_NB(4), .WIDTH(8)) dut (
        .clk(clk),
        .enable(enable),
        .reset(reset),
        .in_data(in_data),
        .digit(digit),
        .layer_done(layer_done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic reset_dut;
        begin
            @(negedge clk);
            enable = 1'b0;
            reset  = 1'b1;

            @(posedge clk);
            #1;

            if (digit !== 8'd0 || layer_done !== 1'b0)
                $fatal(1, "FAIL: reset did not clear select_max state.");

            @(negedge clk);
            reset = 1'b0;
        end
    endtask

    task automatic check_result(
        input [7:0] expected_digit,
        input string test_name
    );
        begin
            @(negedge clk);
            enable = 1'b1;

            @(posedge clk);
            #1;

            if (digit !== expected_digit || layer_done !== 1'b1)
                $fatal(
                    1,
                    "FAIL: %s | expected digit=%0d, got digit=%0d, done=%0b",
                    test_name, expected_digit, digit, layer_done
                );

            $display("PASS: %s | selected digit=%0d", test_name, digit);
        end
    endtask

    initial begin
        reset  = 1'b1;
        enable = 1'b0;

        repeat (2) @(posedge clk);

        // Normal maximum: index 1 contains 12.
        reset = 1'b0;
        in_data = '{-16'sd5, 16'sd12, 16'sd4, 16'sd9};
        check_result(8'd1, "normal maximum");

        // The RTL uses >=, so the later equal maximum wins: index 2.
        reset_dut();
        in_data = '{16'sd3, 16'sd8, 16'sd8, 16'sd2};
        check_result(8'd2, "tie selects highest index");

        // Signed comparison: -1 is larger than -4 and -9.
        // Tie between indices 2 and 3: index 3 wins.
        reset_dut();
        in_data = '{-16'sd4, -16'sd9, -16'sd1, -16'sd1};
        check_result(8'd3, "all-negative signed comparison");

        $display("PASS: all select_max tests completed.");
        $finish;
    end
endmodule
