import sys, mmap

search = bytes(sys.argv[1], 'utf-8')
file = sys.argv[2]

with open(file) as f:
    with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
        while ( (line := mm.readline()) != b"" ):
            if line.find(search) != -1:
                print(line)