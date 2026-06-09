`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 16:53:52
// Design Name: 
// Module Name: relu
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


module relu #(parameter WIDTH = 8)(
    input signed [4*WIDTH-1:0] data_in,
    output signed [2*WIDTH-1:0] data_out
    );

    //------------------------------------------------------------//
    
    wire signed [4*WIDTH-1:0] temp;
    
    assign temp = (data_in > 0)? data_in : 0;
    // assign temp = data_in;
    assign data_out = temp >>> 6;   //4W to 2W truncation

    //------------------------------------------------------------//

    // parameter SHIFT = 6;

    // wire signed [4*WIDTH-1:0] relu_val;
    // wire signed [4*WIDTH-1:0] shifted_val;
    
    // // 1. Standard ReLU (turns negatives to 0)
    // assign relu_val = (data_in > 0) ? data_in : 0;
    
    // // 2. Scale the numbers down to preserve relative differences
    // // Using >>> (Arithmetic Shift) is safer for signed numbers, 
    // // though relu_val is guaranteed positive here anyway.
    // assign shifted_val = relu_val >>> SHIFT; 
    
    // // 3. Define the maximum positive value for a signed 16-bit number (32767)
    // localparam signed [4*WIDTH-1:0] MAX_16BIT = (1 << (2*WIDTH-1)) - 1;
    
    // // 4. Saturation Logic: Clamp it ONLY if it's still too big after scaling
    // assign data_out = (shifted_val > MAX_16BIT) ? MAX_16BIT[2*WIDTH-1:0] : shifted_val[2*WIDTH-1:0];

    //------------------------------------------------------------//

endmodule
