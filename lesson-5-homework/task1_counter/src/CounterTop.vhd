library ieee;
use ieee.std_logic_1164.all;

entity CounterTop is
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
end entity CounterTop;


architecture rtl of CounterTop is

    component Counter is
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
    end component;

begin

    COUNTER_INSTANCE : Counter
    port map
    (
        clk     => clk,
        rst     => rst,
        load    => load,
        data_in => data_in,
        en      => en,
        up_down => up_down,
        count   => count
    );

end architecture rtl;