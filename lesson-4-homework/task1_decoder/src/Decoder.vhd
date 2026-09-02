library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Decoder is
generic
(
	WIDTH : positive := 4
);
port
(
	code    : in  std_logic_vector;
	decoded : out std_logic_vector(WIDTH - 1 downto 0)
);
end entity;

architecture rtl of Decoder is
begin

	DecodeProcess: process(code)
		variable temp  : std_logic_vector(WIDTH - 1 downto 0);
		variable index : integer;
	begin
		temp := (others => '0');
		
		index := to_integer(unsigned(code));
		
		if index < WIDTH then
			temp(index) := '1';
		end if;
		
		decoded <= temp;
	end process;

end rtl;