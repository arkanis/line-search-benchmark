// Purpose: Seems like we might be CPU time limited or multiple cores can use more memory bandwith than just one core.
// Divide the entire file into n slices and search each one in parallel with threads.
// We need to take some care to make sure that each slice is zero-terminated. We insert the \0 between slices and use a
// mmap() trick to get the last \0 after the mapped file data.
// Result: Looks like we get linear speedup until we get memory bandwith limited. Nice. :)
#define _GNU_SOURCE  // for memrchr()
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/stat.h>
#include <sys/mman.h>



struct worker_args {
	const char* search;
	const char* slice_start;
	const char* slice_end;
};

void* worker_thread(void* args_ptr) {
	struct worker_args* args = args_ptr;
	//printf("[worker %lX] slice: %p - %p, %zu bytes\n", pthread_self(), args->slice_start, args->slice_end, args->slice_end - args->slice_start);
	
	int search_length = strlen(args->search);
	const char* pos = args->slice_start;
	const char* match = NULL;
	while ( (match = strstr(pos, args->search)) ) {
		pos = match + search_length;
		// search for prev and next line breaks
		const char* start = memrchr(args->slice_start, '\n', match - args->slice_start);
		start = (start == NULL) ? args->slice_start : start + 1;  // skip outputting the found line break
		const char* end = memchr(match, '\n', args->slice_end - match);
		if (end == NULL)
			end = args->slice_end;
		printf("[worker %lX] %.*s\n", pthread_self(), (int)(end - start), start);
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
	
	// Map the entire file + 1 byte at the end. That byte will automatically be zero-filled (accoring to
	// https://stackoverflow.com/a/32255592). We need it since the strstr() of the last thread needs a zero-terminator,
	// too.
	size_t data_size = stats.st_size;
	char* data_start = mmap(NULL, data_size + 1, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
	char* data_end = data_start + data_size;
	if (data_start == MAP_FAILED) {
		perror("mmap() failed");
		exit(1);
	}
	//printf("data: %p - %p, %zu bytes\n", data_start, data_end, data_size);
	
	
	// Slice data into number_of_threads pieces (or fewer if there isn't enough data) so we can search each in parallel
	struct {
		pthread_t id;
		struct worker_args args;
	} threads[number_of_threads];
	int thread_count = 0;
	
	size_t slice_size = data_size / number_of_threads;
	char* slice_start = NULL;
	char* slice_end = NULL;
	for (slice_start = data_start; slice_start < data_end; slice_start = slice_end + 1 /* the +1 skips the \0 at the end of the previous slice */) {
		// Start at the ideal slice_end and then search for the next \n
		slice_end = slice_start + slice_size;
		if (slice_end < data_end) {
			// Only search for the next \n if we're not already at the end of the last slice
			slice_end = memchr(slice_end, '\n', data_end - slice_end);
			if (slice_end == NULL) {
				// No \n found in the remaining data, we're at the end of the last slice
				slice_end = data_end;
			} else {
				// Replace the \n at the end of each slice with a \0 so strstr() stops there. The mapping is writable and
				// private so the changes are not saved to disk. This causes a segfault for the last slice since we try to
				// write beyond the file that backs the mapping. But we mapped one byte more than the file size and linux
				// fills bytes beyond the file size with zeros. So we already have our zero-terminator.
				slice_end[0] = '\0';
			}
		} else {
			slice_end = data_end;
		}
		
		//printf("slice %d: %p - %p, %zu bytes\n", thread_count, slice_start, slice_end, slice_end - slice_start);
		
		threads[thread_count].args = (struct worker_args){
			.search = search,
			.slice_start = slice_start,
			.slice_end = slice_end
		};
		thread_count++;
	}
	
	// Change all pages in the memory mapping to read-only to avoid overhead (doesn't seem necessary though)
	if ( mprotect(data_start, data_size + 1, PROT_READ) == -1 ) {
		perror("fstat() failed");
		exit(1);
	}
	
	// Spawn threads
	for (int i = 0; i < thread_count; i++)
		pthread_create(&threads[i].id, NULL, worker_thread, &threads[i].args);
	
	// Wait for them
	for (int i = 0; i < thread_count; i++)
		pthread_join(threads[i].id, NULL);
	
	
	munmap(data_start, data_size + 1);
	close(fd);
	
	return 0;
}