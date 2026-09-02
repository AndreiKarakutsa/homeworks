library ieee;
use ieee.std_logic_1164.all;

entity CounterLedTop_tb is
end entity CounterLedTop_tb;


architecture sim of CounterLedTop_tb is

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    signal led   : std_logic_vector(3 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    component CounterLedTop is
    port
    (
        clk   : in  std_logic;
        reset : in  std_logic;

        led   : out std_logic_vector(3 downto 0)
    );
    end component;

begin

    DUT : CounterLedTop
    port map
    (
        clk   => clk,
        reset => reset,
        led   => led
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

        -- Keep reset active for two clock cycles
        reset <= '1';
        wait for 20 ns;

        -- Start counting
        reset <= '0';

        -- Run long enough to see:
        -- 0 -> 1 -> ... -> 15 -> 0 -> ...
        wait for 180 ns;

        -- Test reset again while counter is running
        reset <= '1';
        wait for 20 ns;

        reset <= '0';
        wait for 50 ns;

        wait;

    end process StimulusProcess;

end architecture sim;