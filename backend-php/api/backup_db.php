<?php
// backend-php/api/backup_db.php
require_once 'database.php';

// A simple secret key to prevent unauthorized access
$secretKey = "sunil_musclesup_auto_backup_key";

if (!isset($_GET['key']) || $_GET['key'] !== $secretKey) {
    http_response_code(403);
    echo json_encode(["status" => "error", "message" => "Unauthorized backup request."]);
    exit();
}

try {
    $db = Database::getConnection();
    
    $tables = ['users', 'members', 'inquiries', 'payments', 'workouts', 'attendances', 'website_settings'];
    $backupData = [];

    foreach ($tables as $table) {
        $stmt = $db->query("SELECT * FROM $table");
        $backupData[$table] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    $backupDir = __DIR__ . '/backups';
    if (!is_dir($backupDir)) {
        mkdir($backupDir, 0755, true);
    }

    $dateStr = date('Y-m-d_H-i-s');
    $fileName = "db_backup_$dateStr.json";
    $filePath = $backupDir . '/' . $fileName;

    file_put_contents($filePath, json_encode($backupData, JSON_PRETTY_PRINT));

    echo json_encode(["status" => "success", "message" => "Backup created successfully", "file" => $fileName]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Backup failed: " . $e->getMessage()]);
}
?>
