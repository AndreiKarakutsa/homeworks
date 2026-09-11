library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CounterTop_tb is
end entity CounterTop_tb;


architecture sim of CounterTop_tb is

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    signal load    : std_logic := '0';
    signal data_in : std_logic_vector(3 downto 0) := (others => '0');
    signal en      : std_logic := '0';
    signal up_down : std_logic := '0';

    signal count   : std_logic_vector(3 downto 0);

    constant CLK_PERIOD : time := 10 ns;


    component CounterTop is
    port
    (
        clk     : in  std_logic;
        rst     : in  std_logic;
        load    : in  std_logic;
        data_in : in  std_logic_vector(3 downto 0);
        en      : in  std_logic;
        up_down : in  std_logic;

        count   : out std_logic_vector(3 downto 0)
    );
    end component;
	 
	 
	 procedure check_count
	 (
		constant expected  : in std_logic_vector(3 downto 0);
		constant test_name : in string
	 ) is
	 begin
	 
		if count = expected then

        report "PASS: " & test_name &
               " count=" &
               integer'image(to_integer(unsigned(count)))
               severity note;

		else

        report "FAIL: " & test_name &
               " expected=" &
               integer'image(to_integer(unsigned(expected))) &
               " actual=" &
               integer'image(to_integer(unsigned(count)))
               severity error;

    end if;

end procedure;

begin

    DUT : CounterTop
    port map
    (
        clk     => clk,
        rst     => rst,
        load    => load,
        data_in => data_in,
        en      => en,
        up_down => up_down,
        count   => count
    );


    ClockProcess : process
    begin

        clk <= '0';
        wait for CLK_PERIOD / 2;

        clk <= '1';
        wait for CLK_PERIOD / 2;

    end process ClockProcess;


    StimulusProcess : process
    begin

        --------------------------------------------------
        -- Initial state
        --------------------------------------------------

        rst     <= '0';
        load    <= '0';
        en      <= '0';
        up_down <= '0';
        data_in <= "0000";

        -- Leave some time before reset.
        -- count should be U/X-like because count_reg
        -- has not been initialized yet.
        wait for 3 ns;


        --------------------------------------------------
        -- RESET
        --------------------------------------------------

        rst <= '1';
        wait for CLK_PERIOD;

        rst <= '0';

        wait for 1 ns;

        check_count("0000", "asynchronous reset");


        --------------------------------------------------
        -- LOAD 10
        --------------------------------------------------

        load    <= '1';
        data_in <= std_logic_vector(to_unsigned(10, 4));

        wait until rising_edge(clk);
        wait for 1 ns;

        load <= '0';

        check_count(std_logic_vector(to_unsigned(10, 4)), "load 10");


        --------------------------------------------------
        -- COUNT UP: 10 -> 13
        --------------------------------------------------

        en      <= '1';
        up_down <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        wait until rising_edge(clk);
        wait for 1 ns;

        wait until rising_edge(clk);
        wait for 1 ns;

        check_count(std_logic_vector(to_unsigned(13, 4)), "count up 10 to 13");


        --------------------------------------------------
        -- COUNT UP THROUGH BOUNDARY:
        -- 13 -> 14 -> 15 -> 0
        --------------------------------------------------

        wait until rising_edge(clk);
        wait for 1 ns;

        wait until rising_edge(clk);
        wait for 1 ns;

        wait until rising_edge(clk);
        wait for 1 ns;

        check_count("0000", "count up wrap 15 to 0");


        --------------------------------------------------
        -- HOLD: en = 0
        --------------------------------------------------

        en <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        wait until rising_edge(clk);
        wait for 1 ns;

        check_count("0000", "hold value when en=0");


        --------------------------------------------------
        -- COUNT DOWN THROUGH BOUNDARY:
        -- 0 -> 15
        --------------------------------------------------

        en      <= '1';
        up_down <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        check_count(std_logic_vector(to_unsigned(15, 4)), "count down wrap 0 to 15");


        --------------------------------------------------
        -- LOAD PRIORITY OVER EN
        --------------------------------------------------

        load    <= '1';
        data_in <= std_logic_vector(to_unsigned(5, 4));
        en      <= '1';
        up_down <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        check_count(std_logic_vector(to_unsigned(5, 4)), "load priority over en");

        load <= '0';


        --------------------------------------------------
        -- BONUS:
        -- Load 8, then count down to 7
        --------------------------------------------------

        load    <= '1';
        data_in <= std_logic_vector(to_unsigned(8, 4));

        wait until rising_edge(clk);
        wait for 1 ns;

        load <= '0';

        check_count(std_logic_vector(to_unsigned(8, 4)), "bonus load 8");


        en      <= '1';
        up_down <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        check_count(std_logic_vector(to_unsigned(7, 4)), "bonus count down 8 to 7");


        --------------------------------------------------
        -- END
        --------------------------------------------------

        en <= '0';

        report "All counter tests completed."
            severity note;

        wait;

    end process StimulusProcess;

end architecture sim;