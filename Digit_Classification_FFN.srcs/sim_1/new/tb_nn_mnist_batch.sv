`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.08.2026 20:50:44
// Design Name: 
// Module Name: tb_nn_mnist_batch
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


module tb_nn_mnist_batch();

    localparam int NUM_IMAGES       = 10_000;
    localparam int PIXELS_PER_IMAGE = 784;
    localparam int TOTAL_PIXELS     = NUM_IMAGES * PIXELS_PER_IMAGE;

    // Give XSim the filenames to load from the simulation working directory.
    localparam string PIXEL_FILE     = "E:/VerilogProjects/Digit_Classification_FFN/mnist_test_pixels.hex";
    localparam string LABEL_FILE     = "E:/VerilogProjects/Digit_Classification_FFN/mnist_test_labels.hex";
    localparam string REFERENCE_FILE = "E:/VerilogProjects/Digit_Classification_FFN/mnist_rtl_reference_predictions.hex";

    // Limit detailed error messages while still retaining every error in counters.
    localparam int MAX_MISMATCH_REPORTS = 20;

    // Count agreement with Python and classification correctness independently.
    int reference_mismatch_count;
    int correct_prediction_count;
    int reported_mismatch_count;

    // Track the image-loop index and total simulation duration.
    int image_index;
    time simulation_start_time;

    // Store every raw uint8 pixel from all 10,000 input images.
    logic [7:0] pixel_memory [0:TOTAL_PIXELS-1];

    // Store one true label and one golden Python prediction per image.
    logic [3:0] label_memory     [0:NUM_IMAGES-1];
    logic [3:0] reference_memory [0:NUM_IMAGES-1];

    // These signals drive the accelerator top-level.
    logic clk;
    logic enable;
    logic reset;
    logic [7:0] image [0:PIXELS_PER_IMAGE-1];
    logic [7:0] digit_out;
    logic nn_done;

    // Instantiate the unchanged classifier DUT.
    neural_net_top dut (
        .clk       (clk),
        .enable    (enable),
        .reset     (reset),
        .image     (image),
        .digit_out (digit_out),
        .nn_done   (nn_done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Copy one contiguous 784-pixel image from file-backed memory to the DUT input.
    task automatic load_image(input int image_index);
        int pixel_index;
        begin
            for (pixel_index = 0; pixel_index < PIXELS_PER_IMAGE; pixel_index++) begin
                image[pixel_index] =
                    pixel_memory[(image_index * PIXELS_PER_IMAGE) + pixel_index];
            end
        end
    endtask
    
    // Run one image through the DUT and compare its result with Python's golden prediction.
    task automatic run_one_image(input int image_index);
        begin
            // Present the complete image before the accelerator starts.
            load_image(image_index);
    
            // Reset clears all per-inference state, including nn_done.
            enable = 1'b0;
            reset  = 1'b1;
            repeat (2) @(posedge clk);
    
            // Release reset, then start one inference on a clock boundary.
            reset = 1'b0;
            @(posedge clk);
            enable = 1'b1;
    
            // Wait only for completion's rising edge, not either edge.
            @(posedge nn_done);
            #1;
    
            // Stop the accelerator before preparing another image.
            enable = 1'b0;
    
            // Count an RTL-vs-Python mismatch and show only the first few details.
            if (digit_out[3:0] !== reference_memory[image_index]) begin
                reference_mismatch_count++;
            
                if (reported_mismatch_count < MAX_MISMATCH_REPORTS) begin
                    $display("REFERENCE MISMATCH image=%0d label=%0d rtl=%0d python=%0d",
                             image_index, label_memory[image_index], digit_out,
                             reference_memory[image_index]);
                    reported_mismatch_count++;
                end
            end
            
            // Independently count whether RTL classified this image's true MNIST label.
            if (digit_out[3:0] === label_memory[image_index]) begin
                correct_prediction_count++;
            end
        end
    endtask

    initial begin
        // Initialize DUT controls before loading/running the dataset.
        enable = 1'b0;
        reset  = 1'b1;

        // Load all raw pixels, true labels, and Python reference predictions.
        $readmemh(PIXEL_FILE,     pixel_memory);
        $readmemh(LABEL_FILE,     label_memory);
        $readmemh(REFERENCE_FILE, reference_memory);

        // Clear all statistics before the full verification run.
        reference_mismatch_count = 0;
        correct_prediction_count = 0;
        reported_mismatch_count = 0;
        simulation_start_time = $time;

        // Run every MNIST test image through a reset-to-completion transaction.
        for (image_index = 0; image_index < NUM_IMAGES; image_index++) begin
            run_one_image(image_index);

            // Show progress log lines.
            if ((image_index + 1) % 1000 == 0) begin
                $display("Completed %0d / %0d images at simulation time %0t",
                         image_index + 1, NUM_IMAGES, $time);
            end
        end

        // Report whether the RTL exactly implements the Python integer reference.
        $display("RTL-vs-Python mismatches: %0d", reference_mismatch_count);

        // Report measured RTL classification accuracy against true MNIST labels.
        $display("RTL correct predictions: %0d / %0d",correct_prediction_count, NUM_IMAGES);
        $display("RTL measured accuracy: %0.2f%%",(100.0 * correct_prediction_count) / NUM_IMAGES);
        $display("Simulation duration: %0t", $time - simulation_start_time);

        $finish;

    end

endmodule
