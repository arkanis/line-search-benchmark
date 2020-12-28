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
	
	# The awk skript skips the first line (column names). The last (empty) line is skipped automatically it seems.
	local avg_wall_time=$(awk 'NR > 1 { sum += $1 } END { print sum / (NR - 1) }' < $log_file)
	local mb_per_sec=$(awk "BEGIN { print int(($lines_size / $avg_wall_time) / (1024*1024)) }")
	local mil_lines_per_sec=$(awk "BEGIN { print ($lines_count / $avg_wall_time) / 1000000.0 }")
	# LC_NUMERIC=C makes sure that printf %f reads and outputs in 1.23 format, even if the terminal uses a different locale
	LC_NUMERIC=C printf '%-35s%13.3f, %8d, %8.2f\n' "${log_file%%.csv}," $avg_wall_time $mb_per_sec $mil_lines_per_sec >&2
}


echo -e "Program versions:\n"
grep --version
sed --version
awk --version
mawk -W version 2>&1
gcc --version
php --version
python3.8 --version
ruby --version

echo -e "\nCompiling c programs:\n"
make all

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

bench_cmd 1  'wc -l lines-1m.txt'                                                                                1m-00-warmup.csv                   $lines_size $lines_count
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
bench_cmd 10 'php php1-line-strstr.php 7Xbs7f0hhn2Alb lines-1m.txt'                                              1m-15-php1-line-strstr.csv         $lines_size $lines_count
bench_cmd 10 'php php2-all-strpos.php 7Xbs7f0hhn2Alb lines-1m.txt'                                               1m-16-php2-all-strpos.csv          $lines_size $lines_count
bench_cmd 10 'python3.8 py1-line-find.py 7Xbs7f0hhn2Alb lines-1m.txt'                                            1m-17-py1-line-find.csv            $lines_size $lines_count
bench_cmd 10 'python3.8 py2-mmap-line-find.py 7Xbs7f0hhn2Alb lines-1m.txt'                                       1m-18-py2-mmap-line-find.csv       $lines_size $lines_count
bench_cmd 10 'python3.8 py3-mmap-all-find.py 7Xbs7f0hhn2Alb lines-1m.txt'                                        1m-19-py3-mmap-all-find.csv        $lines_size $lines_count
bench_cmd 10 'ruby ruby1-line-include.rb 7Xbs7f0hhn2Alb lines-1m.txt'                                            1m-20-ruby1-line-include.csv       $lines_size $lines_count
bench_cmd 10 'ruby ruby2-all-index.rb 7Xbs7f0hhn2Alb lines-1m.txt'                                               1m-21-ruby2-all-index.csv          $lines_size $lines_count


if test ! -f lines-10m.txt; then
	echo "Generating lines-10m.txt..."
	ruby gen-lines.rb 10_000_000 > lines-10m.txt
	# sample lines:
	# http://example.com/3073701/Ybyld6r9vNai95TYXiQH4FuQV+l/CHMwP4i3jQ==	qO76BFQLlj2g
	# http://example.com/3503259/V6TGqGjjnmhlHRcYEq1IJCgzUNSx09bCkwJnEKAE	j/tkgNV2c+ACibA3tpPgELnHPYT+3O32QLxFiAFdoGUl9xD9hl/0gCMprpGmMJqKFdU7Y0lkgriled853IQ+2Q1Ub3hMA4n8xpS9c+TLNg==
	# http://example.com/3874850/zjQdPR3iPXe/f28d0x6D2fQONt8x	j5gSmB0dQhRpZ5yjnMBU9la1Dl00wzcD2C7J
	# http://example.com/4097761/2bKX3FQY+hnG	0k3j5evTu+FMzaoLmVeEoJ3PAPERDFSO2RFEo5/mO17YTQrXz4jr0Ud9w0854q6/rcRu11AocX3vzl4q7O0f6c+3jBoZCuL9k+tvrm178dppX5r7xSyDrAtjWHbtM2DBr1j8C13yYudNbTTEu7LJntONc+SY2Vs2WXBige8yAYRq
	# http://example.com/4659995/zLtSsvjmP6o6vYwQQm0VRTtgxM0xUbY=	QvzHvFPq7/VrKDJbjoQ9xnzgUUEHP2F/RW2WbIOfnq0wgS5xNCCwF4w=
	# http://example.com/9674460/OGuKOpNt22+aPUfoW3XTBDOfh/q/lc8ysJpil+M=	WURbI/R069glGkYLjfOizaobX5gJRUjF71pe
	# short:  VrKDJbjoQ9xnzg  → 4659995
	# medium: V6TGqGjjnmhlHRcYEq1IJCgzUNSx09bCkwJnEK  → 3503259
	# long:   FMzaoLmVeEoJ3PAPERDFSO2RFEo5/mO17YTQrXz4jr0Ud9w0854q6/rcRu11AocX3vzl4q7O0f6c  → 4097761
