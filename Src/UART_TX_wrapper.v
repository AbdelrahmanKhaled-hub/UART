module UART_tx_wrapper#( 
    parameter FIFO_WIDTH = 8,
    parameter FIFO_DEPTH = 16,
    parameter ODD_PARITY = 1  // 1 for ODD parity, 0 for EVEN)(
)(
    input wire UART_clk,
    input wire rst_n,
    input wire wr_en,
    input wire [FIFO_WIDTH-1:0] data_in,
    input wire tx_enable,
    output wire tx,
    output wire full
);

  wire [FIFO_WIDTH-1:0] data_out;
  wire tx_done_tick;
  wire empty;
  wire almost_full;
  wire almost_empty;
  wire overflow;
  wire underflow;
  wire wr_ack;
  
  // FIFO control signals
  wire rd_en = tx_done_tick;
  
  // UART control signal
  wire tx_start = ~empty & tx_enable;  // Only start when enabled

  // FIFO Instantiation with all signals connected
  Sync_FIFO_tx #(
    .FIFO_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) FIFO_tx (
    .clk(UART_clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .wr_ack(wr_ack),
    .overflow(overflow),
    .full(full),
    .empty(empty),
    .almostfull(almost_full),
    .almostempty(almost_empty),
    .underflow(underflow)
  );

  // UART Transmitter Instantiation
  UART_tx #(
    .ODD_nEVEN(ODD_PARITY)
  ) UART_tx_block (
    .UART_clk(UART_clk),
    .rst_n(rst_n),
    .tx_start(tx_start),
    .data_in(data_out),
    .tx(tx),
    .tx_done_tick(tx_done_tick)
  );

endmodule