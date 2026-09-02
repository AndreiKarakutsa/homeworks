library ieee;
use ieee.std_logic_1164.all;

entity CounterLedTop is
port
(
    clk   : in  std_logic;
    reset : in  std_logic;

    led   : out std_logic_vector(3 downto 0)
);
end entity CounterLedTop;


architecture rtl of CounterLedTop is

    component CounterLed is
    generic
    (
        WIDTH     : positive := 4;
        MAX_VALUE : natural  := 15
    );
    port
    (
        clk   : in  std_logic;
        reset : in  std_logic;

        led   : out std_logic_vector(WIDTH - 1 downto 0)
    );
    end component;

begin

    COUNTER : CounterLed
    generic map
    (
        WIDTH     => 4,
        MAX_VALUE => 15
    )
    port map
    (
        clk   => clk,
        reset => reset,
        led   => led
    );

end architecture rtl;