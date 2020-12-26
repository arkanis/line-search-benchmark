import sys

search = sys.argv[1]
file = sys.argv[2]

with open(file) as f:
    while ( (line := f.readline()) != "" ):
        if line.find(search) != -1:
            print(line)