// Purpose: Try to see if a naive str_contains() is faster than strstr().
// Result: Nope, not at all. strstr() is very well optimized.
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

bool str_contains(const char * restrict haystack, const char * restrict needle) {
	for (const char* c = haystack; *c != '\0'; c++) {
		const char* i = c;
		const char* n = needle;
		
		for (n = needle; *n != '\0'; n++) {
			if (*i != *n)
				break;
			i++;
		}
		
		if (*n == '\0')
			return true;
	}
	return false;
}

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
		if ( str_contains(line, search) ) {
			printf("%s", line);
		}
	}
	
	fclose(f);
	return 0;
}