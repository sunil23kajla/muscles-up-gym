<?php
// backend-php/api/controllers/WebsiteController.php
require_once 'database.php';
require_once 'jwt.php';

class WebsiteController {
    private $defaultConfigs = [
        'announcement' => [
            'show' => true,
            'text' => '🔥 SUMMER SPEC-OPS OFFER: Enroll on a 1-Year Membership today and get 2 Months of personal training absolutely FREE!'
        ],
        'stats' => [
            'membersTrained' => '1,500+',
            'certifiedTrainers' => '8+',
            'yearsExp' => '5+'
        ],
        'gallery' => [],
        'videos' => [],
        'plans' => [
            [
                'name' => "MONTHLY CARDIO & WEIGHTS",
                'price' => "₹1,500",
                'period' => "/month",
                'features' => [
                    "Access to Weight Floor",
                    "Free Locker Access",
                    "General Trainer Guidance"
                ],
                'badge' => "Standard",
                'isFeatured' => false
            ],
            [
                'name' => "6-MONTHS PRO-FITNESS",
                'price' => "₹7,500",
                'period' => "/6 months",
                'features' => [
                    "All Weight Floor access",
                    "Free locker & showers",
                    "2 Free body scans",
                    "Personalized Workout Draft"
                ],
                'badge' => "Best Value",
                'isFeatured' => true
            ],
            [
                'name' => "1-YEAR VIP MUSCLE UP",
                'price' => "₹12,000",
                'period' => "/year",
                'features' => [
                    "24/7 Premium Gym Access",
                    "Free locker, steam & sauna",
                    "Monthly Dietitian checks",
                    "1 Personal Coach slot",
                    "Exclusive VIP Lounge access"
                ],
                'badge' => "Premium",
                'isFeatured' => false
            ]
        ],
        'contact' => [
            'address' => "Opposite High Court Lane, Sector 4, New Delhi",
            'phone' => "9876543210",
            'email' => "support@musclesup.com"
        ]
    ];

    public function handleRequest($action, $routeParts, $input) {
        $method = $_SERVER['REQUEST_METHOD'];

        if ($method === 'GET' && $action === '') {
            $this->getWebsiteConfig();
        } else if ($method === 'PUT' && $action === '') {
            $req = verifyAuth();
            if ($req['user']['role'] !== 'admin') sendJson(403, ["message" => "Admin only"]);
            $this->updateWebsiteSetting($input);
        } else {
            sendJson(405, ["message" => "Method not allowed"]);
        }
    }

    private function getOrCreateSetting($db, $key, $defaultValue) {
        $stmt = $db->prepare("SELECT value FROM website_settings WHERE `key` = ?");
        $stmt->execute([$key]);
        $row = $stmt->fetch();

        if ($row) {
            return json_decode($row['value'], true);
        } else {
            $insertStmt = $db->prepare("INSERT INTO website_settings (`key`, value) VALUES (?, ?)");
            $insertStmt->execute([$key, json_encode($defaultValue)]);
            return $defaultValue;
        }
    }

    private function getWebsiteConfig() {
        $db = Database::getConnection();

        $announcement = $this->getOrCreateSetting($db, 'announcement', $this->defaultConfigs['announcement']);
        $stats = $this->getOrCreateSetting($db, 'stats', $this->defaultConfigs['stats']);
        $gallery = $this->getOrCreateSetting($db, 'gallery', $this->defaultConfigs['gallery']);
        $videos = $this->getOrCreateSetting($db, 'videos', $this->defaultConfigs['videos']);
        $plans = $this->getOrCreateSetting($db, 'plans', $this->defaultConfigs['plans']);
        $contact = $this->getOrCreateSetting($db, 'contact', $this->defaultConfigs['contact']);

        sendJson(200, [
            "announcement" => $announcement,
            "stats" => $stats,
            "gallery" => $gallery,
            "videos" => $videos,
            "plans" => $plans,
            "contact" => $contact
        ]);
    }

    private function updateWebsiteSetting($input) {
        $key = isset($input['key']) ? $input['key'] : null;
        $value = isset($input['value']) ? $input['value'] : null;

        if (!$key || $value === null) {
            sendJson(400, ["message" => "Key and Value are required."]);
        }

        $allowedKeys = ['announcement', 'stats', 'gallery', 'videos', 'plans', 'contact'];
        if (!in_array($key, $allowedKeys)) {
            sendJson(400, ["message" => "Invalid configuration key."]);
        }

        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT `key` FROM website_settings WHERE `key` = ?");
        $stmt->execute([$key]);
        $exists = $stmt->fetch();

        if ($exists) {
            $updateStmt = $db->prepare("UPDATE website_settings SET value = ? WHERE `key` = ?");
            $updateStmt->execute([json_encode($value), $key]);
        } else {
            $insertStmt = $db->prepare("INSERT INTO website_settings (`key`, value) VALUES (?, ?)");
            $insertStmt->execute([$key, json_encode($value)]);
        }

        sendJson(200, [
            "message" => "Website configuration updated successfully!",
            "key" => $key,
            "value" => $value
        ]);
    }
}
