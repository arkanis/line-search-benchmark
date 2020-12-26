#!/bin/bash

# NOTE: The 2nd parameter (cmd) must not contain quotes. The command is directly given to /usr/bin/time and without any
# shell expansion or word processing from bash.
function bench_cmd {
	local repeats="$1"
	local cmd="$2"
	local log_file="$3"
	local lines_size="$4"
	local lines_count="${5//_/}"  # remove "_" from the number
	
	echo "wall clock sec, cpu user sec, cpu system sec, percentage of cpu, major page faults, minor page faults, max resident kb, involuntarily context switches, voluntarily context switches" > "$log_file"
	for i in $(seq 1 $repeats); do
		/usr/bin/time --format "%e, %U, %S, %P, %F, %R, %M, %c, %w" $cmd 2>> "$log_file"
		echo "RUN $i: $cmd → $?"
	done
	
	# The awk skript skips the first and last line (column names in first line, last is an empty line)
	local avg_wall_time=$(awk 'NR > 1 { sum += $1 } END { print sum / (NR - 2) }' < $log_file)
	local mb_per_sec=$(awk "BEGIN { print int(($lines_size / $avg_wall_time) / (1024*1024)) }")
	local mil_lines_per_sec=$(awk "BEGIN { print ($lines_count / $avg_wall_time) / 1000000.0 }")
	# LC_NUMERIC=C makes sure that printf %f reads and outputs in 1.23 format
	LC_NUMERIC=C printf '%-35s%13.3f, %8d, %8.2f\n' "${log_file%%.csv}," $avg_wall_time $mb_per_sec $mil_lines_per_sec >&2
}


echo -e "Program versions:\n"
grep --version
sed --version
awk --version
mawk -W version 2>&1
php --version
python3.8 --version
ruby --version

echo -e "\nCompiling c programs:\n"
make c1-line-strstr c2-line-str_contains c3-line-fancy c4-all-strstr c5-threaded-strstr c6-threaded-mmap-strstr

echo -e "\nRunning benchmarks:\n"
printf '%-35s%13s, %8s, %8s\n' "benchmark," "wall time sec" "MiByte/s" "mlines/s" >&2

# Not doing the 100k run because it's to fast and we get times below 10ms that /usr/bin/time can't output. This causes
# division by zero errors in AWK (used in bench_cmd).
#ruby gen-lines.rb 100_000 > lines-100k.txt
# sample lines:
# http://example.com/6448/IjSR6u7XlmrxNhNA3rM=	F6HQ3AqUD5717zIDf76P0sRjcsU5oCEWa/3K8Q==
# http://example.com/14355/pAbiHODKpm9jPL/vrq8sbd51dolj3FLQ	+a4WCO6RliUbHP3UZkoIEDdLjfmuc7/IAafq5WxNrOVh3ve/69JTe1BuI5fJuV9+9kHQ/31bd6KFWjJVHkFLIe6PqL726COoS45JBfyY5cCy+M2EGAi9bkN8b9YF9hc7TTu5JDM8zii/Y2cSZAOFXzn/agRTJyAP9Sr4LriVCDtH9TaJI50=
# http://example.com/16016/44mO2bpfWZpHLX5J3ic=	a/i9wjdHN77/8ix7SOMVIKeuOkJJUgCGt7AY2YjPgVcctE61ZPrsJ+r9g4b74uC1doTtTqIlh2J7hsbE1zvv3Of+fbo5w1hpDVeCOkVUHtvYCaP5aRI8IdbP7gozm0Me7r7sNKqLuxQmWriuZbSGdWlEQm643M88Pw==
# http://example.com/41197/0VYcIRy9n3My498=	Mg498CRoS5YsjDLuHHPCSqOgxQJ0JIfKOOKpI7h1ehqzfJQw2tlodeokLNpn5QRYqeDQgO0ilJh9QWrq+jO9bKohABKxnrplLrNA9Cd4blT2Saph0EJI/yNXwKgpl8u9/WRgLVWH/nc=
# http://example.com/68999/byJ9Fl2c1BllTBqfwKFMJZWWma6epWo=	WxIqfsuIEdTW7c5DcbtH1UdSnwDSaZcooC2yBN+wvS0XOlH6nby3VY+W39aZfRAGf1VerpsHZqBj9CcR5XQM6xqM34rfM0VGJbty
# http://example.com/72359/Xm3Q1/RBvzA5/q9K5sWMZc+0ChzeVKFx	hVY+DVvSnSUFxavtbKBwumbfAsRpqVohyNwFgLXd9Ju+0w==
# http://example.com/75948/8raqxxn6sLf/4Th/LPBv5FWIHBwh	5H75IsGDTMoUdPM13QASYKFLFVp5/Rwoa7nI2Rp12LIlFvh/+0zFD23WiwMJfI/Vre/Qy9x4h6YB759A5j6Ef/UgQay2bDlTD6bE2ws67Q==
# http://example.com/94372/CSVoJSFpqJS9bNdX	HIrvSTtPVMJbay3y9WieRO6V
# short:  F6HQ3AqUD5717z  → 6448
# medium: DVvSnSUFxavtbKBwumbfAsRpqVohyNwFgLXd9Ju  → 72359
# long:   Mg498CRoS5YsjDLuHHPCSqOgxQJ0JIfKOOKpI7h1ehqzfJQw2tlodeokLNpn5QRYqeDQgO0ilJh9QWrq  → 41197


