import random
import numpy as np

def combine(x1, x2):
	return (x1+x2*16)

fin = open("input.txt", "w")
fout = open("output.txt", "w")

PATNUM = 10000
fin.write(str(PATNUM)+"\n")

for i in range(PATNUM):
	in_mode = random.randint(0,7)
	fin.write(str(in_mode)+"\n")

	x = np.zeros(8)
	for i in range(8):
		if (in_mode%2)==1:
			a0 = random.randint(3,12)
			a1 = random.randint(3,12)
			a2 = random.randint(0,1)
			in_data = combine(a0, a1)
			fin.write(str(a2)+" ")
			fin.write(str(in_data)+" ")
			if a2==1:
				x[i] = -1 *((a1-3)*10+(a0-3))
			else:
				x[i] = (a1-3)*10+(a0-3)
		else:
			in_data = random.randint(-256,255)
			fin.write(str(in_data)+" ")
			x[i] = in_data;		
		
	fin.write("\n\n")

	if ((in_mode%4)//2)==1:
		max_data = np.amax(x)
		min_data = np.amin(x)
		if (max_data+min_data)<0 and (max_data+min_data)%2==1:
			x = x - int((max_data+min_data)/2)
		else:
			x = x - int((max_data+min_data)/2)

	if (in_mode//4)==1:
		x = np.sort(x, axis=None)

	for i in range(8):
		fout.write(str(int(x[i]))+" ")
	fout.write("\n\n")

fin.close()
fout.close()