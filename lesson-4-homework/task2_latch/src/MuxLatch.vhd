library ieee;
use ieee.std_logic_1164.all;

entity MuxLatch is
port
(
	a   : in  std_logic;
	b   : in  std_logic;
	sel : in  std_logic;
	
	y   : out std_logic
);
end entity;

architecture rtl of MuxLatch is
begin

    process(a, b, sel)
    begin

        case sel is

            when '0' =>
                y <= a;

            when others =>
                null;

        end case;

    end process;

end architecture rtl;