module UART_rx_wrapper_tb;

  parameter CLK_PERIOD = 10;
  reg UART_clk;
  reg rst_n;
  reg rx;
  reg rd_en;
  wire [11:0] rd_data;
  wire empty;

  UART_rx_wrapper uut (
    .UART_clk(UART_clk),
    .rst_n(rst_n),
    .rx(rx),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .empty(empty)
  );

  // Clock generation
  always begin
    #(CLK_PERIOD/2) UART_clk = ~UART_clk;
  end

  // Task to send a UART frame
  task send_uart_frame;
    input [7:0] data;
    input parity_type; // 0=even, 1=odd
    input stop_bit;
    integer i;
    begin
      rx = 0;  // Start bit
      #(CLK_PERIOD);

      for (i = 0; i < 8; i = i + 1) begin
        rx = data[i];
        #(CLK_PERIOD);
      end

      // Parity
      rx = (parity_type) ? ~^data : ^data;
      #(CLK_PERIOD);

      // Stop bit
      rx = stop_bit;
      #(CLK_PERIOD);
      
      // Return to idle
      rx = 1;
      #(CLK_PERIOD * 4);
    end
  endtask

  // Task to verify received data
  task verify_data;
    input [7:0] expected_data;
    input expected_PE;
    input expected_FE;
    input expected_BE;
    begin
      if (empty) begin
        $error("FIFO is empty when trying to verify data");
        $stop;
      end
      
      rd_en = 1;
      @(posedge UART_clk);
      rd_en = 0;

      #(CLK_PERIOD);
      
      $display("Verifying: Data=%h, PE=%b, FE=%b, BE=%b", 
               rd_data[7:0], rd_data[9], rd_data[8], rd_data[11]);
      
      if (rd_data[7:0] !== expected_data) begin
        $error("Data mismatch! Expected %h, got %h", expected_data, rd_data[7:0]);
      end
      
      if (rd_data[9] !== expected_PE) begin
        $error("Parity error flag mismatch! Expected %b, got %b", expected_PE, rd_data[10]);
      end
      
      if (rd_data[8] !== expected_FE) begin
        $error("Frame error flag mismatch! Expected %b, got %b", expected_FE, rd_data[8]);
      end
      
      if (rd_data[11] !== expected_BE) begin
        $error("Blank error flag mismatch! Expected %b, got %b", expected_BE, rd_data[11]);
      end
      
      #(CLK_PERIOD*2);
    end
  endtask

  // Main test sequence
  initial begin
    // Initialize
    UART_clk = 0;
    rst_n = 0;
    rx = 1;
    rd_en = 0;

    // Reset sequence
    #(CLK_PERIOD * 5);
    rst_n = 1;
    #(CLK_PERIOD * 10);

    // Test Case 1: Normal frame with odd parity
    $display("\n=== TEST 1: Normal frame (0xA5, odd parity) ===");
    send_uart_frame(8'hA5, 1'b1, 1'b1);
    #(CLK_PERIOD );
    verify_data(8'hA5, 0, 0, 0);

    // Test Case 2: Frame error (invalid stop bit)
    $display("\n=== TEST 2: Frame error (stop bit = 0) ===");
    send_uart_frame(8'h5A, 1'b1, 1'b0); // odd parity, stop=0
    #(CLK_PERIOD );
    verify_data(8'h5A, 0, 1, 0);

    // Test Case 3: Parity error
    $display("\n=== TEST 3: Parity error ===");
    send_uart_frame(8'h3C, 1'b0, 1'b1); // Should be odd parity but sending even
    #(CLK_PERIOD);
    verify_data(8'h3C, 1, 0, 0);

    // Test Case 4: Blank error (two consecutive zeros)
    $display("\n=== TEST 4: Blank error ===");
    send_uart_frame(8'h00, 1'b1, 1'b1);
    send_uart_frame(8'h00, 1'b1, 1'b1);
    #(CLK_PERIOD);
    verify_data(8'h00, 0, 0, 1);

    // Completion
    #(CLK_PERIOD * 20);
    $display("\n=== ALL TESTS COMPLETED ===");
    $stop;
  end

endmodule