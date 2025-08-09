
module Sync_FIFO_rx(clk, rst_n, wr_en, rd_en, data_in, data_out, wr_ack, overflow,full, empty, almostfull, almostempty, underflow);
  parameter FIFO_WIDTH = 12;
  parameter FIFO_DEPTH = 16;

  input wire [FIFO_WIDTH-1:0] data_in;
  input wire clk, rst_n, wr_en, rd_en;
  output reg [FIFO_WIDTH-1:0] data_out;
  output reg wr_ack, overflow,underflow;
  output wire full, empty, almostfull, almostempty;


  localparam max_fifo_addr = $clog2(FIFO_DEPTH);

  reg [FIFO_WIDTH-1:0] FIFO [FIFO_DEPTH-1:0];
  reg [max_fifo_addr-1:0] wr_ptr, rd_ptr;
  reg [max_fifo_addr:0] count;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      wr_ptr <= 0;
      underflow <= 0;
      overflow <= 0;
      wr_ack <=0;
    end
    else if (wr_en && count < FIFO_DEPTH)
    begin
      FIFO[wr_ptr] <= data_in;
      wr_ack <= 1;
      wr_ptr <= wr_ptr + 1;
      overflow <= 0;
    end
    else
    begin
      wr_ack <= 0;
      if (full & wr_en)
        overflow <= 1;
      else
        overflow <= 0;
    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_out <= 0;
      rd_ptr <= 0;
      underflow <= 0;
      overflow <= 0;
      wr_ack <=0;
    end
    else if (rd_en && count != 0)
    begin
      data_out <= FIFO[rd_ptr];
      rd_ptr <= rd_ptr + 1;
      underflow <= 0;
    end
    else
    begin
      if (empty & rd_en)
        underflow <= 1;
      else
        underflow <= 0;
    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      count <= 0;
    end
    else
    begin
      if	( ({wr_en, rd_en} == 2'b10) && !full)
        count <= count + 1;
      else if ( ({wr_en, rd_en} == 2'b01) && !empty)
        count <= count - 1;
      else if (({{wr_en, rd_en} == 2'b11}) && full)
        count <= count - 1;
      else if (({{wr_en, rd_en} == 2'b11}) && empty)
        count <= count + 1;
    end
  end

  assign full = (count == FIFO_DEPTH)? 1 : 0;
  assign empty = (count == 0)? 1 : 0;
  assign almostfull = (count == FIFO_DEPTH-1)? 1 : 0;
  assign almostempty = (count == 1)? 1 : 0;
endmodule
