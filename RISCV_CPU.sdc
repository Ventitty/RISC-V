create_clock -name board_clock -period 20.000 [get_ports board_clock]

create_generated_clock -name processor_clock \
    -source [get_ports board_clock] \
    -divide_by 2 \
    [get_registers {*clock_counter[0]}]

derive_clock_uncertainty

set_false_path -from [get_ports reset_button]
set_false_path -to [get_ports {hex_0[*] hex_1[*] hex_2[*] hex_3[*]}]
