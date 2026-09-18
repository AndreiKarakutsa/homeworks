library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ExprPipelined is
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
end entity ExprPipelined;


architecture rtl of ExprPipelined is

    --------------------------------------------------------------------
    -- Stage 0 registers
    --------------------------------------------------------------------
    signal a_reg : unsigned(7 downto 0);
    signal b_reg : unsigned(7 downto 0);
    signal c_reg : unsigned(7 downto 0);
    signal d_reg : unsigned(7 downto 0);


    --------------------------------------------------------------------
    -- Stage 1 pipeline registers
    --------------------------------------------------------------------
    signal stage1  : unsigned(15 downto 0);
    signal d_stage : unsigned(7 downto 0);


    --------------------------------------------------------------------
    -- Stage 2 output register
    --------------------------------------------------------------------
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
    -- (a_reg + b_reg) * c_reg
    --
    -- Pipeline d_reg alongside the calculation so that d_stage belongs
    -- to the same input sample as stage1.
    --------------------------------------------------------------------
    Stage1Process : process(clk, rst)

        variable sum_v     : unsigned(8 downto 0);
        variable product_v : unsigned(16 downto 0);

    begin
        if rst = '1' then
            stage1  <= (others => '0');
            d_stage <= (others => '0');

        elsif rising_edge(clk) then

            sum_v :=
                resize(a_reg, 9) +
                resize(b_reg, 9);

            product_v :=
                sum_v * c_reg;

            stage1 <=
                resize(product_v, stage1'length);

            -- Delay d by the same pipeline stage.
            d_stage <= d_reg;

        end if;
    end process Stage1Process;


    --------------------------------------------------------------------
    -- Stage 2:
    --
    -- Short combinational path:
    --
    -- stage1 ----\
    --              SUBTRACT -> result_reg
    -- d_stage ---/
    --------------------------------------------------------------------
    OutputRegisterProcess : process(clk, rst)
    begin
        if rst = '1' then
            result_reg <= (others => '0');

        elsif rising_edge(clk) then

            result_reg <=
                stage1 - resize(d_stage, stage1'length);

        end if;
    end process OutputRegisterProcess;


    result <= std_logic_vector(result_reg);

end architecture rtl;