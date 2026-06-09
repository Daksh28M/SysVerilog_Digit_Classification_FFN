`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 12:15:24
// Design Name: 
// Module Name: avg_pooling
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


module avg_pooling(
    input clk,
    input pool_en,
    input signed [7:0] in1,
    input signed [7:0] in2,
    input signed [7:0] in3,
    input signed [7:0] in4,
    output signed [7:0] out,
    output pool_done
    );

    reg signed [15:0] pool_out;
    reg done;

    always @(posedge clk) begin
        if(pool_en) begin
            pool_out <= ( in1 + in2 + in3 + in4 ) >>> 2;    // >> is logical shift and >>> is arithematic shift (preserves signed bit after shift )
            done <= 1'b1;
        end
        else begin
            done <= 1'b0;
        end
    end

    assign out = pool_out[7:0];
    assign pool_done = done;
    
endmodule
