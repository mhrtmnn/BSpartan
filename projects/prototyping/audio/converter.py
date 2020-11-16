#!/bin/python3
import sys

if len(sys.argv) != 3:
	print("Number of arguments: {}, need 3!".format(len(sys.argv)))
	print("Usage: {} INFILE OUTFILE".format(sys.argv[0]))
	exit()

in_fname  = sys.argv[1]
out_fname = sys.argv[2]

o = open(out_fname, "w")
o.write("// BRAM init content\n")

with open(in_fname, "rb") as f:
	count = 0
	while (sample := f.read(2)) != b"":
		o.write("{}\n".format(sample.hex()))
		count += 1
	print("Read {} samples from {} to {}".format(count, in_fname, out_fname))
