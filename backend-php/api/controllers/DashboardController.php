<?php
// backend-php/api/controllers/DashboardController.php
require_once 'database.php';
require_once 'jwt.php';

class DashboardController {
    public function handleRequest($action, $routeParts, $input) {
        $method = $_SERVER['REQUEST_METHOD'];

        if ($method === 'GET' && $action === 'stats') {
            $req = verifyAuth();
            $this->getDashboardStats($req);
        } else {
            sendJson(405, ["message" => "Method not allowed"]);
        }
    }

    private function getDashboardStats($req) {
        $db = Database::getConnection();

        // 1. Members stats
        $stmtMembers = $db->query("SELECT status, createdAt FROM members");
        $members = $stmtMembers->fetchAll();

        $todayStr = date('Y-m-d');
        
        $totalMembers = count($members);
        $activeMembers = 0;
        $expiredMembers = 0;
        $pendingMembers = 0;
        $newToday = 0;

        foreach ($members as $m) {
            if ($m['status'] === 'active') $activeMembers++;
            if ($m['status'] === 'expired') $expiredMembers++;
            if ($m['status'] === 'pending') $pendingMembers++;
            
            $createdDate = date('Y-m-d', strtotime($m['createdAt']));
            if ($createdDate === $todayStr) {
                $newToday++;
            }
        }

        // 2. Collections
        $startOfMonthStr = date('Y-m-01');
        $startOfYearStr = date('Y-01-01');

        $stmtToday = $db->prepare("SELECT SUM(amount) as total FROM payments WHERE paymentDate = ?");
        $stmtToday->execute([$todayStr]);
        $todayCollection = $stmtToday->fetch()['total'] ?: 0;

        $stmtMonth = $db->prepare("SELECT SUM(amount) as total FROM payments WHERE paymentDate BETWEEN ? AND ?");
        $stmtMonth->execute([$startOfMonthStr, $todayStr]);
        $monthlyCollection = $stmtMonth->fetch()['total'] ?: 0;

        $stmtYear = $db->prepare("SELECT SUM(amount) as total FROM payments WHERE paymentDate BETWEEN ? AND ?");
        $stmtYear->execute([$startOfYearStr, $todayStr]);
        $yearlyCollection = $stmtYear->fetch()['total'] ?: 0;

        // 3. Alerts (upcoming expirations)
        $tenDaysLaterStr = date('Y-m-d', strtotime('+10 days'));
        $stmtExpirations = $db->prepare("SELECT COUNT(*) as count FROM members WHERE subscriptionEnd BETWEEN ? AND ?");
        $stmtExpirations->execute([$todayStr, $tenDaysLaterStr]);
        $upcomingExpirations = $stmtExpirations->fetch()['count'] ?: 0;

        sendJson(200, [
            "members" => [
                "total" => $totalMembers,
                "active" => $activeMembers,
                "expired" => $expiredMembers,
                "pending" => $pendingMembers,
                "newToday" => $newToday
            ],
            "collections" => [
                "today" => (float)$todayCollection,
                "monthly" => (float)$monthlyCollection,
                "yearly" => (float)$yearlyCollection
            ],
            "alerts" => [
                "upcomingExpirations" => (int)$upcomingExpirations
            ]
        ]);
    }
}
