library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ExprPlain is
port
(
    clk    : in  std_logic;
    rst    : in  std_logic;

    a      : in  std_logic_vector(7 downto 0);
    b      : in  std_logic_vector(7 downto 0);
    c      : in  std_logic_vector(7 downto 0);
    d      : in  std_logic_vector(7 downto 0);

    result : out std_logic_vector(15 downto 0)
);
end entity ExprPlain;


architecture rtl of ExprPlain is

    -- Stage 0: registered inputs
    signal a_reg : unsigned(7 downto 0);
    signal b_reg : unsigned(7 downto 0);
    signal c_reg : unsigned(7 downto 0);
    signal d_reg : unsigned(7 downto 0);

    signal result_reg : unsigned(15 downto 0);

begin

    --------------------------------------------------------------------
    -- Stage 0: input registers
    --------------------------------------------------------------------
    InputRegisterProcess : process(clk, rst)
    begin
        if rst = '1' then
            a_reg <= (others => '0');
            b_reg <= (others => '0');
            c_reg <= (others => '0');
            d_reg <= (others => '0');

        elsif rising_edge(clk) then
            a_reg <= unsigned(a);
            b_reg <= unsigned(b);
            c_reg <= unsigned(c);
            d_reg <= unsigned(d);
        end if;
    end process InputRegisterProcess;


    --------------------------------------------------------------------
    -- Stage 1:
    --
    -- Long combinational path:
    --
    -- a_reg ----\
    --             ADD -> MULTIPLY -> SUBTRACT -> result_reg
    -- b_reg ----/          ^              ^
    --                     c_reg          d_reg
    --------------------------------------------------------------------
    OutputRegisterProcess : process(clk, rst)

        variable sum_v     : unsigned(8 downto 0);
        variable product_v : unsigned(16 downto 0);
        variable d_v       : unsigned(16 downto 0);

    begin
        if rst = '1' then
            result_reg <= (others => '0');

        elsif rising_edge(clk) then

            sum_v :=
                resize(a_reg, 9) +
                resize(b_reg, 9);

            product_v :=
                sum_v * c_reg;

            d_v :=
                resize(d_reg, 17);

            result_reg <=
                resize(product_v - d_v, result_reg'length);

        end if;
    end process OutputRegisterProcess;


    result <= std_logic_vector(result_reg);

end architecture rtl;