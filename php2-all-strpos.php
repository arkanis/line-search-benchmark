<?php

$search = $argv[1];
$file = $argv[2];

$data = file_get_contents($file);
$pos = 0;
while ( ($pos = strpos($data, $search, $pos)) !== false ) {
    $start_pos = strrpos(substr($data, 0, $pos), "\n");
    $start_pos = ($start_pos === false) ? 0 : $start_pos + 1;
    $end_pos = strpos($data, "\n", $pos);
    if ($end_pos === false)
        $end_pos = strlen($data);
    echo(substr($data, $start_pos, $end_pos - $start_pos) . "\n");
    
    $pos += strlen($search);
}

?>