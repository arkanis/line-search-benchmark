// Compile with: gcc -std=c99 -Wall -Wextra -O2 fgets-search-opt2.c -o fgets-search-opt2
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>


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
	
	/**
	
	1st algorithm sketch
	====================
	
	for each line
		for each char
			end_char == char + search_length
			advance to next line if char == \n or end_char == \n
			advance to next char if char != search_char or end_char != search_end_char
			increment test depth
			...
	
	→ Got to complicated to think about. Lines not a good abstraction for algo.
	
	
	2nd algorithm sketch
	====================
	
	c is content pointer
		if c + search_length == \n
			skip rest of line: c = c + search_length + 1
		if (c - data) + search_length >= stats.st_size
			exit, last match char would be beyond EOF, no more matches possible
		check if chars from c to search_length - 1 match
			advance to next char if no complete match: c++
			print from line start to match end if complete match
	
	**/	
	
	const char* c = data;
	const char* line_start = c;
	while (true) {
		if ( *(c + search_length) == '\n' ) {
			c += search_length + 1;  // the + 1 skips the '\n'
			line_start = c;
			continue;
		}
		
		if ( (c - data) + search_length >= stats.st_size ) {
			break;
		}
		
		int i;
		for (i = 0; i < search_length; i++) {
			if (c[i] != search[i])
				break;
		}
		if (i == search_length) {
			// Found one!
			printf("%.*s\n", (int)(c + search_length - line_start), line_start);
			c += search_length;
		} else {
			// No hit, try next char
			c++;
		}
	}
	
	
	munmap((void*)data, stats.st_size);
	close(fd);
	
	return 0;
}