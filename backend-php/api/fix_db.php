<?php
require_once 'database.php';

try {
    $db = Database::getConnection();
    
    // Alter website_settings and demo_website_settings
    $db->exec("ALTER TABLE website_settings MODIFY value LONGTEXT NOT NULL;");
    $db->exec("ALTER TABLE demo_website_settings MODIFY value LONGTEXT NOT NULL;");
    
    echo "Database successfully patched. Column 'value' is now LONGTEXT.";
} catch (PDOException $e) {
    echo "Database error: " . $e->getMessage();
}
?>
