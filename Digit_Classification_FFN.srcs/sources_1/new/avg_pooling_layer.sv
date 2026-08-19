`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 12:13:39
// Design Name: 
// Module Name: avg_pooling_layer
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


module avg_pooling_layer(
    input clk,
    input enable,
    input reset,
    input [7:0] img[0:783],    //flattened 28x28 8-bit grayscale image vector
    output reg signed [15:0] pool [0:195],
    output reg pool_en
    );

    // // reg pool_en;
    
    // // wire finished_pool;  ----gpt-----

    // // reg signed [15:0] pool [0:195];

    // wire [7:0] pool_in1;
    // wire [7:0] pool_in2;
    // wire [7:0] pool_in3;
    // wire [7:0] pool_in4;
    // wire [15:0] pool_final;

    // reg [15:0] pool_in1_addr;
    // reg [15:0] pool_in2_addr;
    // reg [15:0] pool_in3_addr;
    // reg [15:0] pool_in4_addr;
    // reg [15:0] pool_final_addr = 16'b0;
    // reg [15:0] pool_addr = 16'b0;
    // reg [15:0] pool_row = 16'b0;
    
    // initial begin
    //     pool_in1_addr <= 16'd0;
    //     pool_in2_addr <= 16'd1;
    //     pool_in3_addr <= 16'd28;
    //     pool_in4_addr <= 16'd29;
    //     pool_en <= 1'b1;
    // end

    // avg_pooling AvgPooling(
    //     // .clk(clk),
    //     // .pool_en(pool_en),
    //     .in1(pool_in1),
    //     .in2(pool_in2),
    //     .in3(pool_in3),
    //     .in4(pool_in4),
    //     // .pool_done(finished_pool),
    //     .out(pool_final)
    // );

    // assign pool_in1 = (img[pool_in1_addr]);
    // assign pool_in2 = (img[pool_in2_addr]);
    // assign pool_in3 = (img[pool_in3_addr]);
    // assign pool_in4 = (img[pool_in4_addr]);

    // always @(posedge clk) begin
    //     if(reset) begin
    //         pool_in1_addr <= 16'd0;
    //         pool_in2_addr <= 16'd1;
    //         pool_in3_addr <= 16'd28;
    //         pool_in4_addr <= 16'd29;
    //         pool_final_addr <= 0;
    //         pool_addr <= 0;
    //         pool_row <= 0;
    //         pool_en <= 1'b1;
    //     end
    //     else if(enable) begin
    //         // if(finished_pool) begin
    //         if(pool_en) begin
    //             pool [pool_final_addr] = pool_final;    //signed-unsigned boundry
    //             pool_addr = pool_addr + 2;
    //             pool_row = pool_row +2;
    //             if(pool_row == 28) begin
    //                 pool_addr = pool_addr + pool_row;
    //                 pool_row = 0;
    //             end
    //             if(pool_in4_addr == 783) begin
    //                 pool_en <= 1'b0;
    //             end
    //             else if(pool_in4_addr != 783) begin
    //                 pool_in1_addr <= pool_addr;
    //                 pool_in2_addr <= pool_addr + 1;
    //                 pool_in3_addr <= pool_addr + 28;
    //                 pool_in4_addr <= pool_addr + 29;
    //                 pool_final_addr <= pool_final_addr + 1; 
    //             end
    //         end
    //     end
    // end

    ///////////////////Implementing 14 PEs, one for each row//////////////////////

    localparam POOL_ROWS = 14;
    localparam POOL_COLS = 14;

    reg [3:0] pool_col;
    wire [15:0] pool_final [0:POOL_ROWS-1];

    genvar row;
    generate
        for (row = 0; row < POOL_ROWS; row = row + 1) begin : pool_pe
            wire [7:0] in1;
            wire [7:0] in2;
            wire [7:0] in3;
            wire [7:0] in4;

    // Window top-left = (2*row)*28 + (2*pool_col).
            assign in1 = img[(56 * row) + (2 * pool_col)];
            assign in2 = img[(56 * row) + (2 * pool_col) + 1];
            assign in3 = img[(56 * row) + (2 * pool_col) + 28];
            assign in4 = img[(56 * row) + (2 * pool_col) + 29];
            
            avg_pooling AvgPooling(
                .in1(in1), .in2(in2), .in3(in3), .in4(in4),
                .out(pool_final[row])
            );
        end
    endgenerate

    integer output_row;

    always @(posedge clk) begin
    if (reset) begin
        pool_col <= 0;
        pool_en  <= 1'b1;
    end
    else if (enable && pool_en) begin
        for (output_row = 0; output_row < POOL_ROWS; output_row = output_row + 1) begin
            pool[(output_row * POOL_COLS) + pool_col] <= pool_final[output_row];
        end

        if (pool_col == POOL_COLS - 1) begin
            pool_en <= 1'b0;
        end
        else begin
            pool_col <= pool_col + 1'b1;
        end
    end
end

endmodule
