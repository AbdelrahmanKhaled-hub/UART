module UART_tx ( 
    input wire UART_clk,
    input wire rst_n,
    input wire tx_start,
    input wire [7:0] data_in,
    output reg tx,
    output reg tx_done_tick
);

  localparam IDLE = 0;
  localparam ACTIVE = 1;
  parameter ODD_nEVEN = 1;  // 1 for ODD, 0 for EVEN

  reg cs, ns;
  reg [3:0] count, count_next;
  reg [7:0] data_buf, data_buf_next;
  reg tx_next, tx_done_tick_next;

  // State register (synchronous)
  always @(posedge UART_clk or negedge rst_n) begin
    if (!rst_n) begin
      cs <= IDLE;
      count <= 0;
      data_buf <= 0;
      tx <= 1;               // Idle high (MARK)
      tx_done_tick <= 0;
    end
    else begin
      cs <= ns;
      count <= count_next;
      data_buf <= data_buf_next;
      tx <= tx_next;
      tx_done_tick <= tx_done_tick_next;
    end
  end

  // Combinational state machine
  always @(*) begin
    // Default values
    ns = cs;
    count_next = count;
    data_buf_next = data_buf;
    tx_next = tx;
    tx_done_tick_next = 0;  // Default no pulse

    case (cs)
      IDLE: begin
        tx_next = 1;  // Maintain idle state
        if (tx_start) begin
          data_buf_next = data_in;  // Latch input data
          ns = ACTIVE;
          count_next = 0;  // Reset counter
        end
      end

      ACTIVE: begin
        case (count)
          0:  tx_next = 1'b0;          // Start bit (SPACE)
          1:  tx_next = data_buf[0];   // LSB first
          2:  tx_next = data_buf[1];
          3:  tx_next = data_buf[2];
          4:  tx_next = data_buf[3];
          5:  tx_next = data_buf[4];
          6:  tx_next = data_buf[5];
          7:  tx_next = data_buf[6];
          8:  tx_next = data_buf[7];   // MSB
          9:  tx_next = (ODD_nEVEN) ? ~^data_buf : ^data_buf;  // Parity
          10: begin
            tx_next = 1'b1;          // Stop bit (MARK)
            tx_done_tick_next = 1'b1;   // Generate done pulse
          end
          default: tx_next = 1'b1;   // Safety
        endcase

        // Advance counter if not at stop bit
        if (count < 10) begin
          ns = ACTIVE; 
          count_next = count + 1;
        end
        else begin
          count_next = 0;  // Reset after stop bit
          ns = IDLE;
        end
      end
      
      default: ns = IDLE;  // Handle undefined states
    endcase
  end
endmodule