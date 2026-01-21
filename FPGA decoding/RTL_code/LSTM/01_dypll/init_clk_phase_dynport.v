`ifndef __RTL_MODULE__INIT_CLK_PHASE_DYNPORT__
`define __RTL_MODULE__INIT_CLK_PHASE_DYNPORT__
//`timescale 1ns / 1ps
//==========================================================================
// Module : init_clk_phase_dynport
//==========================================================================
module init_clk_phase_dynport #

( //--begin_param--
//----------------------------
// Parameters
//----------------------------
parameter                     CLKOP_PHASE_ACTUAL       = 0.0,
parameter                     CLKOS_PHASE_ACTUAL       = 0.0,
parameter                     CLKOS2_PHASE_ACTUAL      = 0.0,
parameter                     CLKOS3_PHASE_ACTUAL      = 0.0,
parameter                     CLKOS4_PHASE_ACTUAL      = 0.0,
parameter                     CLKOS5_PHASE_ACTUAL      = 0.0,
parameter                     CLKOS_EN                 = 0,
parameter                     CLKOS2_EN                = 0,
parameter                     CLKOS3_EN                = 0,
parameter                     CLKOS4_EN                = 0,
parameter                     CLKOS5_EN                = 0,
parameter                     CLKOP_BYPASS             = 0,
parameter                     CLKOS_BYPASS             = 0,
parameter                     CLKOS2_BYPASS            = 0,
parameter                     CLKOS3_BYPASS            = 0,
parameter                     CLKOS4_BYPASS            = 0,
parameter                     CLKOS5_BYPASS            = 0,
parameter                     PHIA                     = "0",
parameter                     PHIB                     = "0",
parameter                     PHIC                     = "0",
parameter                     PHID                     = "0",
parameter                     PHIE                     = "0",
parameter                     PHIF                     = "0"

) //--end_param--

( //--begin_ports--

input                         clk_i,
input                         rstn_i,

// Dynamic Phase Control
output reg                    phasedir_o,
output reg                    phasestep_o,
output reg                    phaseloadreg_o,
output reg  [2:0]             phasesel_o,

// PLL Lock
input                         pll_lock_i, // from PLL primitive

output reg                    pll_lock_o, // gated until phase initialization is done

output reg                    done_pll_init
); //--end_ports--


function [31:0] clog2;
  input [31:0] value;
  reg   [31:0] num;
begin
  num = value - 1;
  for (clog2=0; num>0; clog2=clog2+1) num = num>>1;
end
endfunction

