// Compile with: gcc -std=c99 -pthread -Wall -Wextra -g search-parallel.c -o search-parallel
#define _GNU_SOURCE  // for memrchr()
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

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
		printf("worker %lX at %p: %.*s\n", pthread_self(), match, (int)(end - start), start);
	}
	
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
	
	const char* data = mmap(NULL, stats.st_size, PROT_READ, MAP_SHARED, fd, 0);
	if (data == MAP_FAILED) {
		perror("mmap() failed");
		exit(1);
	}
	
	
	// Slice data into number_of_threads pieces so we can search each in parallel
	struct {
		pthread_t id;
		struct worker_args args;
	} threads[number_of_threads];
	int thread_count = 0;
	
	size_t slice_size = stats.st_size / number_of_threads;
	const char* slice_end = NULL;
	for (const char* slice_start = data; slice_start < data + stats.st_size; slice_start = slice_end + 1 /* the + 1 skips the line break at the end of the line */) {
		slice_end = slice_start + slice_size;
		slice_end = memchr(slice_end, '\n', slice_end - data);
		if (slice_end == NULL) {
			slice_end = data + stats.st_size;
		}
		
		size_t map_length = slice_end - data;
		const char* map_start = mmap(NULL, map_length, PROT_READ, MAP_SHARED, fd, 0);
		if (map_start == MAP_FAILED) {
			perror("mmap() failed");
			exit(1);
		}
		
		printf("slice %p - %p, %zu bytes, map %p %zu bytes\n",
			slice_start, slice_end, slice_end - slice_start,
			map_start, map_length
		);
		
		threads[thread_count].args = (struct worker_args){
			.search = search,
			.start = map_start + (slice_start - data),
			.end = map_start + (slice_end - data)
		};
		pthread_create(&threads[thread_count].id, NULL, worker_thread, &threads[thread_count].args);
		thread_count++;
	}
	
	for (int i = 0; i < thread_count; i++) {
		pthread_join(threads[i].id, NULL);
	}
	
	munmap((void*)data, stats.st_size);
	close(fd);
	
	return 0;
}