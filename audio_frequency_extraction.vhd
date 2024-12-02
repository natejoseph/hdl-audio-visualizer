library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

	type audio_buffer_type is array (0 to FFT_SIZE-1) of std_logic_vector(SAMPLE_WIDTH-1 downto 0);
	
    -- Signal declarations
    signal audio_buffer : audio_buffer_type;
    signal buffer_index : integer range 0 to FFT_SIZE-1 := 0;
	 signal output_sample_index : integer range 0 to FFT_SIZE-1 := 0;
    signal windowed_data : std_logic_vector(SAMPLE_WIDTH-1 downto 0); -- Windowed sample
    signal fft_input_ready : std_logic := '0';
    signal fft_output_valid : std_logic := '0';
    signal fft_real : std_logic_vector(SAMPLE_WIDTH-1 downto 0); -- FFT real output
    signal fft_imag : std_logic_vector(SAMPLE_WIDTH-1 downto 0); -- FFT imaginary output
    signal magnitude_internal : integer;
	 signal sop_signal : std_logic := '0';
	 signal eop_signal : std_logic := '0';
    signal fft_output_sop : std_logic := '0';
    signal fft_output_eop : std_logic := '0';
    signal fft_exp : std_logic_vector(5 downto 0) := (others => '0');
	 
    component fft is
		port (
			clk          : in  std_logic                     := 'X';             -- clk
			reset_n      : in  std_logic                     := 'X';             -- reset_n
			sink_valid   : in  std_logic                     := 'X';             -- sink_valid
			sink_ready   : out std_logic;                                        -- sink_ready
			sink_error   : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- sink_error
			sink_sop     : in  std_logic                     := 'X';             -- sink_sop
			sink_eop     : in  std_logic                     := 'X';             -- sink_eop
			sink_real    : in  std_logic_vector(23 downto 0) := (others => 'X'); -- sink_real
			sink_imag    : in  std_logic_vector(23 downto 0) := (others => 'X'); -- sink_imag
			inverse      : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- inverse
			source_valid : out std_logic;                                        -- source_valid
			source_ready : in  std_logic                     := 'X';             -- source_ready
			source_error : out std_logic_vector(1 downto 0);                     -- source_error
			source_sop   : out std_logic;                                        -- source_sop
			source_eop   : out std_logic;                                        -- source_eop
			source_real  : out std_logic_vector(23 downto 0);                    -- source_real
			source_imag  : out std_logic_vector(23 downto 0);                    -- source_imag
			source_exp   : out std_logic_vector(5 downto 0)                      -- source_exp
		);
	end component fft;

begin

    -- Buffer audio samples
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                buffer_index <= 0;
                fft_input_ready <= '0';
					 sop_signal <= '0';
					 eop_signal <= '0';
            elsif data_valid = '1' then
                audio_buffer(buffer_index) <= audio_in;
                buffer_index <= buffer_index + 1;
					 
					if buffer_index = 0 then
						sop_signal <= '1';
					else
						sop_signal <= '0';
					end if;
					
					if buffer_index = FFT_SIZE - 1 then
						eop_signal <= '1';
					else
						eop_signal <= '0';
					end if;
					 
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
    fft_core : component fft
    port map (
        clk          => clk,          --    clk.clk
        reset_n      => not reset,      --    rst.reset_n
        sink_valid   => fft_input_ready,   --   sink.sink_valid
        sink_ready   => open,   --       .sink_ready
        sink_error   => "00",   --       .sink_error
        sink_sop     => sop_signal,     --       .sink_sop
        sink_eop     => eop_signal,     --       .sink_eop
        sink_real    => windowed_data,    --       .sink_real
        sink_imag    => (others => '0'),    --       .sink_imag
        inverse      => "0",      --       .inverse
        source_valid => fft_output_valid, -- source.source_valid
        source_ready => '1', --       .source_ready
        source_error => open, --       .source_error
        source_sop   => fft_output_sop,   --       .source_sop
        source_eop   => fft_output_eop,   --       .source_eop
        source_real  => fft_real,  --       .source_real
        source_imag  => fft_imag,  --       .source_imag
        source_exp   => fft_exp    --       .source_exp
    );

    -- Calculate magnitude (|FFT(real, imag)|)
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                output_sample_index <= 0;
                fft_output_sop <= '0';
                fft_output_eop <= '0';
                fft_exp <= (others => '0');
            elsif fft_output_valid = '1' then
                -- Abstracted: Use a function or external module to compute magnitude
                -- Placeholder: Assign the real output as magnitude (for simplicity)
                magnitude_internal <= to_integer(unsigned(fft_real)) ** 2 + to_integer(unsigned(fft_imag)) ** 2;

                -- actual_magnitude <= magnitude_internal * (2 ** to_integer(unsigned(fft_exp)));

                if output_sample_index = 0 then
                    fft_output_sop <= '1';
                else
                    fft_output_sop <= '0';
                end if;

                if output_sample_index = FFT_SIZE-1 then
                    fft_output_eop <= '1';
                else
                    fft_output_eop <= '0';
                end if;

                if output_sample_index < FFT_SIZE-1 then
                    output_sample_index <= output_sample_index + 1;
                else
                    output_sample_index <= 0;
                end if;
            end if;
        end if;
    end process;

    -- Map outputs
    magnitude <= magnitude_internal;
    frequency_bin <= buffer_index;

end Behavioral;
