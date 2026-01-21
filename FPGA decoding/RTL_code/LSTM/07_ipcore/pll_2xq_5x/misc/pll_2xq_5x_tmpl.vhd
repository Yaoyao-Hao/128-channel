component pll_2xq_5x is
    port(
        clki_i: in std_logic;
        rstn_i: in std_logic;
        phasedir_i: in std_logic;
        phasestep_i: in std_logic;
        phaseloadreg_i: in std_logic;
        phasesel_i: in std_logic_vector(2 downto 0);
        clkop_o: out std_logic;
        clkos_o: out std_logic;
        clkos2_o: out std_logic;
        clkos3_o: out std_logic;
        clkos4_o: out std_logic;
        clkos5_o: out std_logic;
        lock_o: out std_logic
    );
end component;

__: pll_2xq_5x port map(
    clki_i=>,
    rstn_i=>,
    phasedir_i=>,
    phasestep_i=>,
    phaseloadreg_i=>,
    phasesel_i=>,
    clkop_o=>,
    clkos_o=>,
    clkos2_o=>,
    clkos3_o=>,
    clkos4_o=>,
    clkos5_o=>,
    lock_o=>
);
