<?php
require_once 'database.php';
try {
    $db = Database::getConnection();
    // Use IF NOT EXISTS equivalent for columns by ignoring duplicates or checking information schema
    // To keep it simple, we catch exceptions.
    try {
        $db->exec("ALTER TABLE payments ADD COLUMN notes TEXT NULL");
        echo "notes column added to payments.<br>";
    } catch (PDOException $e) { echo "payments table already has notes or error: " . $e->getMessage() . "<br>"; }

    try {
        $db->exec("ALTER TABLE demo_payments ADD COLUMN notes TEXT NULL");
        echo "notes column added to demo_payments.<br>";
    } catch (PDOException $e) { echo "demo_payments table already has notes or error: " . $e->getMessage() . "<br>"; }

    echo "Update complete!";
} catch (Exception $e) {
    echo "Connection error: " . $e->getMessage();
}
?>
