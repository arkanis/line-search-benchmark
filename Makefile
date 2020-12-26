CFLAGS = -std=c99 -Wall -Werror -O2

c5-threaded-strstr c6-threaded-mmap-strstr: CFLAGS += -pthread

clean:
	rm -f c1-line-strstr c2-line-str_contains c3-line-fancy c4-all-strstr c5-threaded-strstr c6-threaded-mmap-strstr