fi
lines_size=$(stat --printf="%s" lines-10m.txt)
lines_count=10_000_000

bench_cmd 1  'wc -l lines-10m.txt'                                                                                10m-00-warmup.csv                   $lines_size $lines_count
bench_cmd 10 'grep VrKDJbjoQ9xnzg lines-10m.txt'                                                                  10m-01-grep-short.csv               $lines_size $lines_count
bench_cmd 10 'grep V6TGqGjjnmhlHRcYEq1IJCgzUNSx09bCkwJnEK lines-10m.txt'                                          10m-02-grep-medium.csv              $lines_size $lines_count
bench_cmd 10 'grep FMzaoLmVeEoJ3PAPERDFSO2RFEo5/mO17YTQrXz4jr0Ud9w0854q6/rcRu11AocX3vzl4q7O0f6c lines-10m.txt'    10m-03-grep-long.csv                $lines_size $lines_count
bench_cmd 10 'sed /VrKDJbjoQ9xnzg/!d lines-10m.txt'                                                               10m-04-sed.csv                      $lines_size $lines_count
bench_cmd 10 'awk /VrKDJbjoQ9xnzg/ lines-10m.txt'                                                                 10m-05-awk.csv                      $lines_size $lines_count
bench_cmd 10 'mawk /VrKDJbjoQ9xnzg/ lines-10m.txt'                                                                10m-06-mawk.csv                     $lines_size $lines_count
bench_cmd 10 'mawk index($2,"VrKDJbjoQ9xnzg") lines-10m.txt'                                                      10m-07-mawk-index.csv               $lines_size $lines_count
bench_cmd 10 './c1-line-strstr VrKDJbjoQ9xnzg lines-10m.txt'                                                      10m-08-c1-line-strstr.csv           $lines_size $lines_count
bench_cmd 10 './c2-line-str_contains VrKDJbjoQ9xnzg lines-10m.txt'                                                10m-09-c2-line-str_contains.csv     $lines_size $lines_count
bench_cmd 10 './c3-line-fancy VrKDJbjoQ9xnzg lines-10m.txt'                                                       10m-10-c3-line-fancy.csv            $lines_size $lines_count
bench_cmd 10 './c4-all-strstr VrKDJbjoQ9xnzg lines-10m.txt'                                                       10m-11-c4-all-strstr.csv            $lines_size $lines_count
bench_cmd 10 './c5-threaded-strstr VrKDJbjoQ9xnzg lines-10m.txt 2'                                                10m-12-c5-2threads-strstr.csv       $lines_size $lines_count
bench_cmd 10 './c5-threaded-strstr VrKDJbjoQ9xnzg lines-10m.txt 4'                                                10m-13-c5-4threads-strstr.csv       $lines_size $lines_count
bench_cmd 10 './c5-threaded-strstr VrKDJbjoQ9xnzg lines-10m.txt 8'                                                10m-14-c5-8threads-strstr.csv       $lines_size $lines_count
bench_cmd 10 'php php1-line-strstr.php VrKDJbjoQ9xnzg lines-10m.txt'                                              10m-15-php1-line-strstr.csv         $lines_size $lines_count
bench_cmd 10 'php php2-all-strpos.php VrKDJbjoQ9xnzg lines-10m.txt'                                               10m-16-php2-all-strpos.csv          $lines_size $lines_count
bench_cmd 10 'python3.8 py1-line-find.py VrKDJbjoQ9xnzg lines-10m.txt'                                            10m-17-py1-line-find.csv            $lines_size $lines_count
bench_cmd 10 'python3.8 py2-mmap-line-find.py VrKDJbjoQ9xnzg lines-10m.txt'                                       10m-18-py2-mmap-line-find.csv       $lines_size $lines_count
bench_cmd 10 'python3.8 py3-mmap-all-find.py VrKDJbjoQ9xnzg lines-10m.txt'                                        10m-19-py3-mmap-all-find.csv        $lines_size $lines_count
bench_cmd 10 'ruby ruby1-line-include.rb VrKDJbjoQ9xnzg lines-10m.txt'                                            10m-20-ruby1-line-include.csv       $lines_size $lines_count
bench_cmd 10 'ruby ruby2-all-index.rb VrKDJbjoQ9xnzg lines-10m.txt'                                               10m-21-ruby2-all-index.csv          $lines_size $lines_count


