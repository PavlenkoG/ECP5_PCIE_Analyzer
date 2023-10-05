import os
import sys
import csv
import operator

reader = csv.reader(open("out.csv"), delimiter=",")

sortedlist = sorted(reader,  key=lambda row: int(row[1]), reverse=False)

f = open("out_sorted.csv", 'w', newline='')
writer = csv.writer(f)
writer.writerows(sortedlist)
