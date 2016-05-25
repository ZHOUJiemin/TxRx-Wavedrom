module o_ptg_m_t2r3_intr_gen(//System
                             input          s_clk,
                             input          rst_n,
                             //Header
                             input [7:0]    hdr_img_type,
                             input [2:0]    hdr_pkt_type,
                             input [11:0]   hdr_x_cord,
                             input [11:0]   hdr_y_cord,
                             //Reigster
                             input [14:5]   reg_page_width,
                             input [14:5]   reg_page_height,
                             input [2:0]    reg_resize_ratio,
                             input [2:0]    reg_img_comp_num,
                             input          reg_z_exsit,
                             input [1:0]    reg_z_proc,
                             //Y Bus Monitor
                             input          intr_yif_tsp,
                             input          intr_yif_srdyp,
                             //Output
                             output         intr_page_finish,
                             output         intr_err_pkt_type,
                             output         intr_err_img_type,
                             output         intr_err_page_size);

  //wire variables
  //none

  //reg variables
  reg [2:0]  comp_num_with_z;

  reg [17:0] tx_cnt;
  reg [17:0] tx_cnt_max;
  reg [14:0] line_cnt;
  reg [14:0] line_cnt_max;

  reg intr_page_finish_ff;
  reg intr_err_pkt_type_ff;
  reg intr_err_img_type_ff;
  reg intr_err_page_size_ff;

  //continuous assignment
  assign intr_page_finish = intr_page_finish_ff;
  assign intr_err_pkt_type = intr_err_pkt_type_ff;
  assign intr_err_img_type = intr_err_img_type_ff;
  assign intr_err_page_size = intr_err_page_size_ff;

  //process assignment
  //intr_err_pkt_type
  always @ (posedge s_clk) begin
    if(rst_n == 1'b 0)
      intr_err_pkt_type_ff <= 1'b 0;
    else
      if(hdr_pkt_type == 3'b 001)
        intr_err_pkt_type_ff <= intr_err_page_size_ff;
      else
        intr_err_pkt_type_ff <= 1'b 1;
  end

  //intr_err_img_type
  always @ (posedge s_clk) begin
    if(rst_n == 1'b 0)
      intr_err_img_type_ff <= 1'b 0;
    else
      case (hdr_img_type)
        8'b 00000000: intr_err_img_type_ff <= intr_err_page_size_ff;

        default: intr_err_img_type_ff <= 1'b 1;
      endcase
  end

  //intr_err_page_size
  always @ (posedge s_clk) begin
    if(rst_n == 1'b 0)
      intr_err_page_size_ff <= 1'b 0;
    else
      if(hdr_x_cord >= reg_page_width | hdr_y_cord >= reg_page_height)
        intr_err_page_size_ff <= 1'b 1;
      else
        intr_err_page_size_ff <= intr_err_page_size_ff;
  end

  //intr_page_finish
  always @ (posedge s_clk) begin
    if(rst_n == 1'b 0)
      intr_page_finish_ff <= 1'b 0;
    else
      if(line_cnt == line_cnt_max)
        intr_page_finish_ff <= 1'b 1;
      else
        intr_page_finish_ff <= intr_page_finish_ff;
  end

  //line_cnt
  always @ (posedge s_clk) begin
    if(rst_n == 1'b 0)
      line_cnt <= 10'd 0;
    else
      if(intr_yif_tsp == 1'b 1 & intr_yif_srdyp == 1'b 1 & tx_cnt == tx_cnt_max - 1)
        line_cnt <= line_cnt + 1;
  end

  //line_cnt_max
  always @ ( * ) begin
    case (reg_resize_ratio)
      3'b 000: line_cnt_max = {reg_page_height, 5'b 0};
      3'b 001: line_cnt_max = {1'b 0, reg_page_height, 4'b 0};
      3'b 010: line_cnt_max = {2'b 0, reg_page_height, 3'b 0};
      3'b 011: line_cnt_max = {3'b 0, reg_page_height, 2'b 0};
      3'b 100: line_cnt_max = {4'b 0, reg_page_height, 1'b 0};
      default: line_cnt_max = {reg_page_height, 5'b 0};
    endcase
  end

  //tx_cnt
  always @ (posedge s_clk) begin
    if(rst_n == 1'b 0)
      tx_cnt <= 18'd 0;
    else
      if(intr_yif_tsp == 1'b 1 & intr_yif_srdyp == 1'b 1)
        if(tx_cnt == tx_cnt_max -1)
          tx_cnt <= 18'd 0;
        else
          tx_cnt <= tx_cnt + 1;
      else
        tx_cnt <= tx_cnt;
  end

  //tx_cnt_max
  always @ ( * ) begin
    case (reg_resize_ratio)
      3'b 000: tx_cnt_max = reg_page_width*comp_num_with_z;
      3'b 001: tx_cnt_max = (reg_page_width*comp_num_with_z + 1) >> 1;
      3'b 010: tx_cnt_max = (reg_page_width*comp_num_with_z + 3) >> 2;
      3'b 011: tx_cnt_max = (reg_page_width*comp_num_with_z + 7) >> 3;
      3'b 100: tx_cnt_max = (reg_page_width*comp_num_with_z + 15)>> 4;
      default: tx_cnt_max = reg_page_width*comp_num_with_z;
    endcase
  end

  //comp_num_with_z
  always @ ( * ) begin
    case (reg_z_proc)
      2'b 00: comp_num_with_z = reg_img_comp_num + reg_z_exsit;
      2'b 01: comp_num_with_z = reg_img_comp_num + 1;
      2'b 10: comp_num_with_z = reg_img_comp_num;
      default: comp_num_with_z = reg_img_comp_num + reg_z_exsit;
    endcase
  end

endmodule