if test ! -f lines-50m.txt; then
	echo "Generating lines-50m.txt..."
	ruby gen-lines.rb 50_000_000 > lines-50m.txt
	# sample lines:
	# http://example.com/206679/SkdLwsMKrhOQBaLv2JMAXT0=	mY1GI9RXe7Ji756zJy6NdD9o6W9zQ5NNldd9RWb8GyAcDDTLWBezGR/UojrOzFBN91KJHWsf/YXUwfM=
	# http://example.com/1393684/8Rhk19wcTbgKBdm8AoX7GSCACA==	1Adq1marurr829GlT52/cWR6XnpgPgGe7FVgeIoEH3pYU2WxpWfVk77OZrgz0scubCSW6wdUdf0E86xkuq4mXvmXY2XZMa/NeZGQtNCE5fvAut4Hq2eKjhjC5PsHIdTqWOKG3FVr3d5Jcyg0xQIc3/yr89uaf06HIJHwJvs2Vw==
	# http://example.com/5010430//hMYPe65wFhq6c/QY94=	L7VOFCoNw3FDF2QDoQb0+Dd0MVvBFOnbzA0J8Q==
	# http://example.com/7552030/wwWqwyNF2AOlQp1Fme0dN9PUgUQ=	uib9YbHfPrVrRphw4CcKmgJHr99OAjfrjo+NtkvZR4B+9rJ3Ux3sUvUx7RQXDIfPTDqZeHLN+sAZqJ3fqYtL/Q==
	# http://example.com/19717926/w/CZTchiAWA=	8OjYTkxoNyw4DJAUJOrohxZB
	# http://example.com/24743913/yq5Q7vTm8ZNRIuSGSFuIDRPTZ9y9x5Q=	fSFFmd93xyiqk8B7OVY8uTiXIjp3oMcfgMjBNsXPQbwS5q5cqSLGgQ5FSErQJpOMjZDJu2qRt91KKgFI8Uru3Uwab3My2bSWWB62+6+GXbXvXpY1dyoHMr+3wHJvB0oH2M3pQ5q2r2+QKQ6XXrQc5A==
	# http://example.com/32643403/0QXcqYIRJM28knAW/uLFRzzbWWJvtYiXkwQ=	7HM6O+HN+rQcL2GkdE6sXcUkGeqggfx4fW0eyE6JTbaNVlA+7eyuKdIUsIAw1Hvs0BH3ZT3lzLvMWnzYWg==
	# http://example.com/42534638/YxprXKYISmyVSZMJDixo3dAoHgUngEy3snU=	Xs69GJCJRJcDneu5AOIEOOjxzdQOGxhjbWPBDNo2
	# http://example.com/47951266/58Q9UQaVJ/+H5up+rN4Qi2bSnM0=	zfNsfRduj8EExR8A0jaTKv6jp5UdZHPhZ/yiR1hF+ueLmVaxfQnkxQt9/sL3d/QI2YVT2+FbsKjBI7AJfEvysGiH8rRwOjZCHToNLAM9Ig4b4W0qOwuc20DKGRvjrKf2HYRyoUROCX38n+Dz
	# http://example.com/49085328/iRBbc/7CpK0SthWKlK1HdfDH	9DNJSpiVRXjpH+I=
	# short: oNw3FDF2QDoQb0  → 5010430
fi
lines_size=$(stat --printf="%s" lines-50m.txt)
lines_count=50_000_000

bench_cmd 1 'wc -l lines-50m.txt'                                                                                50m-00-warmup.csv                   $lines_size $lines_count
bench_cmd 3 'grep oNw3FDF2QDoQb0 lines-50m.txt'                                                                  50m-01-grep-short.csv               $lines_size $lines_count
bench_cmd 3 './c1-line-strstr oNw3FDF2QDoQb0 lines-50m.txt'                                                      50m-08-c1-line-strstr.csv           $lines_size $lines_count
bench_cmd 3 './c4-all-strstr oNw3FDF2QDoQb0 lines-50m.txt'                                                       50m-11-c4-all-strstr.csv            $lines_size $lines_count
bench_cmd 3 './c5-threaded-strstr oNw3FDF2QDoQb0 lines-50m.txt 2'                                                50m-12-c5-2threads-strstr.csv       $lines_size $lines_count
bench_cmd 3 './c5-threaded-strstr oNw3FDF2QDoQb0 lines-50m.txt 4'                                                50m-13-c5-4threads-strstr.csv       $lines_size $lines_count
bench_cmd 3 './c5-threaded-strstr oNw3FDF2QDoQb0 lines-50m.txt 8'                                                50m-14-c5-8threads-strstr.csv       $lines_size $lines_count
bench_cmd 3 'python3.8 py3-mmap-all-find.py oNw3FDF2QDoQb0 lines-50m.txt'                                        50m-19-py3-mmap-all-find.csv        $lines_size $lines_count


