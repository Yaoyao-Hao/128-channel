
module pll_2xq_5x_dynport
(
  input      wire      clki_i          ,
  input      wire      rstn_i          ,

  output     wire      clkop_o         ,
  output     wire      clkos_o         ,
  output     wire      clkos2_o        ,
  output     wire      clkos3_o        ,
  output     wire      clkos4_o        ,

  output     wire      lock_o          ,
  output     wire      done_pll_init_o
);

  parameter CLKOP_PHASE_ACTUAL  = 0.0 ;
  parameter CLKOS_PHASE_ACTUAL  = 135.0 ;
  parameter CLKOS2_PHASE_ACTUAL = 0.0 ;
  parameter CLKOS3_PHASE_ACTUAL = 0.0 ;
  parameter CLKOS4_PHASE_ACTUAL = 0.0 ;
  parameter CLKOS5_PHASE_ACTUAL = 0.0 ;

  parameter CLKOS_EN            = 1   ;
  parameter CLKOS2_EN           = 1   ;
  parameter CLKOS3_EN           = 1   ;
  parameter CLKOS4_EN           = 1   ;
  parameter CLKOS5_EN           = 0   ;

  parameter CLKOP_BYPASS        = 0   ;
  parameter CLKOS_BYPASS        = 0   ;
  parameter CLKOS2_BYPASS       = 0   ;
  parameter CLKOS3_BYPASS       = 0   ;
  parameter CLKOS4_BYPASS       = 0   ;
  parameter CLKOS5_BYPASS       = 0   ;

  parameter PHIA                = "0" ;
  parameter PHIB                = "0" ;
  parameter PHIC                = "0" ;
  parameter PHID                = "0" ;
  parameter PHIE                = "0" ;
  parameter PHIF                = "0" ;

  wire         phasedir     ;
  wire         phasestep    ;
  wire         phaseloadreg ;
  wire  [2:0]  phasesel     ;

  wire         clkop        ;
  wire         clkos        ;
  wire         clkos2       ;
  wire         clkos3       ;
  wire         clkos4       ;

  wire         pll_lock     ;
  wire         pll_lock_dyn ;
  wire         done_pll_init;

  assign clkop_o         = clkop         ;
  assign clkos_o         = clkos         ;
  assign clkos2_o        = clkos2        ;
  assign clkos3_o        = clkos3        ;
  assign clkos4_o        = clkos4        ;

  assign lock_o          = pll_lock_dyn  ;
  assign done_pll_init_o = done_pll_init ;


  pll_2xq_5x u_pll_2xq_5x
  (
    .clki_i           (clki_i       ),
    .rstn_i           (rstn_i       ),

    .phasedir_i       (phasedir     ),
    .phasestep_i      (phasestep    ),
    .phaseloadreg_i   (phaseloadreg ),
    .phasesel_i       (phasesel     ),

    .clkop_o          (clkop        ),
    .clkos_o          (clkos        ),
    .clkos2_o         (clkos2       ),
    .clkos3_o         (clkos3       ),
    .clkos4_o         (clkos4       ),

    .lock_o           (pll_lock     )
  );

  init_clk_phase_dynport #
  ( /*AUTOINSTPARAM*/
    // Parameters
    .CLKOP_PHASE_ACTUAL                (CLKOP_PHASE_ACTUAL ),
    .CLKOS_PHASE_ACTUAL                (CLKOS_PHASE_ACTUAL ),
    .CLKOS2_PHASE_ACTUAL               (CLKOS2_PHASE_ACTUAL),
    .CLKOS3_PHASE_ACTUAL               (CLKOS3_PHASE_ACTUAL),
    .CLKOS4_PHASE_ACTUAL               (CLKOS4_PHASE_ACTUAL),
    .CLKOS5_PHASE_ACTUAL               (CLKOS5_PHASE_ACTUAL),
    .CLKOS_EN                          (CLKOS_EN           ),
    .CLKOS2_EN                         (CLKOS2_EN          ),
    .CLKOS3_EN                         (CLKOS3_EN          ),
    .CLKOS4_EN                         (CLKOS4_EN          ),
    .CLKOS5_EN                         (CLKOS5_EN          ),
    .CLKOP_BYPASS                      (CLKOP_BYPASS       ),
    .CLKOS_BYPASS                      (CLKOS_BYPASS       ),
    .CLKOS2_BYPASS                     (CLKOS2_BYPASS      ),
    .CLKOS3_BYPASS                     (CLKOS3_BYPASS      ),
    .CLKOS4_BYPASS                     (CLKOS4_BYPASS      ),
    .CLKOS5_BYPASS                     (CLKOS5_BYPASS      ),
    .PHIA                              (PHIA               ),
    .PHIB                              (PHIB               ),
    .PHIC                              (PHIC               ),
    .PHID                              (PHID               ),
    .PHIE                              (PHIE               ),
    .PHIF                              (PHIF               ))
    u_init_clk_phase_dynport
    ( /*AUTOINST*/

      // Inputs
      .clk_i                           (clki_i             ),
      .rstn_i                          (rstn_i             ),
      .pll_lock_i                      (pll_lock           ),

      // Outputs
      .phasedir_o                      (phasedir           ),
      .phasestep_o                     (phasestep          ),
      .phaseloadreg_o                  (phaseloadreg       ),
      .phasesel_o                      (phasesel           ),

      .pll_lock_o                      (pll_lock_dyn       ),
      .done_pll_init                   (done_pll_init      )
    );

endmodule
