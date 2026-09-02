library ieee;
use ieee.std_logic_1164.all;

entity MuxTop is
port
(
	a        : in  std_logic;
	b        : in  std_logic;
	sel      : in  std_logic;

	yLatch   : out std_logic;
	yNoLatch : out std_logic
);
end entity MuxTop;


architecture rtl of MuxTop is

	component MuxLatch is
	port
	(
		a   : in  std_logic;
		b   : in  std_logic;
		sel : in  std_logic;

		y   : out std_logic
	);
	end component;


	component MuxNoLatch is
	port
	(
		a   : in  std_logic;
		b   : in  std_logic;
		sel : in  std_logic;

		y   : out std_logic
	);
	end component;

begin

	MUX_WITH_LATCH : MuxLatch
	port map
	(
		a   => a,
		b   => b,
		sel => sel,
		y   => yLatch
	);


	MUX_WITHOUT_LATCH : MuxNoLatch
	port map
	(
		a   => a,
		b   => b,
		sel => sel,
		y   => yNoLatch
	);

end architecture rtl;