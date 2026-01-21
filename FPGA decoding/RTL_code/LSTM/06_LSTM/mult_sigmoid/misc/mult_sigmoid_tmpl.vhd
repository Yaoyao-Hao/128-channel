component mult_sigmoid is
    port(
        clk_i: in std_logic;
        clk_en_i: in std_logic;
        rst_i: in std_logic;
        data_a_i: in std_logic_vector(23 downto 0);
        data_b_i: in std_logic_vector(23 downto 0);
        result_o: out std_logic_vector(47 downto 0)
    );
end component;

__: mult_sigmoid port map(
    clk_i=>,
    clk_en_i=>,
    rst_i=>,
    data_a_i=>,
    data_b_i=>,
    result_o=>
);
