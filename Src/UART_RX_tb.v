module UART_RX_tb ();
    reg       UART_clk;
    reg       rst_n;
    reg       rx;
    reg       rx_stop;
    wire [11:0] data_out;
    wire        rx_done_tick;
    wire        BE, OE, PE, FE;

    // Instantiate UART receiver
    UART_RX #(.ODD_nEVEN(1)) dut (  // Use ODD parity
        .UART_clk(UART_clk),
        .rst_n(rst_n),
        .rx_stop(rx_stop),  // Unused
        .rx(rx),
        .data_out(data_out),
        .rx_done_tick(rx_done_tick),
        .BE(BE),
        .OE(OE),
        .PE(PE),
        .FE(FE)
    );

    // Clock generation (10ns period = 100MHz)
    initial begin
        UART_clk = 0;
        forever #5 UART_clk = ~UART_clk;
    end

    // Send UART frame task (Verilog-compatible)
    task send_frame;
        input [7:0] data;
        input parity_bit;
        input stop_bit;
        integer i;  
    begin
        // Start bit
        rx = 0;
        #10;
        
        // Data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #10;
        end
        
        // Parity bit
        rx = parity_bit;
        #10;
        
        // Stop bit
        rx = stop_bit;
        #10;

        rx = 1;
        #10;
    end
    endtask

    // Main test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        rx = 1;  // Idle state
        #20;
        
        // Release reset
        rst_n = 1;
        rx_stop = 0;
        #20;
        
        // Test 1: Valid transmission (0x55)
        $display("\nTest 1: Valid transmission (0x55)");
        send_frame(8'h55, 1'b1, 1'b1);  // ODD parity for 0x55 is 1
        wait(rx_done_tick);
        #10;
        $display("Data: 0x%h, Flags: BE=%b, OE=%b, PE=%b, FE=%b",
                 data_out[7:0], BE, OE, PE, FE);
        
        // Test 2: Blank data Error (0x00) (BE)
        $display("\nTest 2: Blank data Error (0x00) (BE)");
        repeat(2) begin
        send_frame(8'h00, 1'b1, 1'b1);  // ODD parity for 0x00 is 1
        wait(rx_done_tick);
        #10;
        $display("Data: 0x%h, Flags: BE=%b, OE=%b, PE=%b, FE=%b",
                 data_out[7:0], BE, OE, PE, FE);
        end
        
        // Test 3: Frame error (missing stop bit)
        $display("\nTest 3: Frame error (missing stop bit)");
        send_frame(8'hAA, 1'b1, 1'b0);  // Invalid stop bit
        wait(rx_done_tick);
        #10;
        $display("Data: 0x%h, Flags: BE=%b, OE=%b, PE=%b, FE=%b",
                 data_out[7:0], BE, OE, PE, FE);
        
        // Test 4: Parity error
        $display("\nTest 4: Parity error");
        send_frame(8'hAA, 1'b0, 1'b1);  // Wrong parity (should be 1 for ODD)
        wait(rx_done_tick);
        #10;
        $display("Data: 0x%h, Flags: BE=%b, OE=%b, PE=%b, FE=%b",
                 data_out[7:0], BE, OE, PE, FE);
        
        // Test 5: Overrun error 
        $display("\nTest 5: Overrun error");
        rx_stop = 1;
        send_frame(8'h55, 1'b1, 1'b1);  // ODD parity for 0x55 is 1
        wait(rx_done_tick);
        #10;
        $display("Data: 0x%h, Flags: BE=%b, OE=%b, PE=%b, FE=%b",
                 data_out[7:0], BE, OE, PE, FE);
        

        
        #100;
        $display("\nAll tests completed!");
        $finish;
    end

    
    // Monitor to display received data
    always @(posedge rx_done_tick) begin
        $display("[%0t] RX Complete: Data=0x%h, BE=%b, OE=%b, PE=%b, FE=%b",
                 $time, data_out[7:0], BE, OE, PE, FE);
    end
endmodule