if test ! -f lines-1m.txt; then
	echo "Generating lines-1m.txt..."
	ruby gen-lines.rb 1_000_000 > lines-1m.txt
	# sample lines:
	# http://example.com/56875/urUCcbHy7k7h	7Xbs7f0hhn2AlbkHOuw=
	# http://example.com/323341/+2ETdlk+3ex+kzuGSTxho7iEcv80AUMw	pGIgqCHth43hkuMwWbpU4Vk4NaP/HJsJ9urXIx6BMUZcAjTXlitlORxcjSyKN4aflCHgQJC+vRmnbSNLr/KHxz+3d96BccG1RTPb+qRUHEAmA533W++y5jQK2huiPflxtpm4sK/YYAcbPkE3tX98QPsQbSuXyYOtq+no5BoLqg3Vnz4=
	# http://example.com/381839/+XhG5VBKrQQ=	sS7iy7NpHNw2LhQNA8stOHE=
	# http://example.com/426559/Iqw4WLAdKyY8/9EzvfPI09wqiA==	2fGQBLk+iWnxJuO6I7oeoSnsHz6Ewwma478AEXquhsIeGCFoPtj8O/fbHf+fW993mMUenCql4SHnwA1IIQbIpqTYMmNyIWcFSiRLrhEj3i1aH+gI+diEcQ9Y2LNObWJMlVoyL5Gz3z4JR0EWgpKukQtqwwvvTG8C
	# http://example.com/731370/ulAB5GONmZbFWQztfyyD	bLLo6RgSqtuKTiM0cCYRlADUyBBByY8uCRZh6ft+WA02gPdPz55z5E7ed9RGaQlcnMTrvSkZgvKoNaMWVaKRjyLIkwURVnea48eGQEhSFfKwQJkNZCTWWgE=
	# http://example.com/768201/u4CU99GsKVtYfZSs965TCA==	6LlXN9tEfah/ZwZcUcQYPf7ASxHNHWqffMQldPrYsHJzsR72T4+rO3IAtNxfHF/31Gs9Uv9FM6AyAhPYjahAEvMuWCrYBbn46FV7ysE7ckXf7pv97UKrzkEBPKsNMwOPSByP
	# short:  7Xbs7f0hhn2Alb  → 56875
	# medium: ZwZcUcQYPf7ASxHNHWqffMQldPrYsHJzsR72T4  → 768201
	# long:   WA02gPdPz55z5E7ed9RGaQlcnMTrvSkZgvKoNaMWVaKRjyLIkwURVnea48eGQEhSFfKwQJkNZCTWWgE  → 731370
fi
lines_size=$(stat --printf="%s" lines-1m.txt)
lines_count=1_000_000

