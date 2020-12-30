CFLAGS = -std=c99 -Wall -Werror -O2
ALL = c1-line-strstr c2-line-str_contains c3-line-fancy c4-all-strstr c5-threaded-strstr

all: $(ALL)
c5-threaded-strstr: CFLAGS += -pthread

clean:
	rm -f $(ALL) *.svg