<?php
require_once 'database.php';

try {
    $db = Database::getConnection();

    // DROP existing tables
    $db->exec("SET FOREIGN_KEY_CHECKS = 0;");
    // Drop demo tables if they exist
    $db->exec("DROP TABLE IF EXISTS demo_attendances");
    $db->exec("DROP TABLE IF EXISTS demo_workouts");
    $db->exec("DROP TABLE IF EXISTS demo_payments");
    $db->exec("DROP TABLE IF EXISTS demo_members");
    $db->exec("DROP TABLE IF EXISTS demo_inquiries");
    $db->exec("DROP TABLE IF EXISTS demo_website_settings");
    $db->exec("DROP TABLE IF EXISTS demo_users");

    // Drop original tables if they exist (Order matters due to foreign keys)
    $db->exec("DROP TABLE IF EXISTS attendances");
    $db->exec("DROP TABLE IF EXISTS workouts");
    $db->exec("DROP TABLE IF EXISTS payments");
    $db->exec("DROP TABLE IF EXISTS members");
    $db->exec("DROP TABLE IF EXISTS inquiries");
    $db->exec("DROP TABLE IF EXISTS website_settings");
    $db->exec("DROP TABLE IF EXISTS users");
    $db->exec("DROP TABLE IF EXISTS attendance;"); // Old PHP table name
    $db->exec("SET FOREIGN_KEY_CHECKS = 1;");

    echo "Creating 'users' table...<br>";
    $db->exec("CREATE TABLE users (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        role ENUM('admin', 'staff') NOT NULL DEFAULT 'staff',
        status ENUM('pending', 'approved') NOT NULL DEFAULT 'pending',
        createdAt DATETIME NOT NULL,
        updatedAt DATETIME NOT NULL
    )");

    echo "Creating 'demo_users' table...<br>";
    $db->exec("CREATE TABLE demo_users (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        role ENUM('admin', 'staff') NOT NULL DEFAULT 'staff',
        status ENUM('pending', 'approved') NOT NULL DEFAULT 'pending',
        createdAt DATETIME NOT NULL,
        updatedAt DATETIME NOT NULL
    )");

    echo "Creating 'website_settings' table...<br>";
    $db->exec("CREATE TABLE website_settings (
        `key` VARCHAR(255) PRIMARY KEY,
        value TEXT NOT NULL
    )");

    echo "Creating 'demo_website_settings' table...<br>";
    $db->exec("CREATE TABLE demo_website_settings (
        `key` VARCHAR(255) PRIMARY KEY,
        value TEXT NOT NULL
    )");

    echo "Creating 'inquiries' table...<br>";
    $db->exec("CREATE TABLE inquiries (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        packageName VARCHAR(255) NOT NULL,
        message TEXT,
        status ENUM('pending', 'contacted', 'joined') NOT NULL DEFAULT 'pending',
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )");

    echo "Creating 'demo_inquiries' table...<br>";
    $db->exec("CREATE TABLE demo_inquiries (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        packageName VARCHAR(255) NOT NULL,
        message TEXT,
        status ENUM('pending', 'contacted', 'joined') NOT NULL DEFAULT 'pending',
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )");

    echo "Creating 'members' table...<br>";
    $db->exec("CREATE TABLE members (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        photo LONGTEXT,
        gender VARCHAR(10),
        age INT,
        height FLOAT,
        weight FLOAT,
        bloodGroup VARCHAR(5),
        address TEXT,
        subscriptionType VARCHAR(50),
        subscriptionStart DATE,
        subscriptionEnd DATE,
        status ENUM('active', 'expired', 'pending') NOT NULL DEFAULT 'pending',
        createdAt DATETIME NOT NULL,
        updatedAt DATETIME NOT NULL
    )");

    echo "Creating 'demo_members' table...<br>";
    $db->exec("CREATE TABLE demo_members (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        photo LONGTEXT,
        gender VARCHAR(10),
        age INT,
        height FLOAT,
        weight FLOAT,
        bloodGroup VARCHAR(5),
        address TEXT,
        subscriptionType VARCHAR(50),
        subscriptionStart DATE,
        subscriptionEnd DATE,
        status ENUM('active', 'expired', 'pending') NOT NULL DEFAULT 'pending',
        createdAt DATETIME NOT NULL,
        updatedAt DATETIME NOT NULL
    )");

    echo "Creating 'payments' table...<br>";
    $db->exec("CREATE TABLE payments (
        id INT AUTO_INCREMENT PRIMARY KEY,
        memberId VARCHAR(36) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        paymentDate DATE NOT NULL,
        notes TEXT,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (memberId) REFERENCES members(id) ON DELETE CASCADE
    )");

    echo "Creating 'demo_payments' table...<br>";
    $db->exec("CREATE TABLE demo_payments (
        id INT AUTO_INCREMENT PRIMARY KEY,
        memberId VARCHAR(36) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        paymentDate DATE NOT NULL,
        notes TEXT,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (memberId) REFERENCES demo_members(id) ON DELETE CASCADE
    )");

    echo "Creating 'workouts' table...<br>";
    $db->exec("CREATE TABLE workouts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        memberId VARCHAR(36) NOT NULL,
        planName VARCHAR(255),
        details TEXT,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (memberId) REFERENCES members(id) ON DELETE CASCADE
    )");

    echo "Creating 'demo_workouts' table...<br>";
    $db->exec("CREATE TABLE demo_workouts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        memberId VARCHAR(36) NOT NULL,
        planName VARCHAR(255),
        details TEXT,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (memberId) REFERENCES demo_members(id) ON DELETE CASCADE
    )");

    echo "Creating 'attendances' table...<br>";
    $db->exec("CREATE TABLE attendances (
        id INT AUTO_INCREMENT PRIMARY KEY,
        memberId VARCHAR(36) NOT NULL,
        date DATE NOT NULL,
        status VARCHAR(20) NOT NULL,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (memberId) REFERENCES members(id) ON DELETE CASCADE
    )");

    echo "Creating 'demo_attendances' table...<br>";
    $db->exec("CREATE TABLE demo_attendances (
        id INT AUTO_INCREMENT PRIMARY KEY,
        memberId VARCHAR(36) NOT NULL,
        date DATE NOT NULL,
        status VARCHAR(20) NOT NULL,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (memberId) REFERENCES demo_members(id) ON DELETE CASCADE
    )");

    echo "Database tables created successfully, matching the Node.js Sequelize models!<br>";

    // Insert Default Website Configurations (Optional)
    $defaultConfigs = [
        'announcement' => ['show' => true, 'text' => '🔥 SUMMER SPEC-OPS OFFER: Enroll on a 1-Year Membership today and get 2 Months of personal training absolutely FREE!'],
        'stats' => ['membersTrained' => '1,500+', 'certifiedTrainers' => '8+', 'yearsExp' => '5+'],
        'gallery' => [],
        'videos' => [],
        'plans' => [
            ['name' => "MONTHLY CARDIO & WEIGHTS", 'price' => "₹1,500", 'period' => "/month", 'features' => ["Access to Weight Floor", "Free Locker Access", "General Trainer Guidance"], 'badge' => "Standard", 'isFeatured' => false],
            ['name' => "6-MONTHS PRO-FITNESS", 'price' => "₹7,500", 'period' => "/6 months", 'features' => ["All Weight Floor access", "Free locker & showers", "2 Free body scans", "Personalized Workout Draft"], 'badge' => "Best Value", 'isFeatured' => true],
            ['name' => "1-YEAR VIP MUSCLE UP", 'price' => "₹12,000", 'period' => "/year", 'features' => ["24/7 Premium Gym Access", "Free locker, steam & sauna", "Monthly Dietitian checks", "1 Personal Coach slot", "Exclusive VIP Lounge access"], 'badge' => "Premium", 'isFeatured' => false]
        ],
        'contact' => ['address' => "Opposite High Court Lane, Sector 4, New Delhi", 'phone' => "9876543210", 'email' => "support@musclesup.com"]
    ];

    $stmtSettings = $db->prepare("INSERT INTO website_settings (`key`, value) VALUES (?, ?)");
    $stmtDemoSettings = $db->prepare("INSERT INTO demo_website_settings (`key`, value) VALUES (?, ?)");
    
    foreach ($defaultConfigs as $key => $val) {
        $json = json_encode($val);
        $stmtSettings->execute([$key, $json]);
        $stmtDemoSettings->execute([$key, $json]);
    }
    echo "Default website configurations inserted.<br>";

} catch (PDOException $e) {
    echo "Database error: " . $e->getMessage();
}
?>
