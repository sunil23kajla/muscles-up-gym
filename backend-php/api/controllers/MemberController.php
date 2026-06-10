<?php
// backend-php/api/controllers/MemberController.php
require_once 'database.php';
require_once 'jwt.php';

class MemberController {
    public function handleRequest($action, $routeParts, $input) {
        $method = $_SERVER['REQUEST_METHOD'];

        if ($method === 'GET' && $action === '') {
            $req = verifyAuth();
            $this->getAllMembers($req);
        } else if ($method === 'GET' && $action === 'expiring') {
            $req = verifyAuth();
            $this->getUpcomingExpiries($req);
        } else if ($method === 'GET' && $action === 'expired') {
            $req = verifyAuth();
            $this->getExpiredMembers($req);
        } else if ($method === 'GET' && isset($routeParts[1])) {
            $req = verifyAuth();
            $this->getMemberById($routeParts[1], $req);
        } else if ($method === 'POST' && $action === '') {
            $req = verifyAuth();
            $this->createMember($input, $req);
        } else if ($method === 'PUT' && isset($routeParts[1])) {
            $req = verifyAuth();
            $this->updateMember($routeParts[1], $input, $req);
        } else if ($method === 'DELETE' && isset($routeParts[1])) {
            $req = verifyAuth();
            if ($req['user']['role'] !== 'admin') sendJson(403, ["message" => "Admin only"]);
            $this->deleteMember($routeParts[1], $req);
        } else {
            sendJson(405, ["message" => "Method not allowed"]);
        }
    }

    private function generateUuid() {
        return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x', mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0x0fff) | 0x4000, mt_rand(0, 0x3fff) | 0x8000, mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff));
    }

    private function autoRecalculateStatus($member) {
        $todayStr = date('Y-m-d');
        $start = $member['subscriptionStart'];
        $end = $member['subscriptionEnd'];

        $computedStatus = 'active';
        if ($todayStr < $start) {
            $computedStatus = 'pending';
        } else if ($todayStr > $end) {
            $computedStatus = 'expired';
        }

        if ($member['status'] !== $computedStatus) {
            $member['status'] = $computedStatus;
            $db = Database::getConnection();
            $stmt = $db->prepare("UPDATE members SET status = ? WHERE id = ?");
            $stmt->execute([$computedStatus, $member['id']]);
        }
        return $member;
    }

    private function createMember($input, $req) {
        $db = Database::getConnection();
        $id = $this->generateUuid();
        
        $name = isset($input['name']) ? $input['name'] : null;
        $phone = isset($input['phone']) ? $input['phone'] : null;
        $photo = isset($input['photo']) ? $input['photo'] : null;
        $height = isset($input['height']) ? $input['height'] : null;
        $weight = isset($input['weight']) ? $input['weight'] : null;
        $bloodGroup = isset($input['bloodGroup']) ? $input['bloodGroup'] : null;
        $subscriptionStart = isset($input['subscriptionStart']) ? $input['subscriptionStart'] : null;
        $subscriptionEnd = isset($input['subscriptionEnd']) ? $input['subscriptionEnd'] : null;
        $plan = isset($input['plan']) ? $input['plan'] : '1 Month';
        
        $member = [
            'id' => $id,
            'name' => $name,
            'phone' => $phone,
            'photo' => $photo,
            'height' => $height,
            'weight' => $weight,
            'bloodGroup' => $bloodGroup,
            'subscriptionStart' => $subscriptionStart,
            'subscriptionEnd' => $subscriptionEnd,
            'plan' => $plan,
            'status' => 'pending'
        ];

        $member = $this->autoRecalculateStatus($member);

        $stmt = $db->prepare("INSERT INTO members (id, name, phone, photo, height, weight, bloodGroup, subscriptionStart, subscriptionEnd, subscriptionType, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        try {
            $stmt->execute([
                $id, $name, $phone, $photo, $height, $weight, $bloodGroup, $subscriptionStart, $subscriptionEnd, $plan, $member['status']
            ]);
            
            $fetchStmt = $db->prepare("SELECT * FROM members WHERE id = ?");
            $fetchStmt->execute([$id]);
            sendJson(201, $fetchStmt->fetch());
        } catch (PDOException $e) {
            sendJson(500, ["message" => "Failed to create member.", "error" => $e->getMessage()]);
        }
    }

