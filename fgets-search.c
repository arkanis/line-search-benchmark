// Compile with: gcc -std=c99 -Wall -Wextra -O2 fgets-search.c -o fgets-search
#include <stdio.h>
#include <string.h>

int main(int argc, char** argv) {
	if (argc != 3) {
		fprintf(stderr, "usage: %s search-term file\n", argv[0]);
		return 1;
	}
	
	const char* search = argv[1];
	const char* file = argv[2];
	
	FILE* f = fopen(file, "rb");
	if (f == NULL) {
		perror("fopen() failed");
		return 1;
	}
	
	char line[2048];
	while ( fgets(line, sizeof(line), f) ) {
		if ( strstr(line, search) ) {
			printf("%s", line);
		}
	}
	
	fclose(f);
	return 0;
}