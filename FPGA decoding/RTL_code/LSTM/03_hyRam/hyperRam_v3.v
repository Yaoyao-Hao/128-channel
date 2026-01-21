//------------------------------------------------------------
//File Name: hyperRam_v3
//
//Project  :  
//
//Module   : top module 
//
//Content  : none
//
//Description : phy of hyperRam
//             
//Spec.    : none
//
//Author   : Hello,Panda
//------------------------------------------------------------
//History :
//20200804: V1.0 -Initial Creation 
//20211116: V2.0
//20211211: V3.0
//------------------------------------------------------------
`timescale 1ns / 1ps

module hyperRam_v3 #(
   parameter integer    DELAY_VALUE  = 1 
  ,parameter            DEL_MODE     = "USER_DEFINED"
)(
    input wire                                          i_hyclk       //200MHz                                                         
   ,input wire                                          i_hyclk_90os  //200MHz 90 degree phase 
   ,input wire                                          i_hyreset     //Reset     
   ,input reset_hyram                                                  
   //phy io                                                                                                                         
   ,output wire                                         o_hyram_cs                                                                  
   ,output wire                                         o_hyram_ckp   
   ,output wire                                         o_hyram_ckn                                                              
   ,output wire                                         o_hyram_resetn                                                               
   ,inout  wire                                         io_hyram_rwds                                                               
   ,inout  wire                  [7 : 0]                io_hyram_dq                                                                 
   //init register value                                                                                                            
   ,input  wire                  [15: 0]                i_reg0_write_value  //constance value                                       
   //addr port                                                                                                                      
   ,input  wire                                         i_acess_tvalid      //acess request,it can be looked as write address       
   ,output wire                                         o_acess_tready      //i_acess_tvalid & o_acess_tready start a acess pipe    
   ,input  wire                                         i_acess_rw          //1-read ; 0-write                                      
   ,input  wire                                         i_acess_burst_type  //1-line  ;0-wapper                                     
   ,input  wire                  [31 : 0]               i_acess_addr        //A31-A0                                                
   ,input  wire                  [7  : 0]               i_acess_len         //fixed, byte 32,64 or 128                              
   ,output wire                                         o_acess_done                                                                
   //data write port                                                                                                                
   ,input  wire                                         i_acess_wdata_tvalid                                                        
   ,output wire                                         o_acess_wdata_tready                                                        
   ,input  wire                  [15 : 0]               i_acess_wdata_tdata                                                         
   ,input  wire                                         i_acess_wdata_tlast                                                         
   ,output wire                                         o_acess_wdata_err                                                           
   //data read  port                                                                                                                
   ,output wire                                         o_acess_rdata_tvalid                                                        
   ,input  wire                                         i_acess_rdata_tready                                                        
   ,output wire                  [15 : 0]               o_acess_rdata_tdata                                                         
   ,output wire                                         o_acess_rdata_tlast                                                         
   //init status                                                                                                                    
   ,output wire                                         o_hyram_init_complate                                                       
   ,output wire                                         o_readtimeout_err 
);

reg                                                     r_hyper_busy=1'b1 ;
reg                [4 : 0]                              r_state = 5'd0    ;
reg                [15: 0]                              r_wait_stable_cnt = 16'd0;
reg                                                     r_hyper_init_start = 1'b0; 
reg                                                     r_hyper_acess_rw   = 1'b0;      
reg                                                     r_hyper_acess_burst_type = 1'b0;
reg                [31 : 0]                             r_hyper_acess_addr = 32'd0;      
reg                [7  : 0]                             r_hyper_acess_len  = 8'd0 ; 
reg                [6  : 0]                             r_acess_wdata_cnt  = 7'd0 ;
reg                                                     r_acess_wdata_err  = 1'b0 ;
reg                [7  : 0]                             r_hyper_acess_cnt  = 8'd0 ;
reg                                                     r_hyram_resetn     = 1'b0 ;
reg                                                     r_hyram_cs         = 1'b1 ;
reg                [15 : 0]                             r_hyram_dout       = 16'd0; 
reg                                                     r_hyram_data_tri   =  1'b1; 
reg                                                     r_hyram_rwds_tri   =  1'b1; 
reg                                                     r_hyram_read_pipe  =  1'b0; 
reg                [6 : 0]                              r_hyram_rdcnt      =  7'd0;
reg                                                     r_wfifo_rden       =  1'b0;
reg                                                     r_wfifo_reset      =  1'b1; 

reg                                                     r_rdata_tvalid     =  1'b0 ;
reg                                                     r_rdata_tlast      =  1'b0 ;
reg                [15 : 0]                             r_rdata_tdata      =  16'd0;

reg                                                     r_hyram_init_complate = 1'b0;
reg                                                     r_readtimeout_err     = 1'b0   ; 
reg                                                     r_acess_done          = 1'b0   ;
reg                   [2 : 0]                           r_done_delay          = 2'b00  ;
reg                   [1 : 0]                           r_rwds_iob_din        = 2'b00  ;
reg                   [15 : 0]                          r_dq_iob_din          = 16'd0  ;
reg                   [1 : 0]                           r_p2_rwds_data        = 2'b00  ;
reg                   [15: 0]                           r_p2_dq_data          = 16'd0  ;
  
wire                                                    w_hyper_acess_tready;
wire                                                    w_hyram_fifo_alfull ;
wire                   [15 : 0]                         w_hyram_fifo_rdata  ; 
wire                                                    w_hyram_fifo_wren   ; 
wire                   [15 : 0]                         w_hyram_rdata       ;  
wire                                                    w_hyper_clk_do      ; 
wire                                                    w_hyper_rwds_iob    ;
wire                                                    w_hyper_rwds_delay  ;
wire                   [1 : 0]                          w_hyper_rwds_do     ;  
wire                                                    w_acess_wdata_tready; 
wire                   [7 : 0]                          w_hyram_rdtotal     ;                                   

localparam            ST_IDEL  =  5'b00000;  //idel
localparam            ST_INIT  =  5'b00001;  //inital pipe
localparam            ST_READ  =  5'b00010;  //read data from HyperRAM
localparam            ST_WRITE =  5'b00100;  //write data to HyperRAM
localparam            ST_WCMD  =  5'b01000;  //Wait Commond comes
localparam            ST_DONE  =  5'b10000;  //Wait Write or Read Done

assign    w_hyper_acess_tready  = (~r_hyper_busy)     ;  
assign    o_acess_tready        = w_hyper_acess_tready;
assign    o_hyram_resetn        = r_hyram_resetn     ;//////////////////////////
assign    o_acess_wdata_tready  = (~w_hyram_fifo_alfull) ;
assign    w_acess_wdata_tready  = (~w_hyram_fifo_alfull) ;   
assign    w_hyram_fifo_wren     = (i_acess_wdata_tvalid & (~w_hyram_fifo_alfull)) ; 
assign    o_acess_rdata_tvalid  = r_rdata_tvalid;
assign    o_acess_rdata_tlast   = r_rdata_tlast ;
assign    o_acess_rdata_tdata   = r_rdata_tdata ;  
assign    o_hyram_init_complate = r_hyram_init_complate ;     
assign    o_acess_wdata_err     = r_acess_wdata_err ;         
assign    o_readtimeout_err     = r_readtimeout_err ;         
assign    o_acess_done          = r_acess_done      ;  
assign    w_hyram_rdtotal       = (r_hyper_acess_len[7:1] + 4'd15) ;//(r_hyper_acess_len[7:1] + 4'd15) ;
/*********************************************************************/
//sample write/read parameter and others
/*********************************************************************/
always @ (posedge i_hyclk)    
begin                         
	  if(i_hyreset||reset_hyram) begin      
	  	 r_wait_stable_cnt  <= 16'd0;
	  	 r_hyper_init_start <= 1'b0 ; 
	  	 r_hyram_resetn     <= 1'b0 ;
	  end
	  else begin 
	     r_wait_stable_cnt   <= (&r_wait_stable_cnt) ? r_wait_stable_cnt : (r_wait_stable_cnt + 1'b1);
	     //wait 160us,after stable,then start hyperRAM intial
	     r_hyper_init_start  <= (r_wait_stable_cnt == 16'd65534)  ? 1'b1 : 1'b0; 	
	     r_hyram_resetn      <= (r_wait_stable_cnt <= 16'd32767)  ? 1'b0 : 1'b1;
	  end
end    

always @ (posedge i_hyclk) 
begin                      
	  if(i_hyreset||reset_hyram) begin 
	     r_hyper_acess_rw         <= 1'b0;       
	     r_hyper_acess_burst_type <= 1'b0; 
	     r_hyper_acess_addr       <= 32'd0;      
	     r_hyper_acess_len        <= 8'd0 ;      	
	  end
	  else begin 
	  	 if(w_hyper_acess_tready & i_acess_tvalid) begin 
	  	 	 r_hyper_acess_rw         <= i_acess_rw         ;
	  	 	 r_hyper_acess_burst_type <= i_acess_burst_type ;
	  	 	 r_hyper_acess_addr       <= i_acess_addr       ;
	  	 	 r_hyper_acess_len        <= i_acess_len        ; //double sample rate,div2
	  	 end                           
	  	 else begin 
	  	 	 r_hyper_acess_rw         <=   r_hyper_acess_rw        ;
	  	 	 r_hyper_acess_burst_type <=   r_hyper_acess_burst_type;
	  	 	 r_hyper_acess_addr       <=   r_hyper_acess_addr      ;
	  	 	 r_hyper_acess_len        <=   r_hyper_acess_len       ;
	  	 end
	  end
end      

always @ (posedge i_hyclk)  
begin                       
	  if(i_hyreset) begin 
	  	r_acess_wdata_cnt  <= 7'd0;
	  	r_acess_wdata_err  <= 1'b0;
	  end
	  else begin 
	  	 if(w_hyper_acess_tready & i_acess_tvalid) begin 
	  	 	  r_acess_wdata_cnt  <= 7'd0;
	  	 	  r_acess_wdata_err  <= 1'b0;
	  	 end         
	  	 else begin 
	  	 	  if(i_acess_wdata_tvalid & w_acess_wdata_tready) begin 
	  	 	  	r_acess_wdata_cnt <= (&r_acess_wdata_cnt) ? r_acess_wdata_cnt : (r_acess_wdata_cnt  + 1'b1);
	  	 	  	r_acess_wdata_err <= (i_acess_wdata_tlast & (r_acess_wdata_cnt != (r_hyper_acess_len[7:1]-1'b1))) ? 1'b1 : 1'b0;	
	  	 	  end
	  	 	  else begin 
	  	 	  	r_acess_wdata_cnt <= r_acess_wdata_cnt;    
	  	 	  	r_acess_wdata_err <= 1'b0;
	  	 	  end
	  	 end	
	  end
end 
/****************************************************/
//main state
/****************************************************/
always @ (posedge i_hyclk)      
begin                      
	  if(i_hyreset) begin 
	  	 r_state       <=  ST_IDEL  ;
	  	 r_hyper_busy  <=  1'b1     ;
	  	 r_hyper_acess_cnt <= 8'd0  ; 
	  	 r_hyram_cs        <= 1'b1  ;
	  	 r_hyram_dout      <= 16'd0 ;   
	  	 r_hyram_data_tri  <= 1'b1  ; 	
	  	 r_hyram_rwds_tri  <= 1'b1  ; 
	  	 r_hyram_read_pipe <= 1'b0  ;
	  	 r_wfifo_reset     <= 1'b1  ; 
	  	 r_hyram_init_complate <= 1'b0; 
	  	 r_done_delay      <= 3'b000 ;
	  end
	  else begin    
	  	case (r_state)
	  	
	  	ST_IDEL : begin 
	  		if(r_hyper_init_start) begin 
	  			 r_state  <=  ST_INIT ;
	  		end
	  		r_hyper_busy      <= 1'b1 ;
	  		r_hyper_acess_cnt <= 8'd0 ;
	  		r_hyram_dout      <= 16'd0;
	  		r_hyram_data_tri  <= 1'b1 ; 
	  		r_hyram_cs        <= 1'b1 ;
	  		r_wfifo_rden      <= 1'b0 ;  
	  		r_hyram_rwds_tri  <= 1'b1 ;
	  		r_hyram_init_complate <= 1'b0;  
	  		r_done_delay          <= 3'b000 ;
	  		r_hyram_read_pipe     <= 1'b0 ;
	  	end
	  	
	    ST_INIT : begin 
	    	r_hyper_acess_cnt <= (&r_hyper_acess_cnt) ? r_hyper_acess_cnt : (r_hyper_acess_cnt + 1'b1);
	    	r_hyper_busy      <= 1'b1 ; 
	    	r_hyram_cs        <= 1'b0 ;
	    	r_hyram_rwds_tri  <= 1'b1 ;
	    	r_hyram_data_tri  <= 1'b0 ;
	    	r_done_delay      <= 3'b000 ;
	    
	      case(r_hyper_acess_cnt)
	    	8'd0: begin  
	    		 r_hyram_dout      <= 16'h6000;
	    	end
	    	8'd1: begin 
	    		 r_hyram_dout      <= 16'h0100;
	    	end
	    	8'd2: begin 
	    		 r_hyram_dout      <= 16'h0000;
	    	end
	    	8'd3: begin 
	    		 r_hyram_dout      <= i_reg0_write_value ;
	    		 r_state           <= ST_DONE  ;
	    	end
	    	 	
	    	default : begin 
	    		 r_state           <= ST_IDEL  ;
	    	end                        
	      endcase
	    end
	    
	    ST_WCMD : begin    	 
	    	 r_hyram_cs          <= 1'b1 ;
	    	 r_hyram_data_tri    <= 1'b1 ;
	    	 r_hyram_rwds_tri    <= 1'b1 ;
	    	 r_hyper_acess_cnt   <= 8'd0 ;
	    	 r_hyram_read_pipe   <= 1'b0 ; 
	    	 r_wfifo_rden        <= 1'b0 ;
	    	 r_wfifo_reset       <= 1'b0 ;
	    	 r_hyram_init_complate <= 1'b1;  
	    	 r_done_delay        <= 3'b000 ;
	    	 if(w_hyper_acess_tready & i_acess_tvalid) begin 
	    	 	  r_state          <= i_acess_rw ? ST_READ : ST_WRITE;
	    	 	  r_hyper_busy     <= 1'b1 ;
	    	 end	 
	    	 else begin 
	    	 	  r_state  <= ST_WCMD;  
	    	 	  r_hyper_busy <= 1'b0;
	    	 end
	    end
	    
	    ST_READ : begin 
	    	 r_hyper_acess_cnt   <= (&r_hyper_acess_cnt) ? r_hyper_acess_cnt : (r_hyper_acess_cnt + 1'b1);
	    	 r_hyper_busy        <= 1'b1;  
	    	 r_hyram_cs          <= 1'b0;
	    	 r_hyram_rwds_tri    <= 1'b1;
	    	 
	    	 if(r_hyper_acess_cnt == 8'd0) begin 
	    	 	  r_hyram_data_tri    <= 1'b0 ;
	    	 	  r_hyram_dout        <= {3'b101,r_hyper_acess_addr[31:27],r_hyper_acess_addr[26:19]};
	    	 end
	    	 else if(r_hyper_acess_cnt == 8'd1) begin 
	    	 	  r_hyram_data_tri    <= 1'b0 ;
	    	 	  r_hyram_dout        <=  {r_hyper_acess_addr[18:11],r_hyper_acess_addr[10:3]};
	    	 end
	    	 else if(r_hyper_acess_cnt == 8'd2) begin 
	    	 	  r_hyram_data_tri    <= 1'b0 ;
	    	 	  r_hyram_dout        <= {8'd0,5'd0,r_hyper_acess_addr[2:0]};
	    	 end
	    	 else begin 
	    	 	  r_hyram_data_tri    <= 1'b1;
	    	 end
	    	  
	    	 r_hyram_read_pipe	 <= (r_hyper_acess_cnt >= 8'd14) ? 1'b1 : 1'b0;
	    	 //r_state  <= ((r_hyram_read_pipe & (r_hyram_rdcnt >= (r_hyper_acess_len[7:1] - 1'b1))) | r_readtimeout_err) ? ST_DONE : ST_READ;
	    	 r_state <= (r_hyper_acess_cnt >= w_hyram_rdtotal) ? ST_DONE : ST_READ;
	    end
	    
	    
	    ST_WRITE : begin 
	    	 r_hyper_busy        <= 1'b1;
	    	 r_hyram_cs          <= 1'b0;
	    	 r_hyper_acess_cnt   <= (&r_hyper_acess_cnt) ? r_hyper_acess_cnt : (r_hyper_acess_cnt + 1'b1);
	    	 r_hyram_data_tri    <= 1'b0;
	    	 
	    	 if(r_hyper_acess_cnt == 8'd0) begin 
	    	 	  r_hyram_dout     <= {3'b001,r_hyper_acess_addr[31:27],r_hyper_acess_addr[26:19]};
	    	 end
	    	 else if(r_hyper_acess_cnt == 8'd1) begin 
	    	 	  r_hyram_dout     <=  {r_hyper_acess_addr[18:11],r_hyper_acess_addr[10:3]};  
	    	 end
	    	 else if(r_hyper_acess_cnt == 8'd2) begin 
	    	 	  r_hyram_dout     <=  {8'd0,5'd0,r_hyper_acess_addr[2:0]}; 
	    	 end 
	    	 else if(r_hyper_acess_cnt >= 8'd16) begin 
	    	 	  r_hyram_dout     <=  w_hyram_fifo_rdata; 
	    	 end
	    	 else begin 
	    	 	  r_hyram_dout     <= 16'd0;
	    	 end
	    	 
	    	 r_hyram_rwds_tri    <= (r_hyper_acess_cnt > 8'd2) ? 1'b0 : 1'b1; 
	    	 r_state  <=  (r_hyper_acess_cnt >= w_hyram_rdtotal) ?  ST_DONE : ST_WRITE ;
	    	 
	    	 r_wfifo_rden <= ((r_hyper_acess_cnt >= 8'd14) & (r_hyper_acess_cnt <= (r_hyper_acess_len[7:1] + 8'd14))) ? 1'b1 : 1'b0;
	    	 r_wfifo_reset<= (r_hyper_acess_cnt >= w_hyram_rdtotal) ? 1'b1 : 1'b0;
	    end  
	    
	    ST_DONE : begin 
	    	 r_done_delay        <= (&r_done_delay) ? r_done_delay : (r_done_delay + 1'b1);
	    	 r_hyram_cs          <= 1'b1;  
	    	 //r_hyram_read_pipe   <= 1'b0; 
	    	 r_hyram_data_tri    <= 1'b1;
	    	 r_hyram_rwds_tri    <= 1'b1;
	    	 r_hyper_busy        <= 1'b0;
	    	 r_wfifo_rden        <= 1'b0;
	    	 r_wfifo_reset       <= 1'b0;
	    	 r_state             <=(&r_done_delay) ? ST_WCMD : ST_DONE;
	    end
	    
	    default : begin 
	    	 r_state  <= 	ST_IDEL ;
	    end
	    endcase
	  end
end   

always @ (posedge i_hyclk)      
begin                      
	  if(i_hyreset) begin
	  	r_readtimeout_err     <= 1'b0   ;  	  
	  	r_acess_done          <= 1'b0   ;
	  end
	  else begin
	  	r_acess_done          <= ((r_state ==  ST_DONE) & (&r_done_delay))?  1'b1 : 1'b0;
	  	
	  	if(r_state == ST_WCMD)  begin 
	  		r_readtimeout_err     <= 1'b0   ;    
 	  	end
	  	else if((r_state ==  ST_DONE) & (&r_done_delay)) begin   
	  		r_readtimeout_err     <= (r_hyram_rdcnt < (r_hyper_acess_len[7:1]-1'b1)) ? 1'b1 : 1'b0;
	  	end
	  end
end
/***********************************************************************/
//write fifo
/***********************************************************************/
fifo_sync_1024_16i_16o u_fifo_wr_inst(
    .clk_i                  (i_hyclk                  )
   ,.rst_i                  (r_wfifo_reset            )
   ,.wr_en_i                (w_hyram_fifo_wren        )
   ,.rd_en_i                (r_wfifo_rden             )
   ,.wr_data_i              (i_acess_wdata_tdata      )
   ,.full_o                 (                         )
   ,.empty_o                (                         )
   ,.almost_full_o          (w_hyram_fifo_alfull      )
   ,.almost_empty_o         (                         )
   ,.rd_data_o              (w_hyram_fifo_rdata       )
); 

/***********************************************************************/
//phy layer IO
/***********************************************************************/
dw8_dq_v2 #(
    .DELAY_VALUE            (DELAY_VALUE              )
   ,.DEL_MODE               (DEL_MODE                 )
)u_dw8_dq_inst(
    .i_clk                  (i_hyclk                  ) 
   ,.i_clk_op               (i_hyclk_90os             )
   ,.i_reset                (i_hyreset                )
   ,.i_dout_en              (r_hyram_data_tri         )
   ,.i_dout_data            (r_hyram_dout             )
   ,.o_din_data             (w_hyram_rdata            )
   ,.i_rwds_z_en            (r_hyram_rwds_tri         )
   ,.i_rwds_dout            (2'b00                    )
   ,.o_rwds_din             (w_hyper_rwds_do          )
   ,.i_csb_dout             (r_hyram_cs               )   
   ,.io_dq                  (io_hyram_dq              ) 
   ,.io_rwds                (io_hyram_rwds            ) 
   ,.o_clk_p                (o_hyram_ckp              ) 
   ,.o_clk_n                (o_hyram_ckn              ) 
   ,.o_csb                  (o_hyram_cs               ) 
);                                                               
                                                                   
always @ (posedge i_hyclk) 
begin                                                 
	  if(i_hyreset) begin                              
	  	 r_rdata_tvalid <= 1'b0 ;
	  	 r_rdata_tlast  <= 1'b0 ;
	  	 r_rdata_tdata  <= 16'd0;
	  	 r_hyram_rdcnt  <= 7'd0 ; 
         r_rwds_iob_din <= 2'b00;	
         r_dq_iob_din   <= 16'd0;	
         r_p2_rwds_data <= 2'b00;
         r_p2_dq_data	 <= 16'd0;	 
	  end
	  else begin  
		  r_rwds_iob_din <= w_hyper_rwds_do;
		  r_p2_rwds_data <= r_rwds_iob_din ;
		  
		  r_dq_iob_din   <= w_hyram_rdata  ;
		  r_p2_dq_data   <= r_dq_iob_din   ;
		  
	  	if(r_hyram_read_pipe) begin 
	  	 //if(r_rwds_iob_din == 2'b10) begin 
		   if(r_p2_rwds_data == 2'b01) begin 
	  	 	  //r_rdata_tdata  <= r_dq_iob_din;
			  r_rdata_tdata  <= {r_p2_dq_data[7:0],r_dq_iob_din[15:8]};
	  	 	  r_rdata_tvalid <= 1'b1; 
	  	 	  r_hyram_rdcnt  <= (&r_hyram_rdcnt) ? r_hyram_rdcnt : (r_hyram_rdcnt + 1'b1);
	  	 end    	 
	  	 else begin 
	  	 	  r_rdata_tvalid <= 1'b0; 
	  	 	  r_rdata_tdata  <= r_rdata_tdata;
	  	 	  r_hyram_rdcnt  <= r_hyram_rdcnt;
	  	 end 
	  	end
	  	else begin 
	  		 r_rdata_tdata  <= 16'd0;
	  		 r_rdata_tvalid <= 1'b0 ; 
	  		 r_hyram_rdcnt  <= 7'd0 ;
	  	end
	  	  
	  	r_rdata_tlast      <= (r_rdata_tvalid & (r_hyram_rdcnt == (r_hyper_acess_len[7:1]-1'b1))) ? 1'b1 : 1'b0;
	  	
	  end
end

endmodule                                                          