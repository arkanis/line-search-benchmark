// Purpose: Thinking the other way around. We search the entire file as one mmaped string with strstr(). When we found
// a match we search for the start and end of the line to output the matching line.
// Takes the performance of strstr() and adds as little overheade as possible.
// Result: Quite fast, even faster than grep.
#define _GNU_SOURCE  // for memrchr()
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mman.h>


int main(int argc, char** argv) {
	if (argc != 3) {
		fprintf(stderr, "usage: %s search-term file\n", argv[0]);
		return 1;
	}
	
	const char* search = argv[1];
	const char* file = argv[2];
	
	
	int fd = open(file, O_RDONLY);
	if ( fd == -1 ) {
		perror("open() failed");
		exit(1);
	}
	
	struct stat stats;
	if ( fstat(fd, &stats) == -1 ) {
		perror("fstat() failed");
		exit(1);
	}
	
	const char* data = mmap(NULL, stats.st_size, PROT_READ, MAP_SHARED, fd, 0);
	if (data == MAP_FAILED) {
		perror("mmap() failed");
		exit(1);
	}
	
	
	int search_length = strlen(search);
	const char* pos = data;
	const char* match = NULL;
	while ( (match = strstr(pos, search)) ) {
		pos = match + search_length;
		// search for prev and next line breaks
		const char* start = memrchr(data, '\n', match - data);
		start = (start == NULL) ? data : start + 1;  // skip outputting the found line break
		const char* end = memchr(match, '\n', stats.st_size - (match - data));
		if (end == NULL)
			end = data + stats.st_size;
		printf("%.*s\n", (int)(end - start), start);
	}
	
	
	munmap((void*)data, stats.st_size);
	close(fd);
	
	return 0;
}