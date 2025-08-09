module UART_tx_tb;

  // Clock parameters
  parameter CLK_PERIOD = 10;  // 100 MHz
  
  // Signals
  reg UART_clk;
  reg rst_n;
  reg tx_start;
  reg [7:0] data_in;
  wire tx;
  wire tx_done_tick;
  
  // Instantiate UART transmitter
  UART_tx #(
    .ODD_nEVEN(1)  // Test with ODD parity
  ) uut (
    .UART_clk(UART_clk),
    .rst_n(rst_n),
    .tx_start(tx_start),
    .data_in(data_in),
    .tx(tx),
    .tx_done_tick(tx_done_tick)
  );
  
  // Clock generation
  initial begin
    UART_clk =0;
      forever begin
        #(CLK_PERIOD/2) UART_clk = ~UART_clk;  
      end
  end
  
  // Task to verify transmission
  task verify_transmission;
    input [7:0] expected_data;
    reg [10:0] shift_reg;
    integer i;
    begin
      // Wait for start bit
      @(negedge tx);
      
      // Capture all 11 bits (start + 8 data + parity + stop)
      for (i=0; i<11; i=i+1) begin
        @(posedge UART_clk);
        shift_reg[i] = tx;
      end
      
      // Display received frame
      $display("Time %0t: Received Frame: Start=%b, Data=%b, Parity=%b, Stop=%b",
               $time, shift_reg[0], shift_reg[8:1], shift_reg[9], shift_reg[10]);
      
      // Verify components
      if (shift_reg[0] !== 1'b0) 
        $error("Start bit error");
      
      if (shift_reg[8:1] !== expected_data)
        $error("Data error: Exp %b, Got %b", expected_data, shift_reg[8:1]);
      
      if ((^expected_data ^ uut.ODD_nEVEN) !== shift_reg[9])
        $error("Parity error: Exp %b, Got %b", (^expected_data ^ uut.ODD_nEVEN), shift_reg[9]);
      
      if (shift_reg[10] !== 1'b1)
        $error("Stop bit error");
      
      $display("Verified data: %h", expected_data);
    end
  endtask
  
  // Main test sequence
  initial begin
    // Initialize
    UART_clk = 0;
    rst_n = 0;
    tx_start = 0;
    data_in = 0;
    
    // Reset sequence
    #20 rst_n = 1;
    #10;
    
    // Test Case 1: Basic transmission
    $display("\n=== Test 1: Basic (0x55) ===");
    data_in = 8'h55;
    tx_start = 1;
    #10 tx_start = 0;
    verify_transmission(8'h55);
    wait(tx_done_tick);
    
    // Test Case 2: All zeros
    $display("\n=== Test 2: All zeros ===");
    data_in = 8'h00;
    tx_start = 1;
    #10 tx_start = 0;
    verify_transmission(8'h00);
    wait(tx_done_tick);
    
    // Test Case 3: All ones
    $display("\n=== Test 3: All ones ===");
    data_in = 8'hFF;
    tx_start = 1;
    #10 tx_start = 0;
    verify_transmission(8'hFF);
    wait(tx_done_tick);
    
    // Test Case 4: Random value
    $display("\n=== Test 4: Random (0xA7) ===");
    data_in = 8'hA7;
    tx_start = 1;
    #10 tx_start = 0;
    verify_transmission(8'hA7);
    wait(tx_done_tick);
    
    // Test Case 5: Reset during transmission
    $display("\n=== Test 5: Reset during TX ===");
    data_in = 8'hAA;
    tx_start = 1;
    #10 tx_start = 0;
    #30;  // Wait until 3rd bit
    
    rst_n = 0;
    #20 rst_n = 1;
    #100;
    
    if (tx !== 1'b1)
      $error("Line not idle after reset");
    
    $display("\nAll tests completed");
    $finish;
    $stop;
  end
  
  // Monitor TX line
  initial begin
    $monitor("Time %0t: TX=%b, Done=%b", $time, tx, tx_done_tick);
  end
  
endmodule