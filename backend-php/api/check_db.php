<?php
require_once 'database.php';

$email = 'musclesupgymoffical@gmail.com';

try {
    $db = (new Database())->getConnection();
    
    // Check main users
    $stmt = $db->prepare("SELECT id, name, email, role FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $mainAdmin = $stmt->fetch(PDO::FETCH_ASSOC);

    // Check demo users
    $stmt = $db->prepare("SELECT id, name, email, role FROM demo_users WHERE email = ?");
    $stmt->execute([$email]);
    $demoAdmin = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        "main_admin" => $mainAdmin,
        "demo_admin" => $demoAdmin
    ]);

} catch (Exception $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
