import sys, mmap

search = bytes(sys.argv[1], 'utf-8')
file = sys.argv[2]

with open(file) as f:
    with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
        
        pos = 0
        while ( (pos := mm.find(search, pos)) != -1 ):
            start = mm.rfind(b"\n", 0, pos)
            if start == -1:
                start = 0
            end = mm.find(b"\n", pos)
            print(mm[start:end])
            
            pos += len(search)