if test ! -f lines-100m.txt; then
	echo "Generating lines-100m.txt..."
	ruby gen-lines.rb 100_000_000 > lines-100m.txt
	# sample lines:
	# http://example.com/206745/SkdLwsMKrhOQBaLv2JMAXT0=	mY1GI9RXe7Ji756zJy6NdD9o6W9zQ5NNldd9RWb8GyAcDDTLWBezGR/UojrOzFBN91KJHWsf/YXUwfM=
	# http://example.com/2555337/W4CjnmWLYlPWMB/6guLz4E5tEy0/	cGoLt3dD6HQxqnbkB0Euuupx
	# http://example.com/39491796/gBfe11alkDr8piK1XkMe	bIuXyL3bXd08DQky5BUwPMT5RUDKnzy3wX387OJNj/4MWENKdEWI2tYsSQ0jHNce
	# http://example.com/40317941/MAEw1igYaheWJuxGO2zHGwZs3g==	VIrkxp++gYDTu1g2+Y/RS8o2SSt/r70LyB5VUOc=
	# http://example.com/40451156/+vx4twZIgHximhm3gzv2FaIxhw==	fsbck7cfiOLNHXI+FodRo2ULO1MfCGkY2lRbl2RRAz1gQr73dkKPLEV3CF+5HxJJF98x4y+EdMfQxSnBTLNGHGJ0ciIFxh0ZNhiIX0tTlMK8x4avb8yObqgSWxVIqM1DF2CrwvuZ185WvsMWHUtA9A==
	# http://example.com/45573539/0ae2qIWIN/Q5jTjJuUuSDlgMt43X	hYbdXz5b0X9ctk2AHVHk8uNsMUGlTHF+EtP0wg==
	# http://example.com/61263977/aq8YeHorhkKt9HRICEM=	Z9iLktmumXS1Kpxq0oBAaWRcIPv7ofrJ09I3QaAKBUnC6RKiUXzNOoNZWBnfUiFXkvMSY5BEktP08J+yvHrUxzMZJlrgH9DdX7vAmyMcTgoGLdbiuTLSy4I=
	# http://example.com/62651960/NgP8oWgdbCvBFg6/L4LosA==	xINpTWkJzdGeEko3UXFR8uBkk1H8dtONOCbePHdTmNQ8k0QSvfyyG/ZzP2tFfY4BSNY8tnie6sHOry4jVzG5FnbIa74svMr7iHqG/9yT37D6jBJShB3xkjlRFGsVPsSXRZ3p9sZFqky2sGgZ6VIOfEMPgtCs0gq2yLcGD1E=
	# http://example.com/65335414/LNhxRQWNB0N3Q16J8khfPDc=	WxErpeHDxm6Y0u5oKGv9wUFGY2G6LlSm1MOtPayGbkyKHB26e+Jfa2p9sEdOZXCziFWwlIC/qS8eYpdn2ECnkMMJEXs17jqS7G1/ySuxpy2hEwGAZ6hfWPrlF6KZ+JjFlzHyjHqsxdT25StCuDFasHj2VcSOM9RA7bEPe8ZuNQ==
	# short: 0X9ctk2AHVHk8u  → 45573539
fi
lines_size=$(stat --printf="%s" lines-100m.txt)
lines_count=100_000_000

bench_cmd 1 'wc -l lines-100m.txt'                                                                                100m-00-warmup.csv                   $lines_size $lines_count
bench_cmd 2 'grep 0X9ctk2AHVHk8u lines-100m.txt'                                                                  100m-01-grep-short.csv               $lines_size $lines_count
bench_cmd 2 './c1-line-strstr 0X9ctk2AHVHk8u lines-100m.txt'                                                      100m-08-c1-line-strstr.csv           $lines_size $lines_count
bench_cmd 2 './c4-all-strstr 0X9ctk2AHVHk8u lines-100m.txt'                                                       100m-11-c4-all-strstr.csv            $lines_size $lines_count
bench_cmd 2 './c5-threaded-strstr 0X9ctk2AHVHk8u lines-100m.txt 2'                                                100m-12-c5-2threads-strstr.csv       $lines_size $lines_count
bench_cmd 2 './c5-threaded-strstr 0X9ctk2AHVHk8u lines-100m.txt 4'                                                100m-13-c5-4threads-strstr.csv       $lines_size $lines_count
bench_cmd 2 './c5-threaded-strstr 0X9ctk2AHVHk8u lines-100m.txt 8'                                                100m-14-c5-8threads-strstr.csv       $lines_size $lines_count
bench_cmd 2 'python3.8 py3-mmap-all-find.py 0X9ctk2AHVHk8u lines-100m.txt'                                        100m-19-py3-mmap-all-find.csv        $lines_size $lines_count
