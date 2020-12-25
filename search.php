<?php

$search = $argv[1];
$file = $argv[2];

$fd = fopen($file, "rb");
while ( ($line = fgets($fd)) ) {
    if ( strstr($line, $search) )
        echo($line);
}
fclose($fd);

?>