<?php
/* RC1 temporary staging-only probe. Remove immediately after verification. */
$ip = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : '';
if ($ip !== '127.0.0.1' && $ip !== '::1') {
    header('HTTP/1.1 403 Forbidden');
    exit;
}
header('Content-Type: text/plain; charset=UTF-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
echo 'sapi=', php_sapi_name(), "\n";
echo 'php_version=', PHP_VERSION, "\n";
echo 'memory_limit=', ini_get('memory_limit'), "\n";
echo 'max_multipart_body_parts=', ini_get('max_multipart_body_parts'), "\n";
echo 'session.upload_progress.enabled=', ini_get('session.upload_progress.enabled'), "\n";
