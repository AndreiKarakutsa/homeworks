library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CounterLed is
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
end entity;


architecture rtl of CounterLed is

    signal counter : unsigned(WIDTH - 1 downto 0) := (others => '0');

begin

    CounterProcess : process(clk)
    begin

        if rising_edge(clk) then

            if reset = '1' then
                counter <= (others => '0');

            elsif counter = to_unsigned(MAX_VALUE, WIDTH) then
                counter <= (others => '0');

            else
                counter <= counter + 1;

            end if;

        end if;

    end process;


    led <= std_logic_vector(counter);

end architecture rtl;