bench_cmd 10 'grep 7Xbs7f0hhn2Alb lines-1m.txt'                                                                  1m-01-grep-short.csv               $lines_size $lines_count
bench_cmd 10 'grep ZwZcUcQYPf7ASxHNHWqffMQldPrYsHJzsR72T4 lines-1m.txt'                                          1m-02-grep-medium.csv              $lines_size $lines_count
bench_cmd 10 'grep WA02gPdPz55z5E7ed9RGaQlcnMTrvSkZgvKoNaMWVaKRjyLIkwURVnea48eGQEhSFfKwQJkNZCTWWgE lines-1m.txt' 1m-03-grep-long.csv                $lines_size $lines_count
bench_cmd 10 'sed /7Xbs7f0hhn2Alb/!d lines-1m.txt'                                                               1m-04-sed.csv                      $lines_size $lines_count
bench_cmd 10 'awk /7Xbs7f0hhn2Alb/ lines-1m.txt'                                                                 1m-05-awk.csv                      $lines_size $lines_count
bench_cmd 10 'mawk /7Xbs7f0hhn2Alb/ lines-1m.txt'                                                                1m-06-mawk.csv                     $lines_size $lines_count
bench_cmd 10 'mawk index($2,"7Xbs7f0hhn2Alb") lines-1m.txt'                                                      1m-07-mawk-index.csv               $lines_size $lines_count
bench_cmd 10 './c1-line-strstr 7Xbs7f0hhn2Alb lines-1m.txt'                                                      1m-08-c1-line-strstr.csv           $lines_size $lines_count
bench_cmd 10 './c2-line-str_contains 7Xbs7f0hhn2Alb lines-1m.txt'                                                1m-09-c2-line-str_contains.csv     $lines_size $lines_count
bench_cmd 10 './c3-line-fancy 7Xbs7f0hhn2Alb lines-1m.txt'                                                       1m-10-c3-line-fancy.csv            $lines_size $lines_count
bench_cmd 10 './c4-all-strstr 7Xbs7f0hhn2Alb lines-1m.txt'                                                       1m-11-c4-all-strstr.csv            $lines_size $lines_count
bench_cmd 10 './c5-threaded-strstr 7Xbs7f0hhn2Alb lines-1m.txt 2'                                                1m-12-c5-2threads-strstr.csv       $lines_size $lines_count
bench_cmd 10 './c5-threaded-strstr 7Xbs7f0hhn2Alb lines-1m.txt 4'                                                1m-13-c5-4threads-strstr.csv       $lines_size $lines_count
bench_cmd 10 './c5-threaded-strstr 7Xbs7f0hhn2Alb lines-1m.txt 8'                                                1m-14-c5-8threads-strstr.csv       $lines_size $lines_count
bench_cmd 10 './c6-threaded-mmap-strstr 7Xbs7f0hhn2Alb lines-1m.txt 2'                                           1m-15-c6-2threads-mmap-strstr.csv  $lines_size $lines_count
bench_cmd 10 './c6-threaded-mmap-strstr 7Xbs7f0hhn2Alb lines-1m.txt 4'                                           1m-16-c6-4threads-mmap-strstr.csv  $lines_size $lines_count
bench_cmd 10 './c6-threaded-mmap-strstr 7Xbs7f0hhn2Alb lines-1m.txt 8'                                           1m-17-c6-8threads-mmap-strstr.csv  $lines_size $lines_count
bench_cmd 10 'php php1-line-strstr.php 7Xbs7f0hhn2Alb lines-1m.txt'                                              1m-18-php1-line-strstr.csv         $lines_size $lines_count
bench_cmd 10 'php php2-all-strpos.php 7Xbs7f0hhn2Alb lines-1m.txt'                                               1m-19-php2-all-strpos.csv          $lines_size $lines_count
bench_cmd 10 'python3.8 py1-line-find.py 7Xbs7f0hhn2Alb lines-1m.txt'                                            1m-20-py1-line-find.csv            $lines_size $lines_count
bench_cmd 10 'python3.8 py2-mmap-line-find.py 7Xbs7f0hhn2Alb lines-1m.txt'                                       1m-21-py2-mmap-line-find.csv       $lines_size $lines_count
bench_cmd 10 'python3.8 py3-mmap-all-find.py 7Xbs7f0hhn2Alb lines-1m.txt'                                        1m-22-py3-mmap-all-find.csv        $lines_size $lines_count
bench_cmd 10 'ruby ruby1-line-include.rb 7Xbs7f0hhn2Alb lines-1m.txt'                                            1m-23-ruby1-line-include.csv       $lines_size $lines_count
bench_cmd 10 'ruby ruby2-all-index.rb 7Xbs7f0hhn2Alb lines-1m.txt'                                               1m-24-ruby2-all-index.csv          $lines_size $lines_count



# 5m   5_000_000   10
# 10m  10_000_000  5
# 50m  50_000_000  3
# 100m 100_000_000 3