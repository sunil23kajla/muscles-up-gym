<?php
// backend-php/api/config.php

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, x-auth-token");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database Credentials
define('DB_HOST', 'localhost');
define('DB_USER', 'u607375181_admin');
define('DB_PASS', 'StrongBody$2026*Up');
define('DB_NAME', 'u607375181_gym');

// JWT Secret
define('JWT_SECRET', 'this_is_a_very_secret_key_for_muscleup_jwt_token_auth_v2');

// Helper to send JSON responses
function sendJson($status, $data) {
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit();
}

// Global Exception Handler
set_exception_handler(function($e) {
    error_log($e->getMessage());
    sendJson(500, ["message" => "Server Error"]);
});
