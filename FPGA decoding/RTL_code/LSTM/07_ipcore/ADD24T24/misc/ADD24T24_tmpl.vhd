component ADD24T24 is
    port(
        data_a_re_i: in std_logic_vector(23 downto 0);
        data_b_re_i: in std_logic_vector(23 downto 0);
        result_re_o: out std_logic_vector(23 downto 0)
    );
end component;

__: ADD24T24 port map(
    data_a_re_i=>,
    data_b_re_i=>,
    result_re_o=>
);
