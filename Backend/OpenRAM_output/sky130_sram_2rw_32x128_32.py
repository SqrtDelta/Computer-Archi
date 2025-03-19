"""
Single ported RAM
"""
word_size = 32 # Bits
num_words = 128
human_byte_size = "{:.0f}kbytes".format((word_size * num_words)/1024/8)
write_size = word_size # Bits

# Single port
num_rw_ports = 2
num_r_ports = 0
num_w_ports = 0
# num_spare_rows= 1 # required only in 1rw case
# num_spare_cols= 1 # requires only for 1rw case
ports_human = '2rw'

tech_name = "sky130"
nominal_corner_only = True

route_supplies = "ring"
uniquify = True

output_name = f"sky130_sram_{ports_human}_{word_size}x{num_words}_{write_size}"
output_path = "./OpenRAM"
