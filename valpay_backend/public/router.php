<?php

// PHP built-in server router for Laravel
if (file_exists(__DIR__ . '/' . $_SERVER['REQUEST_URI'])) {
    return false; // Serve the file as-is
}

require_once __DIR__ . '/index.php';
