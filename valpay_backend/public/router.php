<?php

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?? '/');
error_log('[router] uri=' . $uri . ' file=' . (__DIR__ . $uri));

if ($uri !== '/' && file_exists(__DIR__ . $uri)) {
    error_log('[router] serving static: ' . $uri);
    return false;
}

error_log('[router] dispatching to Laravel: ' . $uri);
try {
    require_once __DIR__ . '/index.php';
} catch (\Throwable $e) {
    error_log('[router] FATAL: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode(['error' => $e->getMessage()]);
}
