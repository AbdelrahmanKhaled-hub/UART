module UART_rx_wrapper#(
    parameter FIFO_WIDTH = 12,
    parameter FIFO_DEPTH = 16,
    parameter ODD_PARITY = 1  // 1 for ODD parity, 0 for EVEN)(
)(
    input wire UART_clk,
    input wire rst_n,
    input wire rx,
    input wire rd_en,
    output wire [FIFO_WIDTH-1:0] rd_data,
    output wire empty
);
    // FIFO status signals (unused in this wrapper)
    wire wr_ack, overflow, almostfull, full, almostempty, underflow;

    // Error flags from UART receiver
    wire rx_done_tick;
    wire BE, OE, PE, FE;
    
    // FIFO control signals
    wire wr_en = rx_done_tick;  // Write when valid data received
    wire rx_stop = full;
    
    // Data from UART receiver (includes error flags)
    wire [11:0] uart_data_out;
    

    // Instantiate FIFO
    Sync_FIFO_rx FIFO_rx (
        .clk(UART_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(uart_data_out),
        .data_out(rd_data),
        .wr_ack(wr_ack),          // Unused
        .overflow(overflow),      // Unused
        .full(full),
        .empty(empty),
        .almostfull(almostfull),  // Unused
        .almostempty(almostempty),// Unused
        .underflow(underflow)     // Unused
    );
    
    // Instantiate UART receiver
    UART_rx UART_rx_block (
        .UART_clk(UART_clk),
        .rst_n(rst_n),
        .rx_stop(full),           // Stop receiving when FIFO is full
        .rx(rx),
        .data_out(uart_data_out), // {BE, OE, PE, FE, data[7:0]}
        .rx_done_tick(rx_done_tick),
        .BE(BE),
        .OE(OE),
        .PE(PE),
        .FE(FE)
    );
    

endmodule