	component pqs is
		port (
			pll_0_outclk0_clk : out std_logic;        -- clk
			pll_0_refclk_clk  : in  std_logic := 'X'; -- clk
			pll_0_reset_reset : in  std_logic := 'X'  -- reset
		);
	end component pqs;

	u0 : component pqs
		port map (
			pll_0_outclk0_clk => CONNECTED_TO_pll_0_outclk0_clk, -- pll_0_outclk0.clk
			pll_0_refclk_clk  => CONNECTED_TO_pll_0_refclk_clk,  --  pll_0_refclk.clk
			pll_0_reset_reset => CONNECTED_TO_pll_0_reset_reset  --   pll_0_reset.reset
		);

