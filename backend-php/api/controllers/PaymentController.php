<?php
// backend-php/api/controllers/PaymentController.php
require_once 'database.php';
require_once 'jwt.php';

class PaymentController {
    public function handleRequest($action, $routeParts, $input) {
        $method = $_SERVER['REQUEST_METHOD'];

        if ($method === 'GET' && $action === '') {
            $req = verifyAuth();
            $this->getAllPayments($req);
        } else if ($method === 'GET' && $action === 'reports') {
            $req = verifyAuth();
            $this->getFinancialReports($req);
        } else if ($method === 'POST' && $action === '') {
            $req = verifyAuth();
            $this->createPayment($input, $req);
        } else {
            sendJson(405, ["message" => "Method not allowed"]);
        }
    }

    private function createPayment($input, $req) {
        $memberId = isset($input['memberId']) ? $input['memberId'] : null;
        $amount = isset($input['amount']) ? $input['amount'] : null;
        $paymentDate = isset($input['paymentDate']) ? $input['paymentDate'] : null;
        $notes = isset($input['notes']) ? $input['notes'] : null;

        $db = Database::getConnection();
        
        $stmt = $db->prepare("SELECT id FROM members WHERE id = ?");
        $stmt->execute([$memberId]);
        if (!$stmt->fetch()) {
            sendJson(404, ["message" => "Member not found."]);
        }

        $todayStr = date('Y-m-d');
        if ($paymentDate && $paymentDate > $todayStr) {
            sendJson(400, ["message" => "Payment date cannot be in the future."]);
        }

        $pDate = $paymentDate ? $paymentDate : $todayStr;

        $insertStmt = $db->prepare("INSERT INTO payments (memberId, amount, paymentDate, notes) VALUES (?, ?, ?, ?)");
        try {
            $insertStmt->execute([$memberId, $amount, $pDate, $notes]);
            $paymentId = $db->lastInsertId();
            
            $fetchStmt = $db->prepare("SELECT * FROM payments WHERE id = ?");
            $fetchStmt->execute([$paymentId]);
            sendJson(201, $fetchStmt->fetch());
        } catch (PDOException $e) {
            sendJson(500, ["message" => "Failed to record payment.", "error" => $e->getMessage()]);
        }
    }

    private function getAllPayments($req) {
        $db = Database::getConnection();
        // include member attributes: name, phone, photo
        $stmt = $db->prepare("
            SELECT p.*, m.name as member_name, m.phone as member_phone, m.photo as member_photo 
            FROM payments p 
            JOIN members m ON p.memberId = m.id 
            ORDER BY p.paymentDate DESC, p.createdAt DESC
        ");
        $stmt->execute();
        $payments = $stmt->fetchAll();

        $formatted = [];
        foreach ($payments as $p) {
            $formattedPayment = [
                'id' => $p['id'],
                'memberId' => $p['memberId'],
                'amount' => $p['amount'],
                'paymentDate' => $p['paymentDate'],
                'notes' => $p['notes'],
                'createdAt' => $p['createdAt'],
                'updatedAt' => $p['updatedAt'],
                'member' => [
                    'name' => $p['member_name'],
                    'phone' => $p['member_phone'],
                    'photo' => $p['member_photo']
                ]
            ];
            $formatted[] = $formattedPayment;
        }

        sendJson(200, $formatted);
    }

    private function getFinancialReports($req) {
        $db = Database::getConnection();
        
        $todayStr = date('Y-m-d');
        $startOfMonthStr = date('Y-m-01');
        $startOfYearStr = date('Y-01-01');

        // 1. Today's collection
        $stmtToday = $db->prepare("SELECT SUM(amount) as total FROM payments WHERE paymentDate = ?");
        $stmtToday->execute([$todayStr]);
        $todayTotal = $stmtToday->fetch()['total'] ?: 0;

        // 2. Month's collection
        $stmtMonth = $db->prepare("SELECT SUM(amount) as total, COUNT(id) as count FROM payments WHERE paymentDate BETWEEN ? AND ?");
        $stmtMonth->execute([$startOfMonthStr, $todayStr]);
        $monthData = $stmtMonth->fetch();
        $monthlyTotal = $monthData['total'] ?: 0;
        $monthlyPaymentsCount = $monthData['count'] ?: 0;

        // 3. Year's collection
        $stmtYear = $db->prepare("SELECT SUM(amount) as total, COUNT(id) as count FROM payments WHERE paymentDate BETWEEN ? AND ?");
        $stmtYear->execute([$startOfYearStr, $todayStr]);
        $yearData = $stmtYear->fetch();
        $yearlyTotal = $yearData['total'] ?: 0;
        $yearlyPaymentsCount = $yearData['count'] ?: 0;

        // 4. Daily Breakdown for current month
        $stmtDaily = $db->prepare("SELECT paymentDate as date, SUM(amount) as amount FROM payments WHERE paymentDate BETWEEN ? AND ? GROUP BY paymentDate ORDER BY paymentDate ASC");
        $stmtDaily->execute([$startOfMonthStr, $todayStr]);
        $dailyChartData = $stmtDaily->fetchAll();

        sendJson(200, [
            "summary" => [
                "today" => (float)$todayTotal,
                "monthly" => (float)$monthlyTotal,
                "yearly" => (float)$yearlyTotal
            ],
            "dailyChartData" => $dailyChartData,
            "monthlyPaymentsCount" => (int)$monthlyPaymentsCount,
            "yearlyPaymentsCount" => (int)$yearlyPaymentsCount
        ]);
    }
}
