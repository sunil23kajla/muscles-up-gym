<?php
// backend-php/api/index.php
require_once 'config.php';
require_once 'jwt.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Global Demo Mode Detection
$isDemo = false;
$rawInput = file_get_contents('php://input');
$input = json_decode($rawInput, true) ?: [];

// Check login/register payload for demo email
if (isset($input['email']) && $input['email'] === 'sunilajsg@gmail.com') {
    $isDemo = true;
} else {
    // Check JWT payload for demo email
    $headers = getallheaders();
    $authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : '';
    if ($authHeader) {
        $parts = explode('.', str_replace('Bearer ', '', $authHeader));
        if (count($parts) === 3) {
            $base64UrlPayload = str_replace(['-', '_'], ['+', '/'], $parts[1]);
            $payload = json_decode(base64_decode($base64UrlPayload), true);
            if (isset($payload['email']) && $payload['email'] === 'sunilajsg@gmail.com') {
                $isDemo = true;
            } else if (isset($payload['user']['email']) && $payload['user']['email'] === 'sunilajsg@gmail.com') {
                $isDemo = true;
            }
        }
    }
}

// Initialize Database connection with the Demo flag
require_once 'database.php';
Database::getConnection($isDemo);

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$routeParts = explode('/', trim(str_replace('/api', '', $uri), '/'));

$resource = isset($routeParts[0]) ? $routeParts[0] : '';
$action = isset($routeParts[1]) ? $routeParts[1] : '';

// Get JSON input
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, TRUE);
if (!$input) {
    $input = $_POST;
}

try {
    switch ($resource) {
        case 'auth':
            require_once 'controllers/AuthController.php';
            $controller = new AuthController();
            $controller->handleRequestWithParts($routeParts, $input);
            break;

        case 'members':
            require_once 'controllers/MemberController.php';
            $controller = new MemberController();
            $controller->handleRequest($action, $routeParts, $input);
            break;

        case 'payments':
            require_once 'controllers/PaymentController.php';
            $controller = new PaymentController();
            $controller->handleRequest($action, $routeParts, $input);
            break;

        case 'attendance':
            require_once 'controllers/AttendanceController.php';
            $controller = new AttendanceController();
            $controller->handleRequest($action, $routeParts, $input);
            break;

        case 'dashboard':
            require_once 'controllers/DashboardController.php';
            $controller = new DashboardController();
            $controller->handleRequest($action, $routeParts, $input);
            break;
            
        case 'website':
            require_once 'controllers/WebsiteController.php';
            $controller = new WebsiteController();
            $controller->handleRequest($action, $routeParts, $input);
            break;

        case 'inquiries':
            require_once 'controllers/InquiryController.php';
            $controller = new InquiryController();
            $controller->handleRequest($action, $routeParts, $input);
            break;

        case 'updatedb':
            try {
                $db->exec("ALTER TABLE payments ADD COLUMN notes TEXT NULL");
                $db->exec("ALTER TABLE demo_payments ADD COLUMN notes TEXT NULL");
                sendJson(200, ["message" => "Database updated successfully!"]);
            } catch (PDOException $e) {
                sendJson(200, ["message" => "Columns already exist or error: " . $e->getMessage()]);
            }
            break;

        default:
            sendJson(404, ["message" => "Endpoint not found"]);
            break;
    }
} catch (Exception $e) {
    sendJson(500, ["message" => "Internal Server Error: " . $e->getMessage()]);
}
