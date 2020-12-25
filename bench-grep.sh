#!/bin/bash

# NOTE: The 1st parameter (cmd) must not contain quotes. The command is directly given to /usr/bin/time and without any
# shell expansion or word processing from bash.
function bench_cmd {
	local cmd="$1"
	local log_file="$2"
	
	echo "wall clock sec, cpu user sec, cpu system sec, percentage of cpu, major page faults, minor page faults, max resident kb, involuntarily context switches, voluntarily context switches" > "$log_file"
	for i in {1..10}; do
		/usr/bin/time --format "%e, %U, %S, %P, %F, %R, %M, %c, %w" $cmd 2>> "$log_file"
		echo "RUN $i: $cmd → $?"
	done
}

bench_cmd 'grep KjtumnUZYtr+56rCapI= lines.txt' "test-02-short.csv"
bench_cmd 'grep /6EH5uWurSalIb4oP6aKS2bI/pzd4d8kKCigDSz/DaMo3RffA71d23Y= lines.txt' "test-02-medium.csv"
bench_cmd 'grep WG/z8/a5yEC0uvh6Ntdw9W678iHZgwNkEGUX6oQahJnNl+On+JXSwAyv4crTDuaVsubZCH8Kuzbf6jsWvrC70JhEEzKroLt1lHnPLjme3iZLTAEMCLgMbyGi3BGYl7/ywB3g48L+YroaWIuCNSMm lines.txt' "test-02-long.csv"

bench_cmd './fgets-search KjtumnUZYtr+56rCapI= lines.txt' "test-03-short.csv"
bench_cmd './fgets-search /6EH5uWurSalIb4oP6aKS2bI/pzd4d8kKCigDSz/DaMo3RffA71d23Y= lines.txt' "test-03-medium.csv"
bench_cmd './fgets-search WG/z8/a5yEC0uvh6Ntdw9W678iHZgwNkEGUX6oQahJnNl+On+JXSwAyv4crTDuaVsubZCH8Kuzbf6jsWvrC70JhEEzKroLt1lHnPLjme3iZLTAEMCLgMbyGi3BGYl7/ywB3g48L+YroaWIuCNSMm lines.txt' "test-03-long.csv"

bench_cmd './fgets-search-opt3 KjtumnUZYtr+56rCapI= lines.txt' "test-04-short.csv"
bench_cmd './fgets-search-opt3 /6EH5uWurSalIb4oP6aKS2bI/pzd4d8kKCigDSz/DaMo3RffA71d23Y= lines.txt' "test-04-medium.csv"
bench_cmd './fgets-search-opt3 WG/z8/a5yEC0uvh6Ntdw9W678iHZgwNkEGUX6oQahJnNl+On+JXSwAyv4crTDuaVsubZCH8Kuzbf6jsWvrC70JhEEzKroLt1lHnPLjme3iZLTAEMCLgMbyGi3BGYl7/ywB3g48L+YroaWIuCNSMm lines.txt' "test-04-long.csv"

bench_cmd 'php search.php KjtumnUZYtr+56rCapI= lines.txt' "test-05-short.csv"
bench_cmd 'php search2.php KjtumnUZYtr+56rCapI= lines.txt' "test-06-short.csv"
