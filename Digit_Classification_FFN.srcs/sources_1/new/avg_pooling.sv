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
    // input clk,
    // input pool_en,
    input [7:0] in1,
    input [7:0] in2,
    input [7:0] in3,
    input [7:0] in4,
    // output pool_done,
    output [15:0] out
    );

    // reg [15:0] pool_out;
    // reg done;

    // always @(posedge clk) begin
    //     if(pool_en) begin
    //         pool_out <= ( {8'b0 , in1} + {8'b0 , in2} + {8'b0 , in3} + {8'b0 , in4} ) >>> 2;    // >> is logical shift and >>> is arithematic shift (preserves signed bit after shift )
    //         done <= 1'b1;
    //     end
    //     else begin
    //         done <= 1'b0;
    //     end
    // end

    // assign out = pool_out;
    // assign pool_done = done;
    
    wire [15:0] pool_sum;

    assign pool_sum = ( {8'b0 , in1} + {8'b0 , in2} + {8'b0 , in3} + {8'b0 , in4} );
    assign out = pool_sum >> 2;
    // assign pool_done = pool_en;
endmodule
