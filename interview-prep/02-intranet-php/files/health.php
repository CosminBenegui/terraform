<?php
$config = @parse_ini_file(__DIR__ . '/config.ini');
if (!is_array($config) || (($config['status'] ?? '') !== 'ok')) {
    http_response_code(500);
    header('Content-Type: text/plain');
    echo "config unreadable\n";
    exit;
}
header('Content-Type: text/plain');
echo "ok\n";
