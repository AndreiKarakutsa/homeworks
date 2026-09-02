library ieee;
use ieee.std_logic_1164.all;

entity DecoderTop is
	port (
		code4 : in  std_logic_vector(1 downto 0);
      code8 : in  std_logic_vector(2 downto 0);

      led4  : out std_logic_vector(3 downto 0);
      led8  : out std_logic_vector(7 downto 0)
	);
end entity DecoderTop;

architecture rtl of DecoderTop is

	component Decoder is
	generic (
		WIDTH : positive := 4
	);
	port (
		code			: in  std_logic_vector;
		decoded		: out std_logic_vector(WIDTH - 1 downto 0)
	);
	end component;
	 
begin
	
	DECODER_4 : Decoder
	generic map
	(
		WIDTH => 4
	)
   port map
	(
		code		=> code4,
		decoded	=> led4
	);

	DECODER_8 : Decoder
   generic map 
	(
		WIDTH => 8
	)
   port map 
	(
		code		=> code8,
		decoded	=> led8
	);

end rtl;