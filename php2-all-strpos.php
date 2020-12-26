<?php

$search = $argv[1];
$file = $argv[2];

$data = file_get_contents($file);
$pos = 0;
while ( ($pos = strpos($data, $search, $pos)) !== false ) {
    $before = substr($data, 0, $pos);
    $start_pos = strrpos($before, "\n");
    $end_pos = strpos($data, "\n", $pos);
    if ($end_pos === false)
        $end_pos = strlen($data);
    echo(substr($data, $start_pos, $end_pos - $start_pos));
    
    $pos += strlen($search);
}

?>