`timescale 1ns/1ps  // Define simulation time units

module Baud_generator_tb;

  reg clk, rst;
  wire UART_clk;

  // Instantiate DUT (Baud_generator)
  Baud_generator #(9600, 1_000_000_000 / 12) DUT (.*);

  // Clock Generation: Toggle every 12ns
  initial
  begin
    clk = 0;
    forever
      #12 clk = ~clk;
  end

  // Reset Generation
  initial
  begin
    rst = 1;   // Start with reset active
    #20;       // Hold reset for 20ns
    rst = 0;   // Deassert reset
  end

  // Stop Simulation After Some Time
  initial
  begin
    #1000;
    $stop;
  end

endmodule
