library ieee;
use ieee.std_logic_1164.all;

entity DigitDebounce is
generic
(
    -- Number of consecutive clock cycles during which the complete
    -- 4-bit input must remain unchanged before it is accepted.
    --
    -- Example:
    --   clk = 50 MHz
    --   debounce time = 20 ms
    --
    --   STABLE_CYCLES = 50_000_000 * 0.020
    --                 = 1_000_000
    --
    -- For simulation, use a much smaller value, for example 3 or 4.
    STABLE_CYCLES : positive := 1_000_000
);
port
(
    clk       : in  std_logic;
    rst       : in  std_logic; -- asynchronous active-high reset

    -- Raw asynchronous value coming from physical button logic.
    digit_in  : in  std_logic_vector(3 downto 0);

    -- Stable debounced value.
    digit_out : out std_logic_vector(3 downto 0)
);
end entity DigitDebounce;


architecture rtl of DigitDebounce is

    --------------------------------------------------------------------
    -- Two-stage synchronizer.
    --
    -- Physical buttons are asynchronous relative to the FPGA clock.
    -- The two registers reduce the probability of metastability
    -- propagating into the debounce logic.
    --
    -- IMPORTANT:
    -- Synchronizing every bit of a multi-bit bus does not by itself
    -- guarantee that all bits belong to the same input transition.
    -- Therefore, after synchronization, the complete 4-bit value is
    -- required to remain unchanged for STABLE_CYCLES clock cycles.
    --------------------------------------------------------------------
    signal sync_0 : std_logic_vector(3 downto 0);
    signal sync_1 : std_logic_vector(3 downto 0);


    --------------------------------------------------------------------
    -- candidate_digit
    --
    -- The synchronized value currently being tested for stability.
    --------------------------------------------------------------------
    signal candidate_digit : std_logic_vector(3 downto 0);


    --------------------------------------------------------------------
    -- stable_digit
    --
    -- The last value which successfully passed the debounce filter.
    --------------------------------------------------------------------
    signal stable_digit : std_logic_vector(3 downto 0);


    --------------------------------------------------------------------
    -- Number of consecutive clocks during which candidate_digit
    -- has remained unchanged.
    --------------------------------------------------------------------
    signal stable_counter : integer range 0 to STABLE_CYCLES;

begin

    --------------------------------------------------------------------
    -- PROCESS 1: INPUT SYNCHRONIZER
    --
    -- digit_in comes from physical hardware and is therefore
    -- asynchronous relative to clk.
    --
    -- sync_0 is the first synchronization stage.
    -- sync_1 is the second synchronization stage and is used by
    -- the debounce logic.
    --------------------------------------------------------------------
    SynchronizerProcess : process(clk, rst)
    begin

        if rst = '1' then

            sync_0 <= (others => '0');
            sync_1 <= (others => '0');

        elsif rising_edge(clk) then

            sync_0 <= digit_in;
            sync_1 <= sync_0;

        end if;

    end process SynchronizerProcess;


    --------------------------------------------------------------------
    -- PROCESS 2: DEBOUNCE / STABILITY FILTER
    --
    -- Algorithm:
    --
    -- 1. Compare the synchronized input with candidate_digit.
    --
    -- 2. If the value changes:
    --      - remember the new candidate;
    --      - reset the stability counter.
    --
    -- 3. If the value remains unchanged:
    --      - increment stable_counter.
    --
    -- 4. Only when the same complete 4-bit value has remained
    --    unchanged for STABLE_CYCLES clocks is it copied to
    --    stable_digit.
    --
    -- Example of contact bounce:
    --
    -- raw input:
    --
    --     5  4  5  4  5  5  5  5  5
    --
    -- Every 5/4 transition resets the counter.
    --
    -- Only after the final value 5 remains stable long enough:
    --
    --     stable_digit <= 5
    --
    -- Therefore temporary values caused by mechanical contact bounce
    -- are not passed to LockController.
    --------------------------------------------------------------------
    DebounceProcess : process(clk, rst)
    begin

        if rst = '1' then

            candidate_digit <= (others => '0');
            stable_digit    <= (others => '0');
            stable_counter  <= 0;

        elsif rising_edge(clk) then

            if sync_1 /= candidate_digit then

                --------------------------------------------------------
                -- A different value appeared.
                --
                -- It may be the beginning of a real new digit or
                -- simply mechanical bounce.
                --
                -- Store it as the new candidate and start measuring
                -- its stability from the beginning.
                --------------------------------------------------------
                candidate_digit <= sync_1;
                stable_counter  <= 0;

            else

                --------------------------------------------------------
                -- The synchronized input is still equal to the
                -- candidate.
                --
                -- Continue counting how long it remains unchanged.
                --------------------------------------------------------
                if stable_counter < STABLE_CYCLES then

                    stable_counter <= stable_counter + 1;

                end if;


                --------------------------------------------------------
                -- The candidate has remained unchanged for the
                -- required number of clock cycles.
                --
                -- Accept it as the new stable/debounced digit.
                --------------------------------------------------------
                if stable_counter = STABLE_CYCLES - 1 then

                    stable_digit <= candidate_digit;

                end if;

            end if;

        end if;

    end process DebounceProcess;


    --------------------------------------------------------------------
    -- digit_out keeps the last accepted stable value until another
    -- value successfully passes the debounce filter.
    --------------------------------------------------------------------
    digit_out <= stable_digit;

end architecture rtl;