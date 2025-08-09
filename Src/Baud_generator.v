module Baud_generator #(parameter Baud_rate=9600 ,parameter  clk_f = (1_000_000_000)/12) (input clk, rst_n ,output reg UART_clk);

  localparam Divisor = clk_f/(Baud_rate*16);           //16 oversampling for better noise immune = 542
  localparam UART_clk_f = clk_f/Divisor;               //clk_f & divisor are changeable parameter based on the design = 153751 hz
  reg [19:0] counter=0;

  always @(posedge clk , posedge rst_n)
  begin
    if(rst_n)
    begin
      counter <=0;
      UART_clk <=0;
    end
    else if (counter == Divisor-1)
    begin
      counter<=0;         //toggle the counter
      UART_clk=~UART_clk; //toggle the clk
    end
    else
      counter=counter+1;
  end

endmodule
