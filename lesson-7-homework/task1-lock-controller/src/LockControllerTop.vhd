library ieee;
use ieee.std_logic_1164.all;

entity LockControllerTop is
generic
(
    --------------------------------------------------------------------
    -- Default for 50 MHz clock and approximately 20 ms debounce.
    --
    -- For ModelSim use a much smaller value such as 3.
    --------------------------------------------------------------------
    DEBOUNCE_CYCLES : positive := 1_000_000
);
port
(
    clk          : in  std_logic;
    rst          : in  std_logic;

    -- Raw value from physical buttons.
    digit_in     : in  std_logic_vector(3 downto 0);

    unlocked_led : out std_logic
);
end entity LockControllerTop;


architecture rtl of LockControllerTop is

    --------------------------------------------------------------------
    -- Signal between the debounce filter and the FSM.
    --------------------------------------------------------------------
    signal debounced_digit : std_logic_vector(3 downto 0);

begin

    --------------------------------------------------------------------
    -- PHYSICAL INPUT CONDITIONING
    --
    -- Raw physical input:
    --
    -- digit_in
    --     |
    --     v
    -- Synchronizer
    --     |
    --     v
    -- Debounce filter
    --     |
    --     v
    -- debounced_digit
    --------------------------------------------------------------------
    DebounceInstance : entity work.DigitDebounce
    generic map
    (
        STABLE_CYCLES => DEBOUNCE_CYCLES
    )
    port map
    (
        clk       => clk,
        rst       => rst,

        digit_in  => digit_in,
        digit_out => debounced_digit
    );


    --------------------------------------------------------------------
    -- LOCK FSM
    --
    -- LockController receives only the stable/debounced value.
    --
    -- Internally it compares debounced_digit with previous_digit,
    -- so the same held digit is processed only once.
    --------------------------------------------------------------------
    LockInstance : entity work.LockController
    port map
    (
        clk          => clk,
        rst          => rst,

        digit_in     => debounced_digit,

        unlocked_led => unlocked_led
    );

end architecture rtl;