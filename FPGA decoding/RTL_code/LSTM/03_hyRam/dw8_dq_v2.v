//------------------------------------------------------------
//File Name: dw8_dq_v2
//
//Project  : any
//
//Module   : HyperRAM module 
//
//Content  : 
//
//Description : phy of hyperRAM
//
//Spec.    :
//
//Author   : Hello,Panda
//------------------------------------------------------------
//History :
//2021-08-21:-Initial Creation
//2021-12-11:update to v2
//------------------------------------------------------------
`timescale 1ns / 1ps

module dw8_dq_v2 #(
   parameter integer    DELAY_VALUE  = 1   
  ,parameter            DEL_MODE     = "USER_DEFINED"
)(
   input  wire                        i_clk
  ,input  wire                        i_clk_op 
  ,input  wire                        i_reset
  
  ,input  wire                        i_dout_en
  ,input  wire          [15 : 0]      i_dout_data
  ,output wire          [15 : 0]      o_din_data
  
  ,input  wire                        i_rwds_z_en
  ,input  wire          [1 : 0]       i_rwds_dout
  ,output wire          [1 : 0]       o_rwds_din
  
  ,input  wire                        i_csb_dout  

  ,inout  wire          [7 : 0]       io_dq
  ,inout  wire                        io_rwds
  ,output wire                        o_clk_p
  ,output wire                        o_clk_n
  ,output wire                        o_csb
);

reg                                   r_hr_dout_en = 1'b0; 
reg                                   r_p2_hr_dout_en = 1'b0;
reg                                   r_hr_dq_z_en = 1'b0; 
reg                                   r_hr_rwds_z  = 1'b0;  
reg                                   r_p2_hr_rwds_z = 1'b0;
reg                                   r_hr_rwds_z_en = 1'b0;
reg                [15 : 0]           r_hr_dq_out  = 16'd0 ;
reg                [1  : 0]           r_hr_rwds_dout = 2'b00; 
reg                                   r_hr_csb = 1'b1;   

wire                                  w_hr_dq_zo         ;  
wire               [7 : 0]            w_hr_dq_o          ;
wire               [7 : 0]            w_hr_dq_i          ; 
wire               [7 : 0]            w_data_delay_out   ;
wire                                  w_hr_rwds_delay    ;

wire                                  w_hr_rwds_zo       ; 
wire                                  w_hr_csb_iob       ;

always @ (posedge i_clk)
begin 
	   r_hr_dout_en   <=  i_dout_en     ;  
	   r_p2_hr_dout_en<=  r_hr_dout_en  ;
	   r_hr_dq_z_en   <=  r_p2_hr_dout_en;  
	   r_hr_rwds_z    <=  i_rwds_z_en   ;
	   r_p2_hr_rwds_z <=  r_hr_rwds_z   ;
	   r_hr_rwds_z_en <=  r_p2_hr_rwds_z; 
	   r_hr_dq_out    <=  i_dout_data   ; 
	   r_hr_rwds_dout <=  i_rwds_dout   ; 
	   r_hr_csb       <=  i_csb_dout    ;
end

OFD1P3DX u_hr_dq_z_inst(
   .D                  (r_hr_dq_z_en         )
  ,.SP                 (1'b1                 )
  ,.CK                 (i_clk                )
  ,.CD                 (i_reset              )
  ,.Q                  (w_hr_dq_zo           )
);                    

BB u_hr_dq_io_inst [7:0] (         
   .I                  (w_hr_dq_o            )   
  ,.T                  (w_hr_dq_zo           )   
  ,.O                  (w_hr_dq_i            )   
  ,.B                  (io_dq                )    
); 

DELAYB                                                                            
#(                                                                                
   .DEL_VALUE          (DELAY_VALUE          )   //delay 1250ps     
  ,.COARSE_DELAY       ("0NS"                )                      
  ,.DEL_MODE           (DEL_MODE             )                      
) u_idelay_data_inst [7:0](                                                    
   .A                  (w_hr_dq_i            )   // I               
  ,.Z                  (w_data_delay_out     )   // O               
);                                                                                



IDDRX1 u_iddr_hrdq_inst [7:0] (      
   .D                  (w_data_delay_out     )   
  ,.RST                (i_reset              )                            
  ,.SCLK               (i_clk                )   
  ,.Q0                 (o_din_data[15:8]     )   
  ,.Q1                 (o_din_data[7 :0]     )    
); 

ODDRX1 u_oddr_hrdq_inst [7:0]  (                             
   .D0                 (r_hr_dq_out[15:8]    ) 
  ,.D1                 (r_hr_dq_out[7 :0]    ) 
  ,.SCLK               (i_clk                ) 
  ,.RST                (i_reset              ) 
  ,.Q                  (w_hr_dq_o            )   
);                           

ODDRX1 u_oddrx1f_hr_clkp_inst  (  
   .D0                 (1'b1                 )  
  ,.D1                 (1'b0                 )  
  ,.SCLK               (i_clk_op             )  
  ,.RST                (i_reset              )  
  ,.Q                  (o_clk_p              )  
);                           
                             
ODDRX1 u_oddrx1f_hr_clkn  (  
   .D0                 (1'b0                 )   
  ,.D1                 (1'b1                 )   
  ,.SCLK               (i_clk_op             )   
  ,.RST                (i_reset              )   
  ,.Q                  (o_clk_n              )    
);

OFD1P3DX u_hr_rwds_z_inst (     
   .D                  (r_hr_rwds_z_en       ) 
  ,.SP                 (1'b1                 ) 
  ,.CK                 (i_clk                ) 
  ,.CD                 (i_reset              ) 
  ,.Q                  (w_hr_rwds_zo         ) 
);                         

BB u_hr_rwds_io_inst (                                     
    .I                 (w_hr_rwds_o          )   
   ,.T                 (w_hr_rwds_zo         )   
   ,.O                 (w_hr_rwds_i          )   
   ,.B                 (io_rwds              )    
);  

DELAYB                                                               
#(                                                                   
   .DEL_VALUE          (DELAY_VALUE          )   //delay 1250ps      
  ,.COARSE_DELAY       ("0NS"                )                       
  ,.DEL_MODE           (DEL_MODE             )                       
) u_idelay_rwds_inst   (                                          
   .A                  (w_hr_rwds_i          )   // I                
  ,.Z                  (w_hr_rwds_delay      )   // O                
);                                                                         

IDDRX1 u_iddr_rwds_inst  (             
    .D                 (w_hr_rwds_delay      )       
   ,.RST               (i_reset              )       
   ,.SCLK              (i_clk                )            
   ,.Q0                (o_rwds_din[1]        )       
   ,.Q1                (o_rwds_din[0]        )         
);  

ODDRX1 u_oddr_rwds_inst  (        
    .D0                (r_hr_rwds_dout[1]    )      
   ,.D1                (r_hr_rwds_dout[0]    )  
   ,.SCLK              (i_clk                )                            
   ,.RST               (i_reset              )  
   ,.Q                 (w_hr_rwds_o          )    
);  

ODDRX1 u_oddrx1f_hr_csb_inst  ( 
    .D0                (r_hr_csb             ) 
   ,.D1                (r_hr_csb             ) 
   ,.SCLK              (i_clk                ) 
   ,.RST               (i_reset              ) 
  // ,.Q                 (w_hr_csb_iob         ) 
   ,.Q                 (o_csb                )
);   

/*OB  u_csb_ob_inst(
    .I                 (w_hr_csb_iob         )
   ,.O                 (o_csb                )      
);*/                     
                  
endmodule 