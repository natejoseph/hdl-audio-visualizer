set_global_assignment -entity "pll_0" -library "lib_pll_0" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_0" -library "lib_pll_0" -name IP_TOOL_VERSION "21.1"
set_global_assignment -entity "pll_0" -library "lib_pll_0" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_0" -name SPD_FILE [file join $::quartus(sip_path) "pll_0.spd"]

set_global_assignment -library "lib_pll_0" -name MISC_FILE [file join $::quartus(sip_path) "pll_0_sim/pll_0.vho"]
