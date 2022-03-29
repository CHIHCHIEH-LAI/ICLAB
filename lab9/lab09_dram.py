import random
import numpy as np
import pdb

def Dec_to_Hex(x_dec):
	x_hex = hex(x_dec)
	return x_hex

f = open("dram.dat", "w")

for i in range(65536, 65536+64*4, 4):
	
	# address
	addr_hex = Dec_to_Hex(i)[2:7]
	f.write("@"+addr_hex)

	f.write('\n')

	# land ID
	land_hex = Dec_to_Hex(i//4)[4:6]
	f.write(land_hex)
	f.write(' ')

	# status
	f.write('0')

	# crop category
	# crop_hex = Dec_to_Hex(i)[6]
	# f.write(crop_hex)
	f.write('0')
	f.write(' ')

	# water amount
	f.write('00' + ' ' + '00')

	f.write('\n')

addr_hex = Dec_to_Hex(65536+64*4)[2:7]
f.write('@' + addr_hex)

f.write('\n')

f.write('00 10 00 00')

f.close()

# land = random.randint(0,64)
# land_hex = Dec_to_Hex(land)
# f.write(land_hex + ' ')

# status = random.randint(0,1)
# crop = random.randint(0,1)

# f.write(str(status) + str(crop) + ' ')

# water = random.randint(0, (16**4)-1)
# water_hex = Dec_to_Hex(water)
# f.write(water_hex)