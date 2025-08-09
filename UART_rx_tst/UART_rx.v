module UART_RX (
    input  wire       UART_clk,
    input  wire       rst_n,
    input  wire       rx_stop,       // Unused in this implementation
    input  wire       rx,
    output reg [11:0] data_out,      // {BE, OE, PE, FE, data[7:0]}
    output reg        rx_done_tick,
    output reg        BE,
    output reg        OE,
    output reg        PE,
    output reg        FE
);

  localparam IDLE   = 1'b0,
             ACTIVE = 1'b1;

  parameter ODD_nEVEN = 1; // 1=ODD, 0=EVEN

  reg        cs, ns;
  reg [3:0]  count, count_next;          // Registered count
  reg [10:0] data_buf, data_buf_next;    // Registered data buffer
  reg [1:0]  BE_count, BE_count_next;    // Registered BE counter
  reg        rx_done_tick_next;
  reg [11:0] data_out_next;
  reg        BE_next, OE_next, PE_next, FE_next;

  // Sequential State and Registers
  always @(posedge UART_clk or negedge rst_n) begin
    if (!rst_n) begin
      cs           <= IDLE;
      count        <= 0;
      data_buf     <= 0;
      data_out     <= 0;
      rx_done_tick <= 0;
      BE           <= 0;
      OE           <= 0;  // OE is not assigned; set to 0 or implement logic
      PE           <= 0;
      FE           <= 0;
      BE_count     <= 0;
    end else begin
      cs           <= ns;
      count        <= count_next;
      data_buf     <= data_buf_next;
      BE_count     <= BE_count_next;
      data_out     <= data_out_next;
      rx_done_tick <= rx_done_tick_next;
      BE           <= BE_next;
      OE           <= OE_next;  // OE is not assigned; set to 0 or implement logic
      PE           <= PE_next;
      FE           <= FE_next;
    end
  end

  // Combinational Next-State Logic
  always @(*) begin
    // Default assignments (hold current values)
    ns = cs;
    count_next = count;
    data_buf_next = data_buf;
    data_out_next = data_out;
    rx_done_tick_next = 0;
    BE_next = BE;
    OE_next = OE;  // OE is not assigned; set to 0 or implement logic
    PE_next = PE;
    FE_next = FE;
    BE_count_next = BE_count;

    case (cs)
      IDLE: begin
        if (~rx) begin  // Start bit detected (active-low) 
          data_buf_next = {rx, data_buf[10:1]};  // Shift in start bit
          count_next = 4'd1;  // Initialize count to 1
          if(rx_stop)
            OE_next =1;
          else
            OE_next =0;
          ns = ACTIVE;
        end
      end

      ACTIVE: begin
        if (count < 11) begin  // Shift in 11 bits (start + 8 data + parity + stop)
          data_buf_next = {rx, data_buf[10:1]};  // Shift right, MSB first
          count_next = count + 1;
        end else if (count == 11) begin  // Process after 11th bit
          // Check stop bit (data_buf[10] = stop bit)
          FE_next = (data_buf[10] != 1'b1);  // Frame error if stop bit != 1

          // Check parity (data_buf[9] = parity bit, data_buf[8:1] = data)
          if (ODD_nEVEN) // ODD parity
            PE_next = (data_buf[9] != ~^data_buf[8:1]); 
          else // EVEN parity
            PE_next = (data_buf[9] != ^data_buf[8:1]);

          // Blank Error (BE) detection
          if (data_buf[8:1] == 8'b0) begin
            BE_count_next = BE_count + 1;
            BE_next = (BE_count_next == 2'd2); // Set BE if 2 consecutive blank bytes
          end else begin
            BE_count_next = 0;
            BE_next = 0;
          end

          // Output data (ignore start/stop/parity bits)
          data_out_next = {BE_next, OE_next, PE_next, FE_next, data_buf[8:1]};
          rx_done_tick_next = 1;  // Pulse for 1 clock cycle
          ns = IDLE;
        end
      end
    endcase
  end
endmodule