localparam MAX_STRING_LENGTH = 16;
localparam CONVWIDTH         = 32;
function [CONVWIDTH-1:0] convertDeviceString;
  input [(MAX_STRING_LENGTH)*8-1:0] attributeValue;
  integer i, j;
  integer decVal;
  integer decPlace;
  integer temp, count;
  reg decimalFlag;
  reg [CONVWIDTH-1:0] reverseVal;
  integer concatDec[CONVWIDTH-1:0];
  reg [1:8] character;
  reg [7:0] checkType;
  begin

    decimalFlag = 1'b0;
    decVal = 0;
    decPlace = 1;
    temp = 0;
    count = 0;
    for(i=0; i<=CONVWIDTH-1; i=i+1) begin
      concatDec[i] = -1;
    end
    convertDeviceString = 0;
    checkType = "N";
    for (i=MAX_STRING_LENGTH-1; i>=1 ; i=i-1) begin
      for (j=1; j<=8; j=j+1) begin
        character[j] = attributeValue[i*8-j];
      end

      //Check to see if binary or hex
      if (checkType === "N") begin
        if (character === "b" || character === "x") begin
           checkType = character;
           decimalFlag = 1'b1;
        end
        else begin
          //Convert to string decimal to array of integers for each digit of the number
          case(character)
              "0": concatDec[i-1] = 0;
              "1": concatDec[i-1] = 1;
              "2": concatDec[i-1] = 2;
              "3": concatDec[i-1] = 3;
              "4": concatDec[i-1] = 4;
              "5": concatDec[i-1] = 5;
              "6": concatDec[i-1] = 6;
              "7": concatDec[i-1] = 7;
              "8": concatDec[i-1] = 8;
              "9": concatDec[i-1] = 9;
              default: concatDec[i-1] = -1;
          endcase
        end
      end // (checkType === "N")

      else begin
        //$display("Index %d: %s", i, character);
        //handle binary
        if (checkType === "b") begin
          case(character)
            "0": convertDeviceString[i-1] = 1'b0;
            "1": convertDeviceString[i-1] = 1'b1;
            default: convertDeviceString[i-1] = 1'bx;
          endcase
        end
        //handle hex
        else if (checkType === "x") begin
          case(character)
            "0"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h0;
            "1"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h1;
            "2"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h2;
            "3"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h3;
            "4"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h4;
            "5"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h5;
            "6"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h6;
            "7"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h7;
            "8"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h8;
            "9"      : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'h9;
            "a", "A" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hA;
            "b", "B" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hB;
            "c", "C" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hC;
            "d", "D" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hD;
            "e", "E" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hE;
            "f", "F" : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hF;
            default  : {convertDeviceString[i*4-1], convertDeviceString[i*4-2], convertDeviceString[i*4-3], convertDeviceString[(i-1)*4]} = 4'hX;
          endcase
        end
      end

    end
    //Calculate decmial value from integer array.
    if(decimalFlag === 1'b0) begin
      for (i=0; i<=CONVWIDTH-1 ; i=i+1) begin
        case(concatDec[i])
          0: temp = 0;
          1: temp = 1;
          2: temp = 2;
          3: temp = 3;
          4: temp = 4;
          5: temp = 5;
          6: temp = 6;
          7: temp = 7;
          8: temp = 8;
          9: temp = 9;
          default: temp = -1;
        endcase
        if(temp != -1) begin
          decVal = decVal + (temp * decPlace);
          count = count + 1;
          decPlace = 10 ** count;
        end
      end
      convertDeviceString = decVal;
    end
  end
endfunction // convertDeviceString

//--------------------------------------------------------------------------
//--- Local Parameters/Defines ---
//--------------------------------------------------------------------------
localparam                    ST_PHLOAD_IDLE  = 3'd0,
                              ST_PHLOAD_START = 3'd4,
                              ST_PHLOAD_WAIT1 = 3'd5,
                              ST_PHLOAD_WAIT2 = 3'd7,
                              ST_PHLOAD_WAIT3 = 3'd6,
                              ST_PHLOAD_DONE  = 3'd1;

localparam                    PHCNTRWID    = 3;

localparam                    FRST_CLK_PTR = 3'd0;
localparam                    LAST_CLK_PTR = 3'd5;

// Check non-zero phase
localparam                    EN_INIT_PHA = (                  CLKOP_BYPASS  == 0 && CLKOP_PHASE_ACTUAL  != 0)? 1 : 0;
localparam                    EN_INIT_PHB = (CLKOS_EN  == 1 && CLKOS_BYPASS  == 0 && CLKOS_PHASE_ACTUAL  != 0)? 1 : 0;
localparam                    EN_INIT_PHC = (CLKOS2_EN == 1 && CLKOS2_BYPASS == 0 && CLKOS2_PHASE_ACTUAL != 0)? 1 : 0;
localparam                    EN_INIT_PHD = (CLKOS3_EN == 1 && CLKOS3_BYPASS == 0 && CLKOS3_PHASE_ACTUAL != 0)? 1 : 0;
localparam                    EN_INIT_PHE = (CLKOS4_EN == 1 && CLKOS4_BYPASS == 0 && CLKOS4_PHASE_ACTUAL != 0)? 1 : 0;
localparam                    EN_INIT_PHF = (CLKOS5_EN == 1 && CLKOS5_BYPASS == 0 && CLKOS5_PHASE_ACTUAL != 0)? 1 : 0;

localparam                    INT_PHIA = convertDeviceString(PHIA);
localparam                    INT_PHIB = convertDeviceString(PHIB);
localparam                    INT_PHIC = convertDeviceString(PHIC);
localparam                    INT_PHID = convertDeviceString(PHID);
localparam                    INT_PHIE = convertDeviceString(PHIE);
localparam                    INT_PHIF = convertDeviceString(PHIF);

localparam                    IDX_CLKOP =             0;
localparam                    IDX_CLKOS = IDX_CLKOP + 1;
localparam                    IDX_CLKS2 = IDX_CLKOS + 1;
localparam                    IDX_CLKS3 = IDX_CLKS2 + 1;
localparam                    IDX_CLKS4 = IDX_CLKS3 + 1;
localparam                    IDX_CLKS5 = IDX_CLKS4 + 1;

//--------------------------------------------------------------------------
//--- Combinational Wire/Reg ---
//--------------------------------------------------------------------------

wire        [5:0]             initialize_clkphase;
wire        [2:0]             nxt_clk_ptr[5:0];
wire        [2:0]             start_clk_ptr;

wire        [PHCNTRWID-1:0]   phi_values[5:0];
wire        [PHCNTRWID-1:0]   nxt_clk_phi;
wire        [PHCNTRWID-1:0]   phrot_cntr_nxt;


//--------------------------------------------------------------------------
//--- Registers ---
//--------------------------------------------------------------------------
reg                           clk_last;
reg         [2:0]             phload_sm_cs;
reg         [PHCNTRWID-1:0]   phrot_cntr;
reg                           phrot_done;

function [5:0] gen_init_clk_phase_map;
  input       enable;
  reg   [5:0] init_clkphase;
begin
  init_clkphase            = {6{1'b0}};
  init_clkphase[IDX_CLKOP] = (EN_INIT_PHA)? enable : ~enable;
  init_clkphase[IDX_CLKOS] = (EN_INIT_PHB)? enable : ~enable;
  init_clkphase[IDX_CLKS2] = (EN_INIT_PHC)? enable : ~enable;
  init_clkphase[IDX_CLKS3] = (EN_INIT_PHD)? enable : ~enable;
  init_clkphase[IDX_CLKS4] = (EN_INIT_PHE)? enable : ~enable;
  init_clkphase[IDX_CLKS5] = (EN_INIT_PHF)? enable : ~enable;

  gen_init_clk_phase_map = init_clkphase;
end
endfunction

assign initialize_clkphase = gen_init_clk_phase_map(1'b1);



genvar i;
generate
  for(i=0; i<5; i=i+1) begin
    assign nxt_clk_ptr[i] = (initialize_clkphase[i+1])? (i+1) : nxt_clk_ptr[i+1];
  end
endgenerate

assign start_clk_ptr = (initialize_clkphase)? ((initialize_clkphase[0])? FRST_CLK_PTR : nxt_clk_ptr[0]) :
                                              (LAST_CLK_PTR);

assign nxt_clk_ptr[5] = 3'd0;           // loop to first clock

assign phi_values[IDX_CLKOP] = INT_PHIA;
assign phi_values[IDX_CLKOS] = INT_PHIB;
assign phi_values[IDX_CLKS2] = INT_PHIC;
assign phi_values[IDX_CLKS3] = INT_PHID;
assign phi_values[IDX_CLKS4] = INT_PHIE;
assign phi_values[IDX_CLKS5] = INT_PHIF;

assign nxt_clk_phi    = phi_values[phasesel_o];
assign phrot_cntr_nxt = phrot_cntr + {{(PHCNTRWID-1){1'b0}},phasestep_o};

//--------------------------------------------
//-- Load phase settings of each clock --
//--------------------------------------------
always @(posedge clk_i or negedge rstn_i) begin
  if(~rstn_i) begin
    phload_sm_cs <= ST_PHLOAD_IDLE;
    /*AUTORESET*/
    // Beginning of autoreset for uninitialized flops
    clk_last <= 1'h0;
    done_pll_init <= 1'h0;
    phasedir_o <= 1'h0;
    phaseloadreg_o <= 1'h0;
    phasesel_o <= 3'h0;
    phasestep_o <= 1'h0;
    phrot_cntr <= {PHCNTRWID{1'b0}};
    phrot_done <= 1'h0;
    pll_lock_o <= 1'h0;
    // End of automatics
  end
  else begin
    phasestep_o    <= 1'b0;
    phasedir_o     <= 1'b0;
    phaseloadreg_o <= 1'b0;
    phrot_cntr     <= 3'd0;
    phrot_done     <= (phrot_cntr_nxt == nxt_clk_phi);
    pll_lock_o     <= (done_pll_init)? pll_lock_i : 1'b0;
    case(phload_sm_cs)
      ST_PHLOAD_START : begin
        phload_sm_cs   <= ST_PHLOAD_WAIT2;

        clk_last       <= (nxt_clk_ptr[phasesel_o] == FRST_CLK_PTR);
      end
      ST_PHLOAD_WAIT2 : begin
        phrot_cntr     <= phrot_cntr_nxt;

        if(phrot_done) begin
          if(clk_last) begin
            phload_sm_cs  <= ST_PHLOAD_DONE;

            done_pll_init <= 1'b1;
          end
          else
            phload_sm_cs <= ST_PHLOAD_WAIT3;
        end
        else begin
          phload_sm_cs   <= ST_PHLOAD_WAIT2;

          phasestep_o    <= ~phasestep_o;
        end
      end
      ST_PHLOAD_WAIT3 : begin
        phload_sm_cs   <= ST_PHLOAD_START;

        phasesel_o     <= nxt_clk_ptr[phasesel_o];
      end
      ST_PHLOAD_DONE : begin
        phload_sm_cs   <= ST_PHLOAD_IDLE;
      end
      default : begin // ST_PHLOAD_IDLE
        phasesel_o     <= start_clk_ptr;
        clk_last       <= 1'b0;

        if(done_pll_init | ~pll_lock_i)
          phload_sm_cs <= ST_PHLOAD_IDLE;
        else
          phload_sm_cs <= ST_PHLOAD_START;
      end
    endcase
  end
end //--always @(posedge clk_i or negedge rstn_i)--

//--------------------------------------------------------------------------
//--- Module Instantiation ---
//--------------------------------------------------------------------------


endmodule //--init_clk_phase_dynport--
`endif // __RTL_MODULE__INIT_CLK_PHASE_DYNPORT__
