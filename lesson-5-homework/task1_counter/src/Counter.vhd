library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Counter is
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
end entity Counter;


architecture rtl of Counter is

    signal count_reg : unsigned(3 downto 0);

begin

    CounterProcess : process(clk, rst)
    begin

        -- Asynchronous active-high reset
        if rst = '1' then
            count_reg <= (others => '0');

        elsif rising_edge(clk) then

            -- load has priority over en
            if load = '1' then
                count_reg <= unsigned(data_in);

            elsif en = '1' then

                if up_down = '1' then
                    count_reg <= count_reg + 1;
                else
                    count_reg <= count_reg - 1;
                end if;

            end if;

        end if;

    end process CounterProcess;


    count <= std_logic_vector(count_reg);

end architecture rtl;