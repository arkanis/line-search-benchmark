#define _GNU_SOURCE  // for memrchr()
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mman.h>


struct worker_args {
	const char* search;
	const char* start;
	const char* end;
};

void* worker_thread(void* args_ptr) {
	struct worker_args* args = args_ptr;
	size_t slice_size = args->end - args->start;
	
	printf("worker %lX slice %p - %p (%zu bytes)\n", pthread_self(), args->start, args->end, slice_size);
	int search_length = strlen(args->search);
	const char* pos = args->start;
	const char* match = NULL;
	while ( (match = strstr(pos, args->search)) ) {
		pos = match + search_length;
		// search for prev and next line breaks
		const char* start = memrchr(args->start, '\n', match - args->start);
		start = (start == NULL) ? args->start : start + 1;  // skip outputting the found line break
		const char* end = memchr(match, '\n', slice_size - (match - args->start));
		if (end == NULL)
			end = args->start + slice_size;
		printf("worker %lX %.*s\n", pthread_self(), (int)(end - start), start);
	}
	
	free(args_ptr);
	return NULL;
}


int main(int argc, char** argv) {
	if (argc != 4) {
		fprintf(stderr, "usage: %s search-term file number-of-threads\n", argv[0]);
		return 1;
	}
	
	const char* search = argv[1];
	const char* file = argv[2];
	int number_of_threads = atoi(argv[3]);
	
	
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
	
	const char* data = mmap(NULL, stats.st_size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
	if (data == MAP_FAILED) {
		perror("mmap() failed");
		exit(1);
	}
	
	
	// Slice data into number_of_threads pieces so we can search each in parallel
	pthread_t thread_ids[number_of_threads];
	int thread_i = 0;
	size_t slice_size = stats.st_size / number_of_threads;
	const char* slice_end = NULL;
	for (const char* c = data; c < data + stats.st_size; c = slice_end + 1 /* the + 1 skips the line break at the end of the line */) {
		const char* slice_start = c;
		slice_end = c + slice_size;
		slice_end = memchr(slice_end, '\n', slice_end - data);
		if (slice_end == NULL) {
			slice_end = data + stats.st_size;
		}
		// Replace the \n at the end of each slice with a \0 so strstr() stops there.
		// Yes, the last slice access one byte after the end of the mapping and writes a \0 there.
		// Yolo!
		((char*)slice_end)[0] = '\0'; 
		
		printf("slice %p - %p, %zu bytes\n", slice_start, slice_end, slice_end - slice_start);
		
		struct worker_args* args = malloc(sizeof(struct worker_args));
		*args = (struct worker_args){ .search = search, .start = slice_start, .end = slice_end };
		pthread_create(&thread_ids[thread_i], NULL, worker_thread, args);
		thread_i++;
	}
	
	for (int i = 0; i < thread_i; i++) {
		pthread_join(thread_ids[i], NULL);
	}
	
	munmap((void*)data, stats.st_size);
	close(fd);
	
	return 0;
}