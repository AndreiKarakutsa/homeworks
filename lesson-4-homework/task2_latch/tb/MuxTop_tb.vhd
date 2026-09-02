library ieee;
use ieee.std_logic_1164.all;

entity MuxTop_tb is
end entity MuxTop_tb;


architecture sim of MuxTop_tb is

	signal a        : std_logic := '0';
	signal b        : std_logic := '0';
	signal sel      : std_logic := '0';

	signal yLatch   : std_logic;
	signal yNoLatch : std_logic;

	component MuxTop is
	port
	(
		a        : in  std_logic;
		b        : in  std_logic;
		sel      : in  std_logic;

		yLatch   : out std_logic;
		yNoLatch : out std_logic
	);
	end component;

begin

	DUT : MuxTop
	port map
	(
		a        => a,
		b        => b,
		sel      => sel,
		yLatch   => yLatch,
		yNoLatch => yNoLatch
	);


	StimulusProcess : process
	begin

		-- sel = 0:
		-- both outputs get value from a
		a   <= '0';
		b   <= '0';
		sel <= '0';
		wait for 10 ns;


		-- Both outputs become 1
		a   <= '1';
		b   <= '0';
		sel <= '0';
		wait for 10 ns;


		-- sel = 1
		--
		-- MuxLatch:
		-- no assignment -> keeps previous value 1
		--
		-- MuxNoLatch:
		-- y = b = 0
		sel <= '1';
		wait for 10 ns;


		-- Change b to 1
		--
		-- MuxLatch still keeps previous value 1
		-- MuxNoLatch follows b and becomes 1
		b <= '1';
		wait for 10 ns;


		-- Change a to 0 while sel remains 1
		--
		-- MuxLatch ignores a and keeps 1
		-- MuxNoLatch remains b = 1
		a <= '0';
		wait for 10 ns;


		-- Change b back to 0
		--
		-- MuxLatch keeps 1
		-- MuxNoLatch becomes 0
		b <= '0';
		wait for 10 ns;


		-- Enable assignment in MuxLatch again
		-- yLatch now receives a = 0
		sel <= '0';
		wait for 10 ns;


		-- Store 1 in the latch again
		a <= '1';
		wait for 10 ns;


		-- Return sel to 1
		-- yLatch keeps stored 1
		-- yNoLatch = b = 0
		sel <= '1';
		wait for 10 ns;


		wait;

	end process StimulusProcess;

end architecture sim;