library ieee;
use ieee.std_logic_1164.all;

entity LockController is
port
(
    clk          : in  std_logic;
    rst          : in  std_logic; -- asynchronous active-high reset

    -- Already synchronized and debounced digit.
    digit_in     : in  std_logic_vector(3 downto 0);

    unlocked_led : out std_logic
);
end entity LockController;


architecture rtl of LockController is

    --------------------------------------------------------------------
    -- FSM states
    --------------------------------------------------------------------
    type StateType is
    (
        LOCKED,
        WAIT_D2,
        WAIT_D3,
        UNLOCKED
    );


    --------------------------------------------------------------------
    -- Current and next FSM states.
    --------------------------------------------------------------------
    signal current_state : StateType;
    signal next_state    : StateType;


    --------------------------------------------------------------------
    -- Previous debounced digit.
    --
    -- digit_in remains at the last stable value after debounce.
    -- Therefore we remember the previous value and process digit_in
    -- only when:
    --
    --     digit_in /= previous_digit
    --
    -- This prevents a button which is held down for many clock cycles
    -- from being processed repeatedly by the FSM.
    --------------------------------------------------------------------
    signal previous_digit : std_logic_vector(3 downto 0);


    --------------------------------------------------------------------
    -- Unlock code: 5 -> 3 -> 7
    --------------------------------------------------------------------
    constant DIGIT_1 : std_logic_vector(3 downto 0) := "0101"; -- 5
    constant DIGIT_2 : std_logic_vector(3 downto 0) := "0011"; -- 3
    constant DIGIT_3 : std_logic_vector(3 downto 0) := "0111"; -- 7

begin

    --------------------------------------------------------------------
    -- PROCESS 1: STATE / INPUT HISTORY REGISTER
    --
    -- Sequential process.
    --
    -- current_state stores the FSM state.
    -- previous_digit stores the digit observed during the previous
    -- clock cycle.
    --
    -- Reset is asynchronous and active HIGH.
    --------------------------------------------------------------------
    StateRegisterProcess : process(clk, rst)
    begin

        if rst = '1' then

            current_state  <= LOCKED;
            previous_digit <= (others => '0');

        elsif rising_edge(clk) then

            current_state  <= next_state;
            previous_digit <= digit_in;

        end if;

    end process StateRegisterProcess;


    --------------------------------------------------------------------
    -- PROCESS 2: NEXT-STATE COMBINATIONAL LOGIC
    --
    -- IMPORTANT:
    --
    -- The FSM processes digit_in only when the debounced value changes:
    --
    --     digit_in /= previous_digit
    --
    -- If digit_in has not changed, next_state remains equal to
    -- current_state.
    --
    -- Therefore a digit which remains stable for many clock cycles
    -- does not cause repeated FSM transitions.
    --------------------------------------------------------------------
    NextStateProcess :
        process(current_state, digit_in, previous_digit)
    begin

        ----------------------------------------------------------------
        -- Default behaviour: remain in the current state.
        --
        -- This also prevents latch inference because next_state always
        -- receives a value.
        ----------------------------------------------------------------
        next_state <= current_state;


        ----------------------------------------------------------------
        -- A different debounced value represents a new digit event.
        ----------------------------------------------------------------
        if digit_in /= previous_digit then

            case current_state is

                --------------------------------------------------------
                -- Waiting for the first digit: 5
                --------------------------------------------------------
                when LOCKED =>

                    if digit_in = DIGIT_1 then

                        next_state <= WAIT_D2;

                    else

                        next_state <= LOCKED;

                    end if;


                --------------------------------------------------------
                -- First digit was correct.
                -- Waiting for second digit: 3
                --------------------------------------------------------
                when WAIT_D2 =>

                    if digit_in = DIGIT_2 then

                        next_state <= WAIT_D3;

                    else

                        -- Any wrong new digit restarts the sequence.
                        next_state <= LOCKED;

                    end if;


                --------------------------------------------------------
                -- First two digits were correct.
                -- Waiting for third digit: 7
                --------------------------------------------------------
                when WAIT_D3 =>

                    if digit_in = DIGIT_3 then

                        next_state <= UNLOCKED;

                    else

                        -- Any wrong new digit restarts the sequence.
                        next_state <= LOCKED;

                    end if;


                --------------------------------------------------------
                -- Correct code has been entered.
                --
                -- Stay unlocked until asynchronous reset.
                --------------------------------------------------------
                when UNLOCKED =>

                    next_state <= UNLOCKED;


                --------------------------------------------------------
                -- Safety fallback.
                --------------------------------------------------------
                when others =>

                    next_state <= LOCKED;

            end case;

        end if;

    end process NextStateProcess;


    --------------------------------------------------------------------
    -- PROCESS 3: OUTPUT COMBINATIONAL LOGIC
    --
    -- Moore FSM:
    -- unlocked_led depends only on current_state.
    --------------------------------------------------------------------
    OutputProcess : process(current_state)
    begin

        unlocked_led <= '0';

        if current_state = UNLOCKED then

            unlocked_led <= '1';

        end if;

    end process OutputProcess;


end architecture rtl;