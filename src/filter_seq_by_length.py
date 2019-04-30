#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import sys
from collections import OrderedDict

args = sys.argv
reader1 = args[1]
reader2 = args[2]
mydict = OrderedDict()
seqlength = []
flag = 1

with open(reader1) as fh:
	for line in fh:
		if line.startswith(">"):
			name = line.strip().split()[0][1:]
			mydict[name] = []
		else: 
			mydict[name].append(line.strip().rstrip("*"))

for key,value in mydict.items():
	values = "".join(value)
	values = values.replace("U","-").replace("u","-")
	length = len(values)
	#print(key,length)
	if length < int(reader2):
		seqlength.append(0)
	else:
		seqlength.append(1)

if seqlength.count(0) >= 3:
	flag = 0
else:
	flag = 1
print(flag)
