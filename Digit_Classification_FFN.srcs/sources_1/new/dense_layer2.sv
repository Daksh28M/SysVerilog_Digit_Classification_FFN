`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 16:35:23
// Design Name: 
// Module Name: dense_layer2
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


module dense_layer2(
    input clk,
    input enable,
    input reset,
    input signed [15:0] in_data[0:31],
    output signed [15:0] layer_out[0:9],
    output layer_done
    );

    reg signed [31:0] dense2_res [0:9];    //result of second dense layer ( 32 bit wide outputs for each of 10 neurons )
    reg signed [15:0] relu_result [0:9];

    localparam signed [7:0] B_ARRAY_L3 [0:9] = '{8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0, 8'sd0};
        
    localparam signed [7:0] W_ARRAY_L3 [0:9][0:31] = 
    '{
    '{8'sd38, -8'sd75, 8'sd61, 8'sd42, -8'sd43, 8'sd20, -8'sd56, 8'sd5, -8'sd24, -8'sd18, 8'sd85, -8'sd2, 8'sd14, 8'sd84, -8'sd76, -8'sd16, -8'sd29, 8'sd24, -8'sd83, 8'sd89, 8'sd13, -8'sd1, -8'sd35, 8'sd21, -8'sd51, -8'sd24, 8'sd13, 8'sd0, -8'sd34, -8'sd5, 8'sd5, 8'sd15},
    '{-8'sd60, -8'sd29, 8'sd13, 8'sd24, 8'sd49, 8'sd18, 8'sd76, -8'sd11, 8'sd35, 8'sd50, 8'sd15, 8'sd33, 8'sd26, -8'sd104, 8'sd127, -8'sd43, 8'sd43, 8'sd55, 8'sd7, -8'sd21, -8'sd40, -8'sd48, 8'sd15, -8'sd39, -8'sd11, 8'sd38, 8'sd9, -8'sd65, 8'sd38, 8'sd47, 8'sd18, 8'sd62},
    '{8'sd114, -8'sd3, 8'sd54, -8'sd72, 8'sd41, -8'sd60, 8'sd75, 8'sd19, -8'sd7, 8'sd24, 8'sd6, 8'sd20, 8'sd11, 8'sd4, -8'sd1, 8'sd18, -8'sd24, 8'sd42, -8'sd5, 8'sd1, 8'sd60, 8'sd32, 8'sd13, -8'sd65, -8'sd16, -8'sd5, -8'sd20, 8'sd38, -8'sd64, 8'sd92, -8'sd17, 8'sd33},
    '{-8'sd13, 8'sd56, -8'sd83, 8'sd25, 8'sd40, -8'sd26, 8'sd14, -8'sd1, -8'sd40, 8'sd78, -8'sd62, 8'sd11, 8'sd116, 8'sd3, -8'sd28, -8'sd20, -8'sd13, 8'sd18, -8'sd46, 8'sd41, -8'sd28, 8'sd32, 8'sd10, 8'sd1, 8'sd4, -8'sd21, -8'sd36, 8'sd94, 8'sd14, 8'sd49, 8'sd5, -8'sd5},
    '{-8'sd65, 8'sd51, 8'sd5, -8'sd16, -8'sd12, 8'sd24, -8'sd65, 8'sd99, -8'sd2, -8'sd6, -8'sd2, 8'sd30, -8'sd53, 8'sd39, -8'sd26, 8'sd70, 8'sd44, -8'sd12, 8'sd16, -8'sd65, 8'sd56, -8'sd18, -8'sd2, 8'sd28, 8'sd76, 8'sd63, 8'sd3, -8'sd87, 8'sd51, 8'sd84, 8'sd4, -8'sd19},
    '{8'sd46, 8'sd23, 8'sd36, 8'sd48, 8'sd26, 8'sd84, -8'sd83, 8'sd30, -8'sd20, -8'sd9, 8'sd15, 8'sd9, 8'sd100, -8'sd8, 8'sd36, 8'sd63, 8'sd59, 8'sd42, -8'sd83, -8'sd56, -8'sd11, -8'sd12, -8'sd12, 8'sd70, -8'sd11, -8'sd45, 8'sd37, -8'sd23, -8'sd6, -8'sd5, -8'sd104, 8'sd49},
    '{8'sd16, 8'sd117, 8'sd114, 8'sd9, -8'sd26, 8'sd17, -8'sd50, -8'sd38, -8'sd6, -8'sd2, 8'sd43, -8'sd6, -8'sd73, 8'sd36, 8'sd9, -8'sd35, 8'sd29, 8'sd44, 8'sd25, -8'sd73, -8'sd58, -8'sd24, -8'sd21, -8'sd28, -8'sd5, -8'sd32, -8'sd31, -8'sd37, -8'sd66, 8'sd19, 8'sd78, -8'sd27},
    '{8'sd14, -8'sd66, -8'sd44, -8'sd39, 8'sd30, 8'sd23, 8'sd34, -8'sd120, -8'sd1, 8'sd47, -8'sd39, 8'sd13, 8'sd8, -8'sd17, -8'sd35, 8'sd101, -8'sd1, -8'sd84, 8'sd54, 8'sd73, 8'sd11, 8'sd66, -8'sd15, 8'sd57, -8'sd25, 8'sd7, 8'sd22, -8'sd51, 8'sd24, 8'sd25, 8'sd74, 8'sd59},
    '{-8'sd28, 8'sd43, 8'sd14, 8'sd14, -8'sd15, 8'sd77, 8'sd53, 8'sd29, 8'sd9, -8'sd9, 8'sd16, -8'sd38, -8'sd19, 8'sd5, 8'sd68, 8'sd34, -8'sd53, 8'sd13, 8'sd6, 8'sd31, 8'sd1, 8'sd72, -8'sd1, 8'sd8, 8'sd9, -8'sd64, -8'sd5, 8'sd9, 8'sd6, -8'sd57, -8'sd73, -8'sd37},
    '{-8'sd14, -8'sd19, 8'sd17, 8'sd34, 8'sd11, 8'sd38, -8'sd76, 8'sd10, 8'sd17, -8'sd41, -8'sd48, -8'sd23, 8'sd15, 8'sd5, 8'sd2, -8'sd51, 8'sd24, -8'sd75, 8'sd41, -8'sd4, 8'sd74, 8'sd66, -8'sd5, 8'sd71, -8'sd1, 8'sd48, -8'sd20, 8'sd1, 8'sd71, -8'sd68, 8'sd76, -8'sd43}
    };
        
    wire dense2_en = enable;
    wire dense2_done;

    dense_layer #(.NEURON_NB(10), .IN_SIZE(32), .WIDTH(8)) dense_layer2(
        .clk(clk),
        .layer_en(dense2_en),
        .reset(reset),
        .in_data(in_data),
        .weights(W_ARRAY_L3),
        .biases(B_ARRAY_L3),
        .neuron_out(dense2_res),
        .layer_done(dense2_done)
    );

    genvar i;
        generate
            for(i=0;i<10;i=i+1) begin : relu_gen
                relu relu_inst(
                    .data_in(dense2_res[i]),
                    .data_out(relu_result[i])
                );
            end
        endgenerate

    // relu relu_inst[0:9](
    //     .data_in(dense2_res), 
    //     .data_out(relu_result)
    // );

    assign layer_out = relu_result;
    assign layer_done = dense2_done;

endmodule
