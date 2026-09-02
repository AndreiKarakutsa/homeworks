library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DecoderTop_tb is
end entity DecoderTop_tb;


architecture sim of DecoderTop_tb is

    signal code4 : std_logic_vector(1 downto 0);
    signal code8 : std_logic_vector(2 downto 0);

    signal led4  : std_logic_vector(3 downto 0);
    signal led8  : std_logic_vector(7 downto 0);
	 
	 component DecoderTop is
	 port (
		code4 : in  std_logic_vector(1 downto 0);
      code8 : in  std_logic_vector(2 downto 0);

      led4  : out std_logic_vector(3 downto 0);
      led8  : out std_logic_vector(7 downto 0)
	);
	end component;

begin
	
	DUT : DecoderTop
	port map 
	(
		code4 => code4,
		code8 => code8,
		led4  => led4,
		led8  => led8
	);


    StimulusProcess : process
    begin

        -- Initial values
        code4 <= "00";
        code8 <= "000";
        wait for 10 ns;

        -- Test Decoder WIDTH = 4
        code4 <= "01";
        wait for 10 ns;

        code4 <= "10";
        wait for 10 ns;

        code4 <= "11";
        wait for 10 ns;


        -- Test Decoder WIDTH = 8
        code8 <= "001";
        wait for 10 ns;

        code8 <= "010";
        wait for 10 ns;

        code8 <= "011";
        wait for 10 ns;

        code8 <= "100";
        wait for 10 ns;

        code8 <= "101";
        wait for 10 ns;

        code8 <= "110";
        wait for 10 ns;

        code8 <= "111";
        wait for 10 ns;


        -- Return to zero
        code4 <= "00";
        code8 <= "000";
        wait for 10 ns;

        wait;

    end process StimulusProcess;

end architecture sim;