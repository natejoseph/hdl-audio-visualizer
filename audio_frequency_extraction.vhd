library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity audio_frequency_extraction is
    generic (
        SAMPLE_WIDTH : integer := 24;   -- Audio sample width (bits)
        FFT_SIZE     : integer := 1024 -- FFT size (must be a power of 2)
    );
    port (
        clk              : in  std_logic;                -- System clock
        reset            : in  std_logic;                -- Reset signal
        audio_in         : in  std_logic_vector(SAMPLE_WIDTH-1 downto 0); -- Input audio data
        data_valid       : in  std_logic;                -- Indicates valid input sample
        fft_start        : out std_logic;                -- Signal to start FFT
        frequency_bin    : out integer range 0 to FFT_SIZE/2-1; -- Frequency bin index
        magnitude        : out integer;                 -- Magnitude of the frequency bin
        fft_done         : out std_logic                 -- Indicates FFT is complete
    );
end audio_frequency_extraction;

architecture Behavioral of audio_frequency_extraction is

    -- Signal declarations
    signal audio_buffer : array (0 to FFT_SIZE-1) of std_logic_vector(SAMPLE_WIDTH-1 downto 0);
    signal buffer_index : integer range 0 to FFT_SIZE-1 := 0;
    signal windowed_data : std_logic_vector(SAMPLE_WIDTH-1 downto 0); -- Windowed sample
    signal fft_input_ready : std_logic := '0';
    signal fft_output_valid : std_logic := '0';
    signal fft_real : std_logic_vector(SAMPLE_WIDTH-1 downto 0); -- FFT real output
    signal fft_imag : std_logic_vector(SAMPLE_WIDTH-1 downto 0); -- FFT imaginary output
    signal magnitude_internal : integer;

begin

    -- Buffer audio samples
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                buffer_index <= 0;
                fft_input_ready <= '0';
            elsif data_valid = '1' then
                audio_buffer(buffer_index) <= audio_in;
                buffer_index <= buffer_index + 1;

                -- Check if the buffer is full
                if buffer_index = FFT_SIZE-1 then
                    buffer_index <= 0;
                    fft_input_ready <= '1';
                end if;
            end if;
        end if;
    end process;

    -- Apply windowing function (e.g., Hamming or Hann)
    -- Abstracted: Replace with actual multiplication logic for applying window coefficients
    process (clk)
    begin
        if rising_edge(clk) then
            if fft_input_ready = '1' then
                -- Multiply the buffered sample by a window coefficient
                -- Placeholder: Directly use the buffered sample for simplicity
                windowed_data <= audio_buffer(buffer_index);
            end if;
        end if;
    end process;

    -- Instantiate FFT core
    -- Abstracted: Use an external FFT IP or core
    -- The FFT core accepts windowed audio data and produces frequency-domain data
    fft_core : entity work.fft_ip
        generic map (
            DATA_WIDTH => SAMPLE_WIDTH,
            FFT_SIZE   => FFT_SIZE
        )
        port map (
            clk               => clk,
            reset             => reset,
            data_in           => windowed_data,
            start             => fft_input_ready,
            real_out          => fft_real,
            imag_out          => fft_imag,
            valid             => fft_output_valid,
            done              => fft_done
        );

    -- Calculate magnitude (|FFT(real, imag)|)
    process (clk)
    begin
        if rising_edge(clk) then
            if fft_output_valid = '1' then
                -- Abstracted: Use a function or external module to compute magnitude
                -- Placeholder: Assign the real output as magnitude (for simplicity)
                magnitude_internal <= to_integer(unsigned(fft_real)); -- Simplified
            end if;
        end if;
    end process;

    -- Map outputs
    magnitude <= magnitude_internal;
    frequency_bin <= buffer_index;

end Behavioral;
