module UART_tx_wrapper_tb;

    // Parameters
    parameter CLK_PERIOD = 10;       // 100MHz clock (10ns period)
    parameter FIFO_DEPTH = 16;       // Match wrapper parameter
    
    // System Signals
    reg UART_clk;
    reg rst_n;
    
    // Test Control
    integer test_num;
    integer error_count;
    integer i = 0;
    
    // DUT Interface
    reg tx_enable;
    reg wr_en;
    reg [7:0] data_in;
    wire tx;
    wire full;
    
    // Instantiate DUT
    UART_tx_wrapper dut (
        .UART_clk(UART_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .data_in(data_in),
        .tx_enable(tx_enable),
        .tx(tx),
        .full(full)
    );
    
    // Clock Generation
    initial begin
        UART_clk = 0;
        forever #(CLK_PERIOD/2) UART_clk = ~UART_clk;
    end
    
    // Task to write data to FIFO
    task write_fifo;
        input [7:0] data;
        begin
            data_in = data;
            wr_en = 1;
            @(posedge UART_clk);
            wr_en = 0;
            wait(dut.wr_ack);  // Wait for write acknowledge
            #(CLK_PERIOD*2);   // Small delay after write
        end
    endtask
    
    // Task to verify transmission
    task verify_tx;
        input [7:0] expected_data;
        begin
            // Wait for transmission to start
            wait(dut.UART_tx_block.cs == dut.UART_tx_block.ACTIVE);
            
            // Wait for transmission to complete
            wait(dut.UART_tx_block.tx_done_tick);
            
            // Verify data from FIFO
            if (dut.data_out !== expected_data) begin
                $error("Data mismatch! Expected %h, got %h", 
                      expected_data, dut.data_out);
                error_count = error_count + 1;
            end
            else begin
                $display("Verified transmission of %h", expected_data);
            end
        end
    endtask
    
    // Main Test Sequence
    initial begin
        // Initialize
        tx_enable = 1;
        test_num = 0;
        error_count = 0;
        wr_en = 0;
        data_in = 0;
        rst_n = 0;
        
        // Reset sequence
        $display("\nApplying reset...");
        #20 rst_n = 1;
        #100;
        
        // Test Case 1: Single byte transmission
        test_num = test_num + 1;
        $display("\nTest %0d: Single byte transmission", test_num);
        write_fifo(8'hA5);
        #200;
        verify_tx(8'hA5);
        
        // Test Case 2: Back-to-back transmissions
        test_num = test_num + 1;
        $display("\nTest %0d: Back-to-back transmissions", test_num);
        write_fifo(8'h5A);
        write_fifo(8'h3C);
        #200;
        verify_tx(8'h5A);
        verify_tx(8'h3C);
        
        // Test Case 3: FIFO fill test
        test_num = test_num + 1;
        $display("\nTest %0d: FIFO fill test", test_num);

        // First pause any transmissions by waiting for idle
        wait(dut.UART_tx_block.cs == dut.UART_tx_block.IDLE);

        // Disable transmissions during fill
        tx_enable = 0;
        
        // Fill FIFO
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            write_fifo(i[7:0]);
        end

        // Verify FIFO is full
        if (!full) begin
            $error("FIFO should be full!");
            error_count = error_count + 1;
        end

        // Re-enable transmissions
        tx_enable = 1;
        #200;
        // Verify all transmissions
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            verify_tx(i[7:0]);
        end
        // Completion
        #100;
        $display("\nTestbench completed");
        $display("Tests run: %0d", test_num);
        $display("Errors found: %0d", error_count);
        if (error_count == 0) begin
            $display("All tests passed!");
        end
        $finish;
        $stop;
    end
    
    // Monitor FIFO status
    initial begin
        forever begin
            @(posedge UART_clk);
            $display("[%0t] FIFO Status: empty=%b, full=%b, count=%0d, overflow=%b, underflow=%b",
                    $time, dut.empty, full, dut.FIFO_tx.count, dut.overflow, dut.underflow);
        end
    end
    
    // Monitor UART transmitter state
    initial begin
        forever begin
            @(posedge UART_clk);
            if (dut.UART_tx_block.tx_done_tick) begin
                $display("[%0t] UART Transmission Complete", $time);
            end
        end
    end
    
endmodule