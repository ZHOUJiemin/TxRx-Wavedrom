reg req_1_cycle_after;
reg req_2_cycle_after;
reg req_3_cycle_after;

reg last_1_cycle;
reg buf_out_cnt;
reg data_exist_in_buf;
reg buf0_is_full;
reg [2*DW-1:0]  dout_buf0;
reg [2*DW-1:0]  dout_buf1;
reg [2*DW-1:0]  dout_buf2;

wire buf_in_sel;
reg  buf_out_sel;
wire buf0_en;
wire buf1_en;
wire buf2_en;

assign buf_in_sel = sram_if_valid_out & (~ sram_if_req_out | last_1_cycle) & (~ buf_out_sel);
assign buf0_en    = ~(buf_in_sel | buf0_is_full);
assign buf1_en    = buf_in_sel & (~ buf_out_sel);
assign buf2_en    = buf_in_sel | (buf_out_sel & sram_if_req_out);

//last_1_cycle
always @ (posedge s_clk) begin
  if(rst_n == 1'b 0)
    last_1_cycle <= 1'b 0;
  else
    if(last_1_cycle == 1'b 1)
      last_1_cycle <= 1'b 0;
    else if(sram_if_req_out == 1'b 0 & sram_if_valid_out == 1'b 1)
      last_1_cycle <= 1'b 1;
    else
      last_1_cycle <= 1'b 0;
end

//data_exist_in_buf
always @ (posedge s_clk) begin
  if(rst_n == 1'b 0)
    data_exist_in_buf <= 1'b 0;
  else
    if(sram_if_req_out == 1'b 0 & sram_if_valid_out == 1'b 1)
      data_exist_in_buf <= 1'b 1;
    else if(data_exist_in_buf == 1'b 1 & sram_if_req_out == 1'b 1)
      data_exist_in_buf <= 1'b 0;
    else
      data_exist_in_buf <= data_exist_in_buf;
end

//buf_out_sel
always @ (posedge s_clk) begin
  if(rst_n == 1'b 0)
    buf_out_sel <= 1'b 0;
  else
    if(data_exist_in_buf == 1'b 1 & sram_if_req_out == 1'b 1)
      buf_out_sel <= 1'b 1;
    else if(sram_if_req_out == 1'b 1 & buf_out_cnt == 1'b 1 & buf_out_sel == 1'b 1)
      buf_out_sel <= 1'b 0;
    else
      buf_out_sel <= buf_out_sel;
end

//buf_out_cnt
always @ (posedge s_clk) begin
  if(rst_n == 1'b 0)
    buf_out_cnt <= 1'b 0;
  else
    if(sram_if_req_out == 1'b 1 & buf_out_sel == 1'b 1)
      buf_out_cnt <= buf_out_cnt + 1;
    else
      buf_out_cnt <= buf_out_cnt;
end

//buf0_is_full
always @ (posedge s_clk) begin
  if(rst_n == 1'b 0)
    buf0_is_full <= 1'b 0;
  else
    if(sram_if_req_out == 1'b 1 & buf_out_cnt == 1'b 1 & buf_out_sel == 1'b 1)
      buf0_is_full <= 1'b 0;
    else if(buf_out_sel == 1'b 1)
      buf0_is_full <= 1'b 1;
    else
      buf0_is_full <= buf0_is_full;
end

//dout_buf0
always @ (posedge s_clk) begin
  if(rst_n == 1'b 0)
    dout_buf0 <= {2*DW{1'b 0}};
  else
    if(buf0_en == 1'b 1)
      if(rd_sel == 1'b 0)
        dout_buf0 <= {dout_0[DW-1:0], dout_1[DW-1:0]};
      else
        dout_buf0 <= {dout_2[DW-1:0], dout_3[DW-1:0]};
    else
      dout_buf0 <= dout_buf0;
end

//dout_buf1
always @ (posedge s_clk) begin
  if(rst_n == 1'b 0)
    dout_buf1 <= {2*DW{1'b 0}};
  else
    if(buf1_en == 1'b 1)
      if(rd_sel == 1'b 0)
        dout_buf1 <= {dout_0[DW-1:0], dout_1[DW-1:0]};
      else
        dout_buf1 <= {dout_2[DW-1:0], dout_3[DW-1:0]};
    else
      dout_buf1 <= dout_buf1;
end

//dout_buf2
always @ (posedge s_clk) begin
  if(rst_n == 1'b 0)
    dout_buf2 <= {2*DW{1'b 0}};
  else
    if(buf2_en == 1'b 1)
      dout_buf2 <= dout_buf1;
    else
      dout_buf2 <= dout_buf2;
end

always @ (posedge s_clk) begin
  if(rst_n == 1'b 0) begin
    req_1_cycle_after <= 1'b 0;
    req_2_cycle_after <= 1'b 0;
    req_3_cycle_after <= 1'b 0;
  end
  else begin
    if(rd_sel == 1'b 0 & output_cnt == grp0_output_max - 1) begin
      req_1_cycle_after <= 1'b 0;
      req_2_cycle_after <= 1'b 0;
      req_3_cycle_after <= 1'b 0;
    end
    else if(rd_sel == 1'b 1 & output_cnt == grp1_output_max -1) begin
      req_1_cycle_after <= 1'b 0;
      req_2_cycle_after <= 1'b 0;
      req_3_cycle_after <= 1'b 0;
    end
    else begin
      req_1_cycle_after <= sram_if_req_out;
      req_2_cycle_after <= req_1_cycle_after;
      req_3_cycle_after <= req_2_cycle_after;
    end
  end
end

always @ (posedge s_clk) begin
  if(rst_n == 1'b 0)
    sram_if_valid_out <= 1'b 0;
  else
    if(sram_if_valid_out == 1'b 0 & req_3_cycle_after == 1'b 1)
      sram_if_valid_out <= 1'b 1;
    else if(sram_if_valid_out == 1'b 1 & sram_if_req_out == 1'b 1)
      if(rd_sel == 1'b 0 & output_cnt == grp0_output_max - 1)
        sram_if_valid_out <= 1'b 0;
      else if(rd_sel == 1'b 1 & output_cnt == grp1_output_max -1)
        sram_if_valid_out <= 1'b 1;
      else
        sram_if_valid_out <= sram_if_valid_out;
    else
      sram_if_valid_out <= sram_if_valid_out;
end


function [6:0] read_addr_comp;
  input [6:0] addr;
  input [2:0] r_ratio;
  input [9:0] remain_tile_num;
  case (r_ratio)
    3'b 000: read_addr_comp = addr;
    3'b 001:
      case (remain_tile_num[0])
        1'b 0: read_addr_comp = addr;
        1'b 1: read_addr_comp = (addr >> 2)*4 + addr;
        default: read_addr_comp = addr;
      endcase
    3'b 010:
      case (remain_tile_num[1:0])
        2'b 00: read_addr_comp = addr;
        2'b 01: read_addr_comp = (addr >> 1)*6 + addr;
        2'b 10: read_addr_comp = (addr >> 2)*4 + addr;
        2'b 11: read_addr_comp = divider(addr,6)*2 + addr;
        default: read_addr_comp = addr;
      endcase
    3'b 011:
      case (remain_tile_num[2:0])
        3'b 000: read_addr_comp = addr;
        3'b 001: read_addr_comp = addr*8;
        3'b 010: read_addr_comp = (addr >> 1)*6 + addr;
        3'b 011: read_addr_comp = divider(addr,3)*5 + addr;
        3'b 100: read_addr_comp = (addr >> 2)*4 + addr;
        3'b 101: read_addr_comp = divider(addr,5)*3 + addr;
        3'b 110: read_addr_comp = divider(addr,6)*2 + addr;
        3'b 111: read_addr_comp = divider(addr,7) + addr;
        default: read_addr_comp = addr;
      endcase
    3'b 100:
      case (remain_tile_num[3:0])
        4'b 0000: read_addr_comp = addr;
        4'b 0001: read_addr_comp = addr*8;
        4'b 0010: read_addr_comp = addr*8;
        4'b 0011: read_addr_comp = (addr >> 1)*6 + addr;
        4'b 0100: read_addr_comp = (addr >> 1)*6 + addr;
        4'b 0101: read_addr_comp = divider(addr,3)*5 + addr;
        4'b 0110: read_addr_comp = divider(addr,3)*5 + addr;
        4'b 0111: read_addr_comp = (addr >> 2)*4 + addr;
        4'b 1000: read_addr_comp = (addr >> 2)*4 + addr;
        4'b 1001: read_addr_comp = divider(addr,5)*3 + addr;
        4'b 1010: read_addr_comp = divider(addr,5)*3 + addr;
        4'b 1011: read_addr_comp = divider(addr,6)*2 + addr;
        4'b 1100: read_addr_comp = divider(addr,6)*2 + addr;
        4'b 1101: read_addr_comp = divider(addr,7) + addr;
        4'b 1110: read_addr_comp = divider(addr,7) + addr;
        4'b 1111: read_addr_comp = addr;
        default: read_addr_comp = addr;
      endcase
    default: read_addr_comp = addr;
  endcase
endfunction

function [6:0] divider;
  input [7:0]  numerator;
  input [2:0]  denominator;
  reg   [13:0] tmp_num;
  reg   [9:0]  tmp_deno;
  integer i;
  tmp_num = {7'b 0, numerator};
  tmp_deno= {denominator, 7'b 0};
  for(i = 0; i < 7; i = i + 1) begin
    tmp_num = tmp_num << 1;
    if(tmp_num[13:7] < tmp_deno[9:7])
      divider[6-i] = 0;
    else begin
      divider[6-i] = 1;
      tmp_num = tmp_num - tmp_deno;
    end
  end
endfunction
