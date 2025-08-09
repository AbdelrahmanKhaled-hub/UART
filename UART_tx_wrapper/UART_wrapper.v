module UART_wrapper #(
    parameter FIFO_WIDTH = 8,
    parameter FIFO_DEPTH = 16,
    parameter ODD_PARITY = 1  // 1 for ODD parity, 0 for EVEN
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire rx,
    input wire rd_en,
    input wire [FIFO_WIDTH-1:0] data_in,
    input wire tx_enable,
    output wire tx,
    output wire full,
    output wire [11:0] rd_data,
    output wire empty
);

    reg UART_clk;

    // Baud generator instantiation
    Baud_generator #(
        .BAUD_RATE(9600),
        .CLOCK_RATE((1_000_000_000)/12)  // Assuming 83.33 MHz clock
    ) UART_clk_generator (
        .clk(clk),
        .rst_n(rst_n),
        .baud_clk(UART_clk)
    );

    // Transmitter instantiation
    UART_tx_wrapper #(
        .FIFO_WIDTH(FIFO_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .ODD_PARITY(ODD_PARITY)
    ) tx (
        .UART_clk(UART_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .data_in(data_in),
        .tx_enable(tx_enable),
        .tx(tx),
        .full(full)
    );

    // Receiver instantiation
    UART_rx_wrapper #(
        .FIFO_WIDTH(12),  // Note: Different from tx FIFO width
        .FIFO_DEPTH(FIFO_DEPTH),
        .ODD_PARITY(ODD_PARITY)
    ) rx (
        .UART_clk(UART_clk),
        .rst_n(rst_n),
        .rx(rx),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty)
    );

endmodule