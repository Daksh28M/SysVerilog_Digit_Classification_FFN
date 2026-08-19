`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.08.2026 00:35:31
// Design Name: 
// Module Name: tb_avg_pooling_layer
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


module tb_avg_pooling_layer();
    logic clk;
    logic reset;
    logic enable;

    logic [7:0] img [0:783];
    wire signed [15:0] pool [0:195];
    wire pool_en;

    integer r, c, pr, pc, idx;
    integer expected;
    integer failures;

    avg_pooling_layer dut(
        .clk(clk),
        .enable(enable),
        .reset(reset),
        .img(img),
        .pool(pool),
        .pool_en(pool_en)
    );

    //---------------clock----------------//
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        
        //random input image
        for (r = 0; r < 28; r = r + 1) begin
            for (c = 0; c < 28; c = c + 1) begin
                img[r*28 + c] = 4*r + 2*c;
            end
        end

        reset   = 1'b1;
        enable  = 1'b0;
        failures = 0;
        repeat (3) @(posedge clk);
        reset  = 1'b0;
        enable = 1'b1;

        repeat (500) begin
            @(posedge clk);
            if (pool_en == 1'b0)
                break;
        end

        if (pool_en != 1'b0) begin
            $fatal(1, "TIMEOUT: pooling never completed.");
        end

        // Allow registered values to settle, then verify all 196 outputs.
        #1;

        for (pr = 0; pr < 14; pr = pr + 1) begin
            for (pc = 0; pc < 14; pc = pc + 1) begin
                idx = pr*14 + pc;
                expected = 8*pr + 4*pc + 3;

                if (pool[idx] !== expected) begin
                    $error(
                        "Mismatch: pool[%0d] (row=%0d, col=%0d): expected %0d, got %0d",
                        idx, pr, pc, expected, pool[idx]
                    );
                    failures = failures + 1;
                end
            end
        end

        if (failures == 0) begin
            $display("PASS: All 196 pooled outputs are correct.");
        end
        else begin
            $fatal(1, "FAIL: %0d of 196 pooling values mismatched.", failures);
        end

        $finish;

    end
    
endmodule
