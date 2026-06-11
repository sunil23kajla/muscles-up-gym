<?php
// backend-php/api/upload_gallery.php
require_once 'controllers/jwt.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["message" => "Method Not Allowed"]);
    exit;
}

// Verify Admin token
$req = verifyAuth();
if ($req['user']['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode(["message" => "Admin only"]);
    exit;
}

if (!isset($_FILES['media']) || $_FILES['media']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    $error = isset($_FILES['media']) ? $_FILES['media']['error'] : 'No file uploaded';
    echo json_encode(["message" => "File upload failed", "error_code" => $error]);
    exit;
}

$file = $_FILES['media'];
$filename = $file['name'];
$tmpPath = $file['tmp_name'];
$size = $file['size'];

// Extract extension
$ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));

// Allowed extensions
$allowedImages = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
$allowedVideos = ['mp4', 'mov', 'webm', 'avi'];
$allowed = array_merge($allowedImages, $allowedVideos);

if (!in_array($ext, $allowed)) {
    http_response_code(400);
    echo json_encode(["message" => "Invalid file type. Allowed: " . implode(", ", $allowed)]);
    exit;
}

// Validate file size manually (e.g. max 256MB)
$maxSize = 256 * 1024 * 1024;
if ($size > $maxSize) {
    http_response_code(400);
    echo json_encode(["message" => "File is too large. Max 256MB allowed."]);
    exit;
}

$uploadDir = __DIR__ . '/uploads/gallery/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

// Generate unique filename to avoid overwrites
$newFilename = uniqid('media_') . '.' . $ext;
$destPath = $uploadDir . $newFilename;

if (move_uploaded_file($tmpPath, $destPath)) {
    // Generate the public URL
    // Depending on routing, we might need the host. 
    // Usually, the app accesses via `https://musclesupgym.com/api/uploads/gallery/file.mp4`
    $url = '/api/uploads/gallery/' . $newFilename;
    
    // We don't automatically insert it into the database here, 
    // we return the URL so the app can call the standard update API if it wants.
    // Actually, it's safer if we just return the URL, and the App handles adding it to the `gallery` array.
    http_response_code(200);
    echo json_encode([
        "message" => "File uploaded successfully",
        "url" => $url
    ]);
} else {
    http_response_code(500);
    echo json_encode(["message" => "Failed to move uploaded file."]);
}
