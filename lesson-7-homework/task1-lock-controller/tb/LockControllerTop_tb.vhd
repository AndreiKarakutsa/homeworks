library ieee;
use ieee.std_logic_1164.all;

entity LockControllerTop_tb is
end entity LockControllerTop_tb;


architecture sim of LockControllerTop_tb is

    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal digit_in     : std_logic_vector(3 downto 0) := (others => '0');
    signal unlocked_led : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    --------------------------------------------------------------------
    -- DUT
    --
    -- Use only 3 stable clocks for debounce in simulation.
    --------------------------------------------------------------------
    DUT : entity work.LockControllerTop
    generic map
    (
        DEBOUNCE_CYCLES => 3
    )
    port map
    (
        clk          => clk,
        rst          => rst,
        digit_in     => digit_in,
        unlocked_led => unlocked_led
    );


    --------------------------------------------------------------------
    -- 100 MHz clock
    --------------------------------------------------------------------
    ClockProcess : process
    begin

        clk <= '0';
        wait for CLK_PERIOD / 2;

        clk <= '1';
        wait for CLK_PERIOD / 2;

    end process ClockProcess;


    --------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------
    StimulusProcess : process
    begin

        ----------------------------------------------------------------
        -- TEST 1: ASYNCHRONOUS RESET
        ----------------------------------------------------------------
        report "TEST 1: Asynchronous reset";

        rst <= '1';

        wait for 3 ns;

        assert unlocked_led = '0'
            report "FAIL: LED must be OFF during reset"
            severity error;

        rst <= '0';

        report "PASS: Asynchronous reset";


        ----------------------------------------------------------------
        -- Wait before first physical button activity.
        ----------------------------------------------------------------
        wait for 20 ns;


        ----------------------------------------------------------------
        -- TEST 2:
        -- FIRST DIGIT = 5 WITH CONTACT BOUNCE
        --
        -- Simulate unstable physical button transitions:
        --
        -- 5 -> 4 -> 5 -> 4 -> 5
        --
        -- Only the final stable 5 must pass the debounce filter.
        ----------------------------------------------------------------
        report "TEST 2: First digit 5 with bounce";

        digit_in <= "0101"; -- 5
        wait for 10 ns;

        digit_in <= "0100"; -- temporary bounce
        wait for 10 ns;

        digit_in <= "0101"; -- 5
        wait for 10 ns;

        digit_in <= "0100"; -- temporary bounce
        wait for 10 ns;

        digit_in <= "0101"; -- final stable 5


        ----------------------------------------------------------------
        -- Keep 5 stable long enough to pass:
        -- synchronizer + debounce.
        ----------------------------------------------------------------
        wait for 100 ns;


        assert unlocked_led = '0'
            report "FAIL: controller unlocked after first digit"
            severity error;

        report "PASS: First digit accepted";


        ----------------------------------------------------------------
        -- IMPORTANT TEST:
        --
        -- Continue holding 5.
        --
        -- LockController must NOT process the same 5 repeatedly.
        ----------------------------------------------------------------
        report "TEST 3: Hold first digit";

        wait for 100 ns;

        assert unlocked_led = '0'
            report "FAIL: held digit caused incorrect FSM behaviour"
            severity error;

        report "PASS: Held digit is not processed repeatedly";


        ----------------------------------------------------------------
        -- TEST 4:
        -- SECOND DIGIT = 3 WITH BOUNCE
        ----------------------------------------------------------------
        report "TEST 4: Second digit 3 with bounce";

        digit_in <= "0011"; -- 3
        wait for 10 ns;

        digit_in <= "0010"; -- bounce
        wait for 10 ns;

        digit_in <= "0011"; -- 3
        wait for 10 ns;

        digit_in <= "0010"; -- bounce
        wait for 10 ns;

        digit_in <= "0011"; -- final stable 3

        wait for 100 ns;


        assert unlocked_led = '0'
            report "FAIL: controller unlocked after only two digits"
            severity error;

        report "PASS: Second digit accepted";


        ----------------------------------------------------------------
        -- TEST 5:
        -- THIRD DIGIT = 7 WITH BOUNCE
        ----------------------------------------------------------------
        report "TEST 5: Third digit 7 with bounce";

        digit_in <= "0111"; -- 7
        wait for 10 ns;

        digit_in <= "0110"; -- bounce
        wait for 10 ns;

        digit_in <= "0111"; -- 7
        wait for 10 ns;

        digit_in <= "0110"; -- bounce
        wait for 10 ns;

        digit_in <= "0111"; -- final stable 7

        wait for 100 ns;


        ----------------------------------------------------------------
        -- Correct sequence 5 -> 3 -> 7 must unlock.
        ----------------------------------------------------------------
        assert unlocked_led = '1'
            report "FAIL: correct code 5-3-7 did not unlock"
            severity error;

        report "PASS: Correct code 5-3-7 unlocked controller";


        ----------------------------------------------------------------
        -- TEST 6:
        -- UNLOCKED must remain UNLOCKED.
        ----------------------------------------------------------------
        report "TEST 6: Stay unlocked";

        digit_in <= "0010";
        wait for 100 ns;

        assert unlocked_led = '1'
            report "FAIL: controller left UNLOCKED state"
            severity error;

        report "PASS: Controller remains UNLOCKED";


        ----------------------------------------------------------------
        -- TEST 7:
        -- Reset after unlock.
        ----------------------------------------------------------------
        report "TEST 7: Reset after unlock";

        rst <= '1';

        -- Asynchronous reset: no clock edge is required.
        wait for 3 ns;

        assert unlocked_led = '0'
            report "FAIL: reset did not lock controller"
            severity error;

        rst <= '0';

        report "PASS: Reset after unlock";


        ----------------------------------------------------------------
        -- TEST 8:
        -- Wrong sequence: 5 -> 9
        ----------------------------------------------------------------
        wait for 20 ns;

        report "TEST 8: Wrong digit";


        -- 5
        digit_in <= "0101";
        wait for 100 ns;


        -- Wrong second digit = 9
        digit_in <= "1001";
        wait for 100 ns;


        assert unlocked_led = '0'
            report "FAIL: wrong sequence unlocked controller"
            severity error;

        report "PASS: Wrong digit returns controller to LOCKED";


        ----------------------------------------------------------------
        -- End simulation
        ----------------------------------------------------------------
        report "ALL TESTS COMPLETED";

        wait;

    end process StimulusProcess;

end architecture sim;