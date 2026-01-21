//------------------------------------------------------------
//File Name: hyperRam_top_v2
//
//Project  : any
//
//Module   : HyperRAM module 
//
//Content  : 
//
//Description : top of hyperRAM
//
//Spec.    :
//
//Author   : Hello,Panda
//------------------------------------------------------------
//History :
//2021-08-21:-Initial Creation
//2021-12-08:update to v2.0 
//------------------------------------------------------------
`timescale 1ns / 1ps

module hyperRam_top_v2(
   input  wire                       i_ref_50m
  ,output wire                       o_hram_clk
  ,output wire                       o_hram_csn
  ,output wire                       o_hram_resetn
  ,inout  wire                       io_hram_rwds
  ,inout  wire          [7 : 0]      io_hram_dq
  ,output wire                                 w_clk_200m    
  ,output wire user_clk_50
  ,output reg                                  r_reset       = 1'b1 

  ,input reset_test
  ,input  [7:0]fifo_count
  ,input  [15:0]wr_data
  ,output  r_acess_wdata_tvalid_out0
  ,input [31:0]length_file
  ,input rw_con
  ,input reset_hyram
  ,output wire              [15 : 0]           w_acess_rdata_tdata   
  ,output wire                                 w_acess_rdata_tvalid 
  ,input fifo_ready
,output w_r
);
reg r_acess_wdata_tvalid_out;

reg              [7 : 0]             r_sys_dcnt    = 8'd0 ;
reg                                  r_ref_resetn  = 1'b0 ;  
reg              [7 : 0]             r_pll_locked  = 8'd0 ;

reg              [15 : 0]            r_poweron_cnt = 16'd0;

wire                                 w_clk_50m     ;
wire                                 w_pll_locked  ; 

wire                                 w_clk_200m_135os ;
wire                                 w_clk_200m_180os ;
/************************************************************/
//part1: onchip soc clock generate
//freq : 50MHz
/************************************************************/

osc_v1 u_osc_inst(
    .hf_out_en_i                     (1'b1                   )    
   ,.hf_clk_out_o                    (w_clk_50m              )
);

always @ (posedge w_clk_50m)
begin 
	   r_sys_dcnt     <= (&r_sys_dcnt) ? r_sys_dcnt : (r_sys_dcnt + 1'b1);
	   r_ref_resetn   <= (&r_sys_dcnt) ? 1'b1 : 1'b0;
end

/*************************************************************/
//part2: generate clocks for system
//clkop:200MHz;  clkos_o: 200MHz phase offset 130 degree
/*************************************************************/ 
/*
pll_2xq_5x_dynport u_pll_tb_inst(                      
    .clki_i              (i_ref_50m             )      
   ,.rstn_i              (r_ref_resetn          )      
                                                       
   ,.clkop_o             (w_clk_200m            )      
   ,.clkos_o             (w_clk_200m_135os      )      
   ,.clkos2_o            (                      )      
   ,.clkos3_o            (                      )      
   ,.clkos4_o            (                      ) 
  // ,.clkos5_o            (                      )   
                                                       
   ,.lock_o              (w_pll_locked          )      
   ,.done_pll_init_o     (w_done_pll_init_o     )      
);

*/
pll_2xq_5x u_pll_tb_inst(
	    .clki_i(i_ref_50m), 
        .rstn_i(r_ref_resetn), 
        .clkop_o(w_clk_200m), 
        .clkos_o(w_clk_200m_135os), 
		.clkos2_o(),
        .lock_o(w_pll_locked)) ;
assign user_clk_50 = i_ref_50m;
always @ (posedge w_clk_200m)                                                   
begin                                                                           
	    r_pll_locked <= {r_pll_locked[6:0],(w_pll_locked )};//& w_done_pll_init_o)} ;  
end     
always @ (posedge w_clk_200m)                                                              
begin                                                                                      
	   if(~r_pll_locked[7]) begin                                                            
	   	 r_reset       <= 1'b1 ;                                                             
	   	 r_poweron_cnt <= 16'd0;                                                                                                                                     
	   end                                                                                   
	   else begin                                                                            
	   	 r_poweron_cnt <= (&r_poweron_cnt) ? r_poweron_cnt : (r_poweron_cnt + 1'b1);         
	   	 r_reset       <= (&r_poweron_cnt) ? 1'b0 : 1'b1;                                    
	   end                                                                                   
end   
/**************************************************************/
//part3: hyper ctrl logic
/**************************************************************/ 
localparam  ST_IDEL  = 4'b0000;                                  
localparam  ST_CMD   = 4'b0001;                                  
localparam  ST_WRITE = 4'b0010;                                  
localparam  ST_READ  = 4'b0100;                                  
localparam  ST_DUMMY = 4'b1000;                                  
                                                                 
reg               [3 : 0]            r_delay_cnt ;               
reg               [7 : 0]            r_data_cnt  ;               
reg               [3 : 0]            r_state     ;               
reg                                  r_cmd_acess_tvalid     ;    
reg                                  r_cmd_acess_rw         ;    
reg                                  r_cmd_acess_burst_type ;    
reg             [31 : 0]             r_cmd_acess_addr       ;    
reg             [7  : 0]             r_cmd_acess_len        ;    
   
reg                                  r_acess_wdata_tlast    ;    
                                                                 
    
wire                                 w_hyram_init_complate ;     
wire                                 w_cmd_acess_tready    ;     
//wire                                 w_acess_rdata_tvalid  ;     
wire                                 w_acess_rdata_tlast   ;     
wire                                 w_acess_done          ; 

assign r_acess_wdata_tvalid_out0 = r_acess_wdata_tvalid_out&&~r_acess_wdata_tlast;
reg r_acess_wdata_tvalid     ;                                                      
reg [15:0]r_acess_wdata_tdata  ;  

assign w_r = r_cmd_acess_rw;

reg rw_con_d = 0;
reg start_wr = 0;
reg r_cmd_acess_rw_d = 0;
always@(posedge w_clk_200m)
 begin 
	if(reset_hyram||r_reset)
	 begin
		rw_con_d<= 'd0;
		start_wr <= 'd0;
		r_cmd_acess_rw_d = 0;
	  end
		else begin
	rw_con_d <= rw_con;
    if(rw_con_d&&~rw_con) begin start_wr<= 'd0; end
		else if(~r_cmd_acess_rw_d&&r_cmd_acess_rw)begin start_wr<= 'd1; end
			else begin start_wr<= start_wr; end
			end
 end


always @ (posedge w_clk_200m)                                                                  
begin                                                                                          
	   if(r_reset||reset_hyram) begin                                                                    
	   	  r_data_cnt  <= 8'd0    ;                                                               
	   	  r_state     <= ST_IDEL ;                                                               
	   	  r_delay_cnt <= 4'd0    ;                                                               
	   	  r_cmd_acess_tvalid      <= 1'b0;                                                       
	   	 	r_cmd_acess_rw          <= 1'b0;                                                        
	   	 	r_cmd_acess_burst_type  <= 1'b1        ;                                               
	   	 	r_cmd_acess_addr        <= 32'h00000000;                                               
	   	 	r_cmd_acess_len         <= 8'd128       ; //32*2 byte                                  
	   	 	r_acess_wdata_tvalid    <= 1'b0 ;                                                      
	   	 	r_acess_wdata_tdata     <= 32'd0;                                                      
	   	 	r_acess_wdata_tlast     <= 1'b0 ;     
				r_acess_wdata_tvalid_out <= 'd0;                                                 
	   end                                                                                       
	   else begin                                                                                
	   	 case (r_state)                                                                          
	   	 ST_IDEL : begin                                                                         
	   	 	 if(w_hyram_init_complate) begin                                                       
	   	 	 	r_state  <=  ST_CMD ;                                                                
	   	 	 end                                                                                   
	   	 	 else begin                                                                            
	   	 	 	r_state  <= ST_IDEL ;                                                                
	   	 	 end                                                                                   
	   	 	 r_data_cnt  <= 8'd0    ;                                                              
	   	 	 r_cmd_acess_tvalid      <= 1'b0;                                                      
	   	 	 r_cmd_acess_rw          <= 1'b0;   ////////////////////////////////////////////////////////写为0 读为1，调试为1                                                   
	   	 	 r_cmd_acess_burst_type  <= 1'b1        ;                                              
	   	 	 r_cmd_acess_addr        <= 32'h00000000;                                              
	   	 	 r_cmd_acess_len         <= 8'd128       ; //32*2 byte                                 
	   	 	 r_acess_wdata_tvalid    <= 1'b0 ;                                                     
	   	 	 r_acess_wdata_tdata     <= 32'd0;                                                     
	   	 	 r_acess_wdata_tlast     <= 1'b0 ;                                                     
	   	 	 r_delay_cnt <= 4'd0    ;           
				 r_acess_wdata_tvalid_out <= 'd0;                                                      
	   	 end                                                                                     
	   	                                                                                         
	   	 ST_CMD : begin                                                                          
	   	 	 if(w_cmd_acess_tready) begin                                                          
	   	 	 	 r_cmd_acess_tvalid      <= 1'b1;                                                    
	   	 	 	 //r_cmd_acess_rw          <= 1'b0;                                                  
	   	 	 	 r_cmd_acess_burst_type  <= 1'b1;                                                    
	   	 	 	 r_cmd_acess_addr        <= r_cmd_acess_addr;                                            
	   	 	 	 r_cmd_acess_len         <= 8'd128;        
					  
				if(~r_cmd_acess_rw&&fifo_count>=64)  begin r_state                 <= ST_WRITE ;r_cmd_acess_tvalid      <= 1'b1;  r_acess_wdata_tvalid   <= 1'b0;   r_acess_wdata_tvalid_out <= 'd1;      end                                               
				   else if(r_cmd_acess_rw&&fifo_ready) begin r_state                 <= ST_READ ;r_cmd_acess_tvalid      <= 1'b1; r_acess_wdata_tvalid   <= 1'b0;   r_acess_wdata_tvalid_out <= 'd0;       end
				   else begin r_state  <= r_state ;r_cmd_acess_tvalid      <= 1'b0;  r_acess_wdata_tvalid   <= 1'b0;   r_acess_wdata_tvalid_out <= 'd0;      end
	   	 	 	 //r_state                 <= r_cmd_acess_rw ? ST_READ : ST_WRITE ;   
					// if(~start_wr&&fifo_count>=64)  begin r_cmd_acess_rw<= 0; r_state                 <= ST_WRITE ;r_cmd_acess_tvalid      <= 1'b1;  r_acess_wdata_tvalid   <= 1'b0;   r_acess_wdata_tvalid_out <= 'd1;      end  
					//	else if(r_cmd_acess_rw) begin r_cmd_acess_rw<= 1; r_state                 <= ST_READ ;r_cmd_acess_tvalid      <= 1'b1; r_acess_wdata_tvalid   <= 1'b0;   r_acess_wdata_tvalid_out <= 'd0;      end          
					//	else begin r_cmd_acess_rw<= r_cmd_acess_rw; r_state  <= r_state ;r_cmd_acess_tvalid      <= 1'b0;  r_acess_wdata_tvalid   <= 1'b0;   r_acess_wdata_tvalid_out <= 'd0;      end                 
	   	 	 end                                                                                   
	   	 	 else begin                                                                            
	   	 	 	  r_cmd_acess_tvalid      <= 1'b0;                                                   
	   	 	 	  r_cmd_acess_burst_type  <= 1'b1;                                                   
	   	 	 	  r_cmd_acess_addr        <= reset_test?0:r_cmd_acess_addr;                                           
	   	 	 	  r_cmd_acess_len         <= 8'd128;                                                 
	   	 	 	  r_state                 <= ST_CMD ; 
					   r_acess_wdata_tvalid_out <= 'd0;                                                  
	   	 	 end                                                                                   
	   	 	 r_delay_cnt <= 4'd0    ;                                                              
	   	 end                                                                                     
	   	                                                                                         
	   	                                                                                         
	   	 ST_WRITE : begin                                                                        
	   	 	   r_cmd_acess_tvalid     <= 1'b0;                                                     
	   	 	   r_acess_wdata_tvalid   <= 1'b1;       
				r_acess_wdata_tvalid_out <= 'd1;                                                 
	   	 	   r_data_cnt             <= r_acess_wdata_tvalid ? (r_data_cnt + 1'b1) :  r_data_cnt ;
	   	 	   if(r_data_cnt == 8'd62) begin                                                       
	   	 	   	 r_acess_wdata_tlast  <= 1'b1;                                                     
	   	 	   	 r_state              <= ST_DUMMY ;                                                
	   	 	   end                                                                                 
	   	 	   r_acess_wdata_tdata    <= wr_data;//r_acess_wdata_tvalid ?                                    
	   	 	                            //({r_data_cnt[7:0],r_data_cnt[7:0]} + 16'h0101) : 16'hC055; 
	   	 end                                                                                     
	   	                                                                                         
	   	 ST_READ : begin                                                                         
	   	 	  r_data_cnt   <=  (&r_data_cnt) ? r_data_cnt : (r_data_cnt + 1'b1);            
	   	 	  if(r_data_cnt == 8'd63) begin                                                        
	   	 	  	 r_state   <= ST_DUMMY ;                                                           
	   	 	  end                                                                                  
	   	 	  r_cmd_acess_tvalid <= 1'b0;    
				  r_acess_wdata_tvalid_out <= 'd0;                                                         
	   	 end                                                                                     
	   	                                                                                         
	   	 ST_DUMMY : begin                                                                        
	   	 	  r_data_cnt  <= 8'd0    ;               
				  r_acess_wdata_tvalid_out <= 'd0;                                                 
	   	 	  r_cmd_acess_tvalid      <= 1'b0;                                                     
	   	 	  //r_cmd_acess_rw          <= (~r_cmd_acess_rw);                                      
	   	 	  r_cmd_acess_burst_type  <= 1'b1        ;                                             
	   	 	  //r_cmd_acess_addr        <= 32'h00000000;                                             
	   	 	  r_cmd_acess_len         <= 8'd128       ; //32*2 byte                                
	   	 	  r_acess_wdata_tvalid    <= 1'b0 ;                                                    
	   	 	  r_acess_wdata_tdata     <= wr_data;                                                    
	   	 	  r_acess_wdata_tlast     <= 1'b0 ;                                                    
	   	 	 // if(w_cmd_acess_tready) begin                                                         
	   	 	 // 	r_delay_cnt  <= (&r_delay_cnt) ? r_delay_cnt : (r_delay_cnt + 1'b1);               
	   	 	 // 	if(&r_delay_cnt)  begin 


			  if(w_acess_done) begin   
				
				if(~r_cmd_acess_rw) begin   
					r_state  <= ST_CMD;   
			       if(r_cmd_acess_addr >= length_file-128) begin                                                           
					r_cmd_acess_rw          <= (~r_cmd_acess_rw);   r_cmd_acess_addr        <= 32'h00000000;        end
					
			       else begin r_cmd_acess_rw          <= (r_cmd_acess_rw); r_cmd_acess_addr        <= r_cmd_acess_addr + 32'd128;   end                          
				 end 
				 else begin 
					r_state  <= ST_CMD;   
					if(r_cmd_acess_addr >= length_file-128) begin                                                           
						   r_cmd_acess_addr        <= 32'h00000000;        end
						
				  else begin  r_cmd_acess_addr        <= r_cmd_acess_addr + 32'd128;   end          

				  end 
				end
	   	 	//    if(w_acess_done) begin                                                            
	   	 	//  	   r_state  <= ST_CMD;                                                             
	   	 	//  	   r_cmd_acess_rw          <= (~r_cmd_acess_rw);                                   
	   	 	//  	end                                                                                
	   	 	 // end                                                                                  
	   	 end                                                                                     
	   	                                                                                         
	   	 default : begin                                                                         
	   	 	  r_data_cnt  <= 8'd0    ;                                                             
	   	 	  r_cmd_acess_tvalid      <= 1'b0;  
				  r_acess_wdata_tvalid_out <= 'd0;                                                      
	   	 	  r_cmd_acess_rw          <= 1'b0;                                                     
	   	 	  r_cmd_acess_burst_type  <= 1'b1        ;                                             
	   	 	  r_cmd_acess_addr        <= 32'h00000000;                                             
	   	 	  r_cmd_acess_len         <= 8'd128       ; //32*2 byte                                
	   	 	  r_acess_wdata_tvalid    <= 1'b0 ;                                                    
	   	 	  r_acess_wdata_tdata     <= 32'd0;                                                    
	   	 	  r_acess_wdata_tlast     <= 1'b0 ;                                                    
	   	 	  r_state  <= ST_IDEL ;                                                                
	   	 	  r_delay_cnt <= 4'd0    ;                                                             
	   	 end                                                                                     
	     endcase                                                                                 
	   end                                                                                       
end  
reg r_acess_wdata_tvalid_d;
always@(posedge w_clk_200m) begin 
	if(r_reset) begin r_acess_wdata_tvalid_d<= 'd0; end
    else  begin r_acess_wdata_tvalid_d<= r_acess_wdata_tvalid; end
end

/**************************************************************/
//part4: hyperRAM PHY
/**************************************************************/
hyperRam_v3 #(
   .DELAY_VALUE                              (0                         )
  ,.DEL_MODE                                 ("SCLK_ALIGNED"            )
)u_hyperRam_inst(
   .i_hyclk                                  (w_clk_200m                )      
  ,.i_hyclk_90os                             (w_clk_200m_135os          )       
  ,.i_hyreset                                (r_reset                 )      
  ,.reset_hyram                              (reset_hyram)        
                                                    
  ,.o_hyram_cs                               (o_hram_csn                )           
  ,.o_hyram_ckp                              (o_hram_clk                )  
  ,.o_hyram_ckn                              (                          )
  ,.o_hyram_resetn                           (o_hram_resetn             )           
                           
  ,.io_hyram_rwds                            (io_hram_rwds              )            
  ,.io_hyram_dq                              (io_hram_dq                )  
  
  ,.i_reg0_write_value                       (16'hEF2C                  ) 
            
                           
  ,.i_acess_tvalid                           (r_cmd_acess_tvalid        )       
  ,.o_acess_tready                           (w_cmd_acess_tready        )                          
  ,.i_acess_rw                               (r_cmd_acess_rw                    )//r_cmd_acess_rw            )                          
  ,.i_acess_burst_type                       (r_cmd_acess_burst_type    )                       
  ,.i_acess_addr                             (r_cmd_acess_addr          )       
  ,.i_acess_len                              (r_cmd_acess_len           ) 
  ,.o_acess_done                             (w_acess_done              )
                           
  ,.i_acess_wdata_tvalid                     (r_acess_wdata_tvalid_d      )   
  ,.o_acess_wdata_tready                     (                          )   
  ,.i_acess_wdata_tdata                      (r_acess_wdata_tdata       )   
  ,.i_acess_wdata_tlast                      (r_acess_wdata_tlast       )   
  ,.o_acess_wdata_err                        (                          )   
                           
  ,.o_acess_rdata_tvalid                     (w_acess_rdata_tvalid      )  
  ,.i_acess_rdata_tready                     (1'b1                      )  
  ,.o_acess_rdata_tdata                      (w_acess_rdata_tdata       )  
  ,.o_acess_rdata_tlast                      (w_acess_rdata_tlast       )  
                           
  ,.o_hyram_init_complate                    (w_hyram_init_complate     )    
);  
                                                                       
endmodule 