    private function getAllMembers($req) {
        $status = isset($_GET['status']) ? $_GET['status'] : null;
        $search = isset($_GET['search']) ? $_GET['search'] : null;

        $db = Database::getConnection();
        
        $query = "SELECT * FROM members WHERE 1=1";
        $params = [];

        if ($search) {
            $query .= " AND (name LIKE ? OR phone LIKE ?)";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        $stmt = $db->prepare($query);
        $stmt->execute($params);
        $members = $stmt->fetchAll();

        $updatedMembers = [];
        foreach ($members as $member) {
            $member = $this->autoRecalculateStatus($member);
            if (!$status || $member['status'] === $status) {
                $updatedMembers[] = $member;
            }
        }

        sendJson(200, $updatedMembers);
    }

    private function getMemberById($id, $req) {
        $db = Database::getConnection();
        
        $stmt = $db->prepare("SELECT * FROM members WHERE id = ?");
        $stmt->execute([$id]);
        $member = $stmt->fetch();

        if (!$member) {
            sendJson(404, ["message" => "Member not found."]);
        }

        $member = $this->autoRecalculateStatus($member);

        // Include relations
        $stmtPayments = $db->prepare("SELECT * FROM payments WHERE memberId = ?");
        $stmtPayments->execute([$id]);
        $member['payments'] = $stmtPayments->fetchAll();

        $stmtAttendance = $db->prepare("SELECT * FROM attendances WHERE memberId = ?");
        $stmtAttendance->execute([$id]);
        $member['attendance'] = $stmtAttendance->fetchAll();

        $stmtWorkout = $db->prepare("SELECT * FROM workouts WHERE memberId = ?");
        $stmtWorkout->execute([$id]);
        $member['workout'] = $stmtWorkout->fetch() ?: null;

        sendJson(200, $member);
    }

    private function updateMember($id, $input, $req) {
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM members WHERE id = ?");
        $stmt->execute([$id]);
        $member = $stmt->fetch();

        if (!$member) {
            sendJson(404, ["message" => "Member not found."]);
        }

        $name = isset($input['name']) ? $input['name'] : $member['name'];
        $phone = isset($input['phone']) ? $input['phone'] : $member['phone'];
        $photo = array_key_exists('photo', $input) ? $input['photo'] : $member['photo'];
        $height = array_key_exists('height', $input) ? $input['height'] : $member['height'];
        $weight = array_key_exists('weight', $input) ? $input['weight'] : $member['weight'];
        $bloodGroup = array_key_exists('bloodGroup', $input) ? $input['bloodGroup'] : $member['bloodGroup'];
        $subscriptionStart = isset($input['subscriptionStart']) ? $input['subscriptionStart'] : $member['subscriptionStart'];
        $subscriptionEnd = isset($input['subscriptionEnd']) ? $input['subscriptionEnd'] : $member['subscriptionEnd'];
        $plan = array_key_exists('plan', $input) ? $input['plan'] : $member['plan'];

        $member['name'] = $name;
        $member['phone'] = $phone;
        $member['photo'] = $photo;
        $member['height'] = $height;
        $member['weight'] = $weight;
        $member['bloodGroup'] = $bloodGroup;
        $member['subscriptionStart'] = $subscriptionStart;
        $member['subscriptionEnd'] = $subscriptionEnd;
        $member['plan'] = $plan;

        $member = $this->autoRecalculateStatus($member);

        $updateStmt = $db->prepare("UPDATE members SET name=?, phone=?, photo=?, height=?, weight=?, bloodGroup=?, subscriptionStart=?, subscriptionEnd=?, subscriptionType=?, status=? WHERE id=?");
        $updateStmt->execute([
            $member['name'], $member['phone'], $member['photo'], $member['height'], $member['weight'], $member['bloodGroup'], $member['subscriptionStart'], $member['subscriptionEnd'], $member['plan'], $member['status'], $id
        ]);

        sendJson(200, $member);
    }

    private function deleteMember($id, $req) {
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT id FROM members WHERE id = ?");
        $stmt->execute([$id]);
        if (!$stmt->fetch()) {
            sendJson(404, ["message" => "Member not found."]);
        }

        $delStmt = $db->prepare("DELETE FROM members WHERE id = ?");
        $delStmt->execute([$id]);
        sendJson(200, ["message" => "Member deleted successfully."]);
    }

    private function getUpcomingExpiries($req) {
        $db = Database::getConnection();
        $todayStr = date('Y-m-d');
        $tenDaysLaterStr = date('Y-m-d', strtotime('+10 days'));

        $stmt = $db->prepare("SELECT * FROM members WHERE subscriptionEnd BETWEEN ? AND ? ORDER BY subscriptionEnd ASC");
        $stmt->execute([$todayStr, $tenDaysLaterStr]);
        $members = $stmt->fetchAll();

        $updatedMembers = [];
        foreach ($members as $member) {
            $updatedMembers[] = $this->autoRecalculateStatus($member);
        }

        sendJson(200, $updatedMembers);
    }

    private function getExpiredMembers($req) {
        $db = Database::getConnection();
        $todayStr = date('Y-m-d');

        $stmt = $db->prepare("SELECT * FROM members WHERE subscriptionEnd < ? ORDER BY subscriptionEnd DESC");
        $stmt->execute([$todayStr]);
        $members = $stmt->fetchAll();

        $updatedMembers = [];
        foreach ($members as $member) {
            $updatedMembers[] = $this->autoRecalculateStatus($member);
        }

        sendJson(200, $updatedMembers);
    }
}
