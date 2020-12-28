<?php

function svg_chart($axes, $records, $options = []) {
	$default_options = [
		'chart' => [
			'height' => 200,
			'margin' => 10,
			'horizontal_padding' => 10,
			'grid_lines' => 5
		],
		'records' => [
			'margin' => 50,
			'label_height' => 20,
			'values' => [
				'digits' => 3,
				'width' => 40,
				'margin' => 5,
				'label_height' => 14,
				'unit_height' => 6
			]
		],
		'legend' => [
			'top_margin' => 10,
			'line_height' => 20,
			'text_offset' => 12
		]
	];
	$options = array_replace_recursive($default_options, $options);
	
	$record_width = count($axes) * $options['records']['values']['width'] + (count($axes) - 1) * $options['records']['values']['margin'];
	$chart_width = $options['chart']['horizontal_padding'] * 2 + count($records) * $record_width + (count($records) - 1) * $options['records']['margin'];
	
	$total_width = $options['chart']['margin'] * 2 + $chart_width;
	$total_height = $options['chart']['height'] + $options['chart']['margin'] * 2 + $options['records']['label_height'] + $options['legend']['top_margin'] + count($axes) * $options['legend']['line_height'];
	
	$legend_x = $options['chart']['height'] + $options['records']['label_height'] + $options['legend']['top_margin'];
	
	$round_to_digits = function($number, $digits){
		$log10 = log10($number);
		$integer_digits = ceil($log10);
		$fraction_digits = max($digits - $integer_digits, 0);
		// For sub zero nubers we need a digit for the leading 0
		if ($integer_digits <= 0)
			$fraction_digits--;
		
		$rounded = round($number, $fraction_digits);
		return sprintf('%' . ($integer_digits + $fraction_digits) . '.' . $fraction_digits . 'f', $rounded);
	};
	
	ob_start();
?>
<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="<?= $total_width ?>" height="<?= $total_height ?>">
	<defs>
		<style type="text/css">
			text { font-family: sans-serif; font-size: 14px; color: #333; }
			text.value { text-anchor: middle; }
			text.unit { text-anchor: middle; font-size: 12px; }
			text.label { text-anchor: middle; font-size: 10px; }
			text.legend {}
		</style>
	</defs>
	<g transform="translate(<?= $options['chart']['margin'] ?>, <?= $options['chart']['margin'] ?>)">
		<g>
<?php		for($i = 0; $i < $options['chart']['grid_lines']; $i++): ?>
			<rect x="0" y="<?= $options['chart']['height'] / $options['chart']['grid_lines'] * $i ?>" width="<?= $chart_width ?>" height="1" fill="#ccc"></rect>
<?php		endfor ?>
			<rect x="0" y="<?= $options['chart']['height'] ?>" width="<?= $chart_width ?>" height="1" fill="black"></rect>
		</g>
<?php	foreach($records as $record_index => $record): ?>
<?php
			$title = array_shift($record);
			$x = $options['chart']['horizontal_padding'] + ($record_width + $options['records']['margin']) * $record_index;
			
?>
		<g id="records" transform="translate(<?= $x ?>, 0)">
<?php		foreach($axes as $index => $axis): ?>
<?php
				$value_height = ceil(($options['chart']['height'] / $axis['to']) * $record[$index]);
				$value_height = max($value_height, 1);
				$value_x = ($options['records']['values']['width'] + $options['records']['values']['margin']) * $index;
				$value_y = $options['chart']['height'] - $value_height;
				$value_x_center = $value_x + $options['records']['values']['width'] / 2;
				$unit_y = $value_y - ($axis['unit'] ? $options['records']['values']['unit_height'] : 0);
				$label_y = $unit_y - $options['records']['values']['label_height'];
?>
			<rect x="<?= $value_x ?>" y="<?= $value_y ?>" width="<?= $options['records']['values']['width'] ?>" height="<?= $value_height ?>" style="<?= $axis['style'] ?>"></rect>
			<text class="value" x="<?= $value_x_center ?>" y="<?= $label_y ?>"><?= $round_to_digits($record[$index], $options['records']['values']['digits']) ?></text>
<?php		if($axis['unit']): ?>
			<text class="unit" x="<?= $value_x_center ?>" y="<?= $unit_y ?>"><?= $axis['unit'] ?></text>
<?php		endif ?>
<?php		endforeach ?>
			<text class="label" x="<?= $record_width / 2 ?>" y ="<?= $options['chart']['height'] + $options['records']['label_height'] ?>">
<?php		foreach( explode("\n", $title) as $line_no => $title_line ): ?>
				<tspan x="<?= $record_width / 2 ?>"<?php if($line_no > 0): ?> dy="1.2em"<?php endif ?>><?= $title_line ?></tspan>
<?php		endforeach ?>
			</text>
		</g>
<?php	endforeach ?>
		
		<g transform="translate(0, <?= $legend_x ?>)">
<?php	foreach($axes as $axis_index => $axis): ?>
			<g id="foo<?= $axis_index ?>">
				<rect x="0" y="<?= $axis_index * $options['legend']['line_height'] ?>" width="14" height="14" style="<?= $axis['style'] ?>"></rect>
				<text class="legend" x="18" y="<?= $axis_index * $options['legend']['line_height'] + $options['legend']['text_offset'] ?>"><?= $axis['name'] ?></text>
			</g>
<?php	endforeach ?>
		</g>
	</g>
</svg>
<?php
	return ob_get_clean();
}


//$records["10m"]["warmup"]["wall_time" | "mbs" | "mls"]

file_put_contents('tldr.svg', svg_chart([
	['name' => 'Search speed in MiBytes per second', 'unit' => 'MiByte/s', 'to' => 3000, 'style' => 'fill: #3366cc', 'label_style' => ''],
], [
//	[ /*10m-00-*/ "warmup",                             /*0.880,*/     1656,   /* 11.36*/],
	[ /*10m-01-*/ "grep",                               /*0.631,*/     2310,   /* 15.85*/],
//	[ /*10m-02-*/ "grep-medium",                        /*0.349,*/     4177,   /* 28.65*/],
//	[ /*10m-03-*/ "grep-long",                          /*0.280,*/     5207,   /* 35.71*/],
	[ /*10m-04-*/ "sed",                                /*1.922,*/      758,   /*  5.20*/],
	[ /*10m-05-*/ "awk",                                /*4.092,*/      356,   /*  2.44*/],
	[ /*10m-06-*/ "mawk",                               /*1.724,*/      845,   /*  5.80*/],
//	[ /*10m-07-*/ "mawk-index",                         /*2.690,*/      542,   /*  3.72*/],
	[ /*10m-15-*/ "PHP\nstrstr by line",                /*7.102,*/      205,   /*  1.41*/],
	[ /*10m-17-*/ "Python\nfind by line",               /*3.653,*/      399,   /*  2.74*/],
	[ /*10m-20-*/ "Ruby\ninclude by line",              /*5.070,*/      287,   /*  1.97*/],
	
	[ /*10m-16-*/ "PHP\nstrpos on content",             /*1.541,*/      946,   /*  6.49*/],
//	[ /*10m-18-*/ "py2-mmap-line-find",                 /*2.747,*/      530,   /*  3.64*/],
	[ /*10m-19-*/ "Python\nfind on mmap",               /*1.935,*/      753,   /*  5.17*/],
	[ /*10m-21-*/ "Ruby\nindex on content",             /*1.151,*/     1266,   /*  8.69*/],
], [
	'chart' => [
		'horizontal_padding' => 20,
		'grid_lines' => 6
	],
]));

file_put_contents('tldr-c.svg', svg_chart([
	['name' => 'Search speed in MiBytes per second', 'unit' => 'MiByte/s', 'to' => 24000, 'style' => 'fill: #3366cc', 'label_style' => ''],
], [
	[ /*10m-01-*/ "grep",                               /*0.631,*/     2310,   /* 15.85*/],
	[ /*10m-08-*/ "C\nstrstr by line",                  /*0.820,*/     1778,   /* 12.20*/],
//	[ /*10m-09-*/ "c2-line-str_contains",               /*1.841,*/      792,   /*  5.43*/],
//	[ /*10m-10-*/ "c3-line-fancy",                      /*1.919,*/      759,   /*  5.21*/],
	[ /*10m-11-*/ "C\nstrstr on mmap",                  /*0.181,*/     8055,   /* 55.25*/],
	[ /*10m-12-*/ "C\nstrstr on mmap\n2 threads",       /*0.107,*/    13626,   /* 93.46*/],
	[ /*10m-13-*/ "C\nstrstr on mmap\n4 threads",       /*0.093,*/    15678,   /*107.53*/],
	[ /*10m-14-*/ "C\nstrstr on mmap\n8 threads",       /*0.080,*/    18226,   /*125.00*/],
], [
	'chart' => [
		'horizontal_padding' => 20,
		'grid_lines' => 6
	],
	'legend' => [
		'top_margin' => 20,
	]
]));

file_put_contents('grep.svg', svg_chart([
	['name' => 'Search speed in MiBytes per second', 'unit' => 'MiByte/s', 'to' => 6000, 'style' => 'fill: #3366cc', 'label_style' => ''],
], [
//	[ /*10m-00-*/ "warmup",                             /*0.880,*/     1656,   /* 11.36*/],
	[ /*10m-01-*/ "grep\nshort",                        /*0.631,*/     2310,   /* 15.85*/],
	[ /*10m-02-*/ "grep\nmedium",                       /*0.349,*/     4177,   /* 28.65*/],
	[ /*10m-03-*/ "grep\nlong",                         /*0.280,*/     5207,   /* 35.71*/],
], [
	'chart' => [
		'horizontal_padding' => 30,
		'grid_lines' => 6
	],
	'legend' => [
		'top_margin' => 20,
	]
]));

file_put_contents('awk.svg', svg_chart([
	['name' => 'Search speed in MiBytes per second', 'unit' => 'MiByte/s', 'to' => 1000, 'style' => 'fill: #3366cc', 'label_style' => ''],
], [
//	[ /*10m-00-*/ "warmup",                             /*0.880,*/     1656,   /* 11.36*/],
	[ /*10m-05-*/ "awk",                                /*4.092,*/      356,   /*  2.44*/],
	[ /*10m-06-*/ "mawk",                               /*1.724,*/      845,   /*  5.80*/],
	[ /*10m-07-*/ "mawk\nindex",                         /*2.690,*/      542,   /*  3.72*/],
	[ /*10m-04-*/ "sed",                                /*1.922,*/      758,   /*  5.20*/],
], [
	'chart' => [
		'horizontal_padding' => 30,
		'grid_lines' => 5
	],
	'legend' => [
		'top_margin' => 20,
	]
]));

file_put_contents('line-by-line.svg', svg_chart([
	['name' => 'Search speed in MiBytes per second', 'unit' => 'MiByte/s', 'to' => 500, 'style' => 'fill: #3366cc', 'label_style' => ''],
], [
	[ /*10m-15-*/ "PHP\nstrstr by line",                /*7.102,*/      205,   /*  1.41*/],
	[ /*10m-17-*/ "Python\nfind by line",               /*3.653,*/      399,   /*  2.74*/],
	[ /*10m-20-*/ "Ruby\ninclude by line",              /*5.070,*/      287,   /*  1.97*/],
], [
	'chart' => [
		'horizontal_padding' => 30,
		'grid_lines' => 5
	],
	'legend' => [
		'top_margin' => 20,
	]
]));

file_put_contents('mmapped.svg', svg_chart([
	['name' => 'Search speed in MiBytes per second', 'unit' => 'MiByte/s', 'to' => 1500, 'style' => 'fill: #3366cc', 'label_style' => ''],
], [
	[ /*10m-15-*/ "PHP\nstrstr by line",                /*7.102,*/      205,   /*  1.41*/],
	[ /*10m-16-*/ "PHP\nstrpos on content",             /*1.541,*/      946,   /*  6.49*/],
	[ /*10m-17-*/ "Python\nfind by line",               /*3.653,*/      399,   /*  2.74*/],
	[ /*10m-18-*/ "Python\nmmaped find on line",        /*2.747,*/      530,   /*  3.64*/],
	[ /*10m-19-*/ "Python\nfind on mmap",               /*1.935,*/      753,   /*  5.17*/],
	[ /*10m-20-*/ "Ruby\ninclude by line",              /*5.070,*/      287,   /*  1.97*/],
	[ /*10m-21-*/ "Ruby\nindex on content",             /*1.151,*/     1266,   /*  8.69*/],
], [
	'chart' => [
		'horizontal_padding' => 30,
		'grid_lines' => 6
	],
	'legend' => [
		'top_margin' => 20,
	]
]));

file_put_contents('10m.svg', svg_chart([
	['name' => 'wall time',                           'unit' => 's',        'to' => 8, 'style' => 'fill: #3366cc', 'label_style' => ''],
	//['name' => 'Speed in MiBytes per second',         'unit' => 'MiByte/s', 'to' => 20000, 'style' => 'fill: #4e9a06', 'label_style' => ''],
	//['name' => 'Speed in million lines per second',   'unit' => 'MLines/s', 'to' => 130, 'style' => 'fill: #dc3912', 'label_style' => '']
], [
	[ /*10m-00-*/ "warmup",                             0.880/*,     1656,    11.36*/],
	[ /*10m-01-*/ "grep-short",                         0.631/*,     2310,    15.85*/],
	[ /*10m-02-*/ "grep-medium",                        0.349/*,     4177,    28.65*/],
	[ /*10m-03-*/ "grep-long",                          0.280/*,     5207,    35.71*/],
	[ /*10m-04-*/ "sed",                                1.922/*,      758,     5.20*/],
	[ /*10m-05-*/ "awk",                                4.092/*,      356,     2.44*/],
	[ /*10m-06-*/ "mawk",                               1.724/*,      845,     5.80*/],
	[ /*10m-07-*/ "mawk-index",                         2.690/*,      542,     3.72*/],
	[ /*10m-08-*/ "c1-line-strstr",                     0.820/*,     1778,    12.20*/],
	[ /*10m-09-*/ "c2-line-str_contains",               1.841/*,      792,     5.43*/],
	[ /*10m-10-*/ "c3-line-fancy",                      1.919/*,      759,     5.21*/],
	[ /*10m-11-*/ "c4-all-strstr",                      0.181/*,     8055,    55.25*/],
	[ /*10m-12-*/ "c5-2threads-strstr",                 0.107/*,    13626,    93.46*/],
	[ /*10m-13-*/ "c5-4threads-strstr",                 0.093/*,    15678,   107.53*/],
	[ /*10m-14-*/ "c5-8threads-strstr",                 0.080/*,    18226,   125.00*/],
	[ /*10m-15-*/ "php1-line-strstr",                   7.102/*,      205,     1.41*/],
	[ /*10m-16-*/ "php2-all-strpos",                    1.541/*,      946,     6.49*/],
	[ /*10m-17-*/ "py1-line-find",                      3.653/*,      399,     2.74*/],
	[ /*10m-18-*/ "py2-mmap-line-find",                 2.747/*,      530,     3.64*/],
	[ /*10m-19-*/ "py3-mmap-all-find",                  1.935/*,      753,     5.17*/],
	[ /*10m-20-*/ "ruby1-line-include",                 5.070/*,      287,     1.97*/],
	[ /*10m-21-*/ "ruby2-all-index",                    1.151/*,     1266,     8.69*/],
], [
]));



file_put_contents('io-limit.svg', svg_chart([
	['name' => 'Search speed in MiBytes per second', 'unit' => 'MiByte/s', 'to' => 20000, 'style' => 'fill: #3366cc', 'label_style' => ''],
], [
#	[ /* 100m-00-warmup             */ "wc -l",                         /* 140.790, */     104,  /*   0.71 */],
	[ /* 100m-01-grep-short         */ "grep",                          /* 140.545, */     104,  /*   0.71 */],
	[ /* 100m-08-c1-line-strstr     */ "C\nstrstr by line",             /* 140.160, */     104,  /*   0.71 */],
	[ /* 100m-11-c4-all-strstr      */ "C\nstrstr on mmap\n1st run",    /* 140.34,  */     104,              ],
	[ /* 100m-11-c4-all-strstr      */ "C\nstrstr on mmap\n2nd run",    /*   1.94,  */    7564,              ],
	[ /* 100m-12-c5-2threads-strstr */ "C\nstrstr on mmap\n2 threads",  /*   1.040, */   14111,  /*  96.15 */],
	[ /* 100m-13-c5-4threads-strstr */ "C\nstrstr on mmap\n4 threads",  /*   0.870, */   16868,  /* 114.94 */],
	[ /* 100m-14-c5-8threads-strstr */ "C\nstrstr on mmap\n8 threads",  /*   0.870, */   16868,  /* 114.94 */],
	[ /* 100m-19-py3-mmap-all-find  */ "Python\nfind on mmap",          /*  18.520, */     792,  /*   5.40 */],
], [
	'chart' => [
		'horizontal_padding' => 30,
		'grid_lines' => 10
	],
	'legend' => [
		'top_margin' => 30,
	]
]));

?>