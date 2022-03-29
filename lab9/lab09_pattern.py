import random
import numpy as np
import pdb

fin = open("input.txt", "w")
fout = open("output.txt", "w")

total_patnum = 100
fin.write(str(total_patnum) + '\n')

# initialize dram
dram = np.zeros((65,3), dtype=np.int32)
dram[64][2] = 1600

# check deposit
action = 8
fin.write(str(action) + '\n')
fout.write(str(dram[64][2]) + '\n')

for i in range(total_patnum):
	action = random.choice([1,2,3,4,8])
	fin.write(str(action) + '\n')

	if action==8:
		fout.write(str(dram[64][2]) + '\n')

	elif action==4:
		ID = random.randint(0,63)
		fin.write(str(ID) + ' ')
		if dram[ID][0]==0
		fout.write(str(dram[ID][0]) + ' ' + str(dram[ID][1]) + ' ' + str(dram[ID][2]) + '\n')
		dram[ID] = 0

	elif action==2:
		ID = random.randint(0,63)
		fin.write(str(ID) + ' ')
		fout.write(str(dram[ID][0]) + ' ' + str(dram[ID][1]) + ' ' + str(dram[ID][2]) + '\n')
		dram[ID] = 0







fin.close()
fout.close()