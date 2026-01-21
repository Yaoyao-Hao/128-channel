component add_48 is
    port(
        clk_i: in std_logic;
        rst_i: in std_logic;
        add_sub_i: in std_logic;
        data_a_re_i: in std_logic_vector(47 downto 0);
        data_b_re_i: in std_logic_vector(47 downto 0);
        result_re_o: out std_logic_vector(47 downto 0)
    );
end component;

__: add_48 port map(
    clk_i=>,
    rst_i=>,
    add_sub_i=>,
    data_a_re_i=>,
    data_b_re_i=>,
    result_re_o=>
);
