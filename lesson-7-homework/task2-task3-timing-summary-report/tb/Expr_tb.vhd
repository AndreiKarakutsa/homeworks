library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Expr_tb is
end entity Expr_tb;


architecture sim of Expr_tb is

    --------------------------------------------------------------------
    -- Testbench signals
    --------------------------------------------------------------------
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal a : std_logic_vector(7 downto 0) := (others => '0');
    signal b : std_logic_vector(7 downto 0) := (others => '0');
    signal c : std_logic_vector(7 downto 0) := (others => '0');
    signal d : std_logic_vector(7 downto 0) := (others => '0');

    signal result_plain : std_logic_vector(15 downto 0);
    signal result_pipe  : std_logic_vector(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    --------------------------------------------------------------------
    -- DUT 1: Non-pipelined version
    --------------------------------------------------------------------
    DUT_Plain : entity work.ExprPlain
    port map
    (
        clk    => clk,
        rst    => rst,

        a      => a,
        b      => b,
        c      => c,
        d      => d,

        result => result_plain
    );


    --------------------------------------------------------------------
    -- DUT 2: Pipelined version
    --------------------------------------------------------------------
    DUT_Pipelined : entity work.ExprPipelined
    port map
    (
        clk    => clk,
        rst    => rst,

        a      => a,
        b      => b,
        c      => c,
        d      => d,

        result => result_pipe
    );


    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    ClockProcess : process
    begin

        clk <= '0';
        wait for CLK_PERIOD / 2;

        clk <= '1';
        wait for CLK_PERIOD / 2;

    end process ClockProcess;


    --------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------
    StimulusProcess : process
    begin

        ----------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------
        report "TEST: Reset";

        rst <= '1';

        wait for 12 ns;

        assert result_plain = x"0000"
            report "FAIL: ExprPlain is not zero during reset"
            severity error;

        assert result_pipe = x"0000"
            report "FAIL: ExprPipelined is not zero during reset"
            severity error;

        rst <= '0';

        wait until falling_edge(clk);


        ----------------------------------------------------------------
        -- TEST CASE 1
        --
        -- (5 + 3) * 4 - 10
        -- = 8 * 4 - 10
        -- = 32 - 10
        -- = 22
        ----------------------------------------------------------------
        report "TEST 1: (5 + 3) * 4 - 10 = 22";

        a <= std_logic_vector(to_unsigned(5, 8));
        b <= std_logic_vector(to_unsigned(3, 8));
        c <= std_logic_vector(to_unsigned(4, 8));
        d <= std_logic_vector(to_unsigned(10, 8));


        -- First rising edge:
        -- inputs are captured into a_reg/b_reg/c_reg/d_reg
        wait until rising_edge(clk);

        -- Second rising edge:
        -- ExprPlain captures the calculated result.
        -- ExprPipelined captures stage1.
        wait until rising_edge(clk);
        wait for 1 ns;


        assert unsigned(result_plain) = to_unsigned(22, 16)
            report "FAIL: ExprPlain TEST 1. Expected 22, got "
                   & integer'image(to_integer(unsigned(result_plain)))
            severity error;

        report "PASS: ExprPlain TEST 1 -> result = "
               & integer'image(to_integer(unsigned(result_plain)));


        -- Third rising edge:
        -- ExprPipelined captures stage1 - d_stage.
        wait until rising_edge(clk);
        wait for 1 ns;


        assert unsigned(result_pipe) = to_unsigned(22, 16)
            report "FAIL: ExprPipelined TEST 1. Expected 22, got "
                   & integer'image(to_integer(unsigned(result_pipe)))
            severity error;

        report "PASS: ExprPipelined TEST 1 -> result = "
               & integer'image(to_integer(unsigned(result_pipe)));


        ----------------------------------------------------------------
        -- TEST CASE 2
        --
        -- (10 + 20) * 2 - 5
        -- = 30 * 2 - 5
        -- = 60 - 5
        -- = 55
        ----------------------------------------------------------------

        -- Change inputs on falling edge so that they are stable
        -- before the next rising edge.
        wait until falling_edge(clk);

        report "TEST 2: (10 + 20) * 2 - 5 = 55";

        a <= std_logic_vector(to_unsigned(10, 8));
        b <= std_logic_vector(to_unsigned(20, 8));
        c <= std_logic_vector(to_unsigned(2, 8));
        d <= std_logic_vector(to_unsigned(5, 8));


        -- Capture new inputs
        wait until rising_edge(clk);

        -- Plain result becomes available
        wait until rising_edge(clk);
        wait for 1 ns;


        assert unsigned(result_plain) = to_unsigned(55, 16)
            report "FAIL: ExprPlain TEST 2. Expected 55, got "
                   & integer'image(to_integer(unsigned(result_plain)))
            severity error;

        report "PASS: ExprPlain TEST 2 -> result = "
               & integer'image(to_integer(unsigned(result_plain)));


        -- Pipelined result becomes available one clock later
        wait until rising_edge(clk);
        wait for 1 ns;


        assert unsigned(result_pipe) = to_unsigned(55, 16)
            report "FAIL: ExprPipelined TEST 2. Expected 55, got "
                   & integer'image(to_integer(unsigned(result_pipe)))
            severity error;

        report "PASS: ExprPipelined TEST 2 -> result = "
               & integer'image(to_integer(unsigned(result_pipe)));


        ----------------------------------------------------------------
        -- FINISH
        ----------------------------------------------------------------
        report "ALL TESTS COMPLETED";

        wait;

    end process StimulusProcess;

end architecture sim;