`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 17:19:17
// Design Name: 
// Module Name: neural_net_top
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


module neural_net_top(
    input clk,
    input enable,
    input reset,
    input [7:0] image[0:783],
    output [7:0] digit_out,
    output nn_done
    );

    wire pool_enable;
    wire finished_pool;
    reg signed [15:0] pool [0:195];
    

    avg_pooling_layer AvgPoolingLayer(
        .clk(clk),
        .enable(enable),
        .reset(reset),
        .img(image),  
        .pool(pool),
        .pool_en(pool_enable)
    );
    
    reg dense1_enable;
    wire finished_dense1;
    reg signed [15:0] dense1_res [0:31];
    
    initial dense1_enable = 0;

    dense_layer1 layer2(
        .clk(clk),
        .enable(dense1_enable),
        .reset(reset),
        .pooled_img(pool),
        .layer_out(dense1_res),
        .layer_done(finished_dense1)
    );

    always @(posedge clk) begin
        if(reset) begin
            dense1_enable <= 0;
        end
        else if(enable) begin
            if(pool_enable == 0 && finished_dense1 == 0 ) begin
                dense1_enable <= 1;
            end
            else begin
                dense1_enable <= 0;
            end
        end
    end

    reg dense2_enable;
    wire finished_dense2;
    reg signed [15:0] dense2_res [0:9];
    
    initial dense2_enable = 0;

    dense_layer2 layer3(
        .clk(clk),
        .enable(dense2_enable),
        .reset(reset),
        .in_data(dense1_res),
        .layer_out(dense2_res),
        .layer_done(finished_dense2)
    );

    always @(posedge clk) begin
        if(reset) begin
            dense2_enable <= 0;
        end
        else if(enable) begin
            if(pool_enable == 0 && finished_dense1 == 1 && finished_dense2 == 0 ) begin
                dense2_enable <= 1;
            end
            else begin
                dense2_enable <= 0;
            end
        end
    end

    reg max_enable;
    wire digit_recog_done;
    reg [7:0] digit;

    initial max_enable <= 0;

    select_max maxLayer(
        .clk(clk),
        .enable(max_enable),
        .reset(reset),
        .in_data(dense2_res),
        .digit(digit),
        .layer_done(digit_recog_done)
    );

    always @(posedge clk) begin
        if(reset) begin
            max_enable <= 0;
        end
        else if(enable) begin
            if(finished_dense2 == 1) begin
                max_enable <= 1;
            end
            else begin
                max_enable <= 0;
            end
        end
    end

    assign digit_out = digit;
    assign nn_done = digit_recog_done;

endmodule
