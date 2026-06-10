<?php
// backend-php/api/controllers/AttendanceController.php
require_once 'database.php';
require_once 'jwt.php';

class AttendanceController {
    public function handleRequest($action, $routeParts, $input) {
        $method = $_SERVER['REQUEST_METHOD'];

        if ($method === 'POST' && $action === 'mark') {
            $req = verifyAuth();
            $this->markAttendance($input, $req);
        } else if ($method === 'GET' && $action === 'daily') {
            $req = verifyAuth();
            $this->getDailyAttendance($req);
        } else if ($method === 'POST' && $action === 'workout') {
            $req = verifyAuth();
            $this->assignWorkoutPlan($input, $req);
        } else if ($method === 'GET' && $action === 'workout' && isset($routeParts[2])) {
            $req = verifyAuth();
            $this->getWorkoutPlan($routeParts[2], $req);
        } else {
            sendJson(405, ["message" => "Method not allowed"]);
        }
    }

    private function markAttendance($input, $req) {
        $memberId = isset($input['memberId']) ? $input['memberId'] : null;
        $date = isset($input['date']) ? $input['date'] : null;
        $status = isset($input['status']) ? $input['status'] : null;

        if (!$memberId || !$date || !$status) {
            sendJson(400, ["message" => "MemberId, date, and status are required."]);
        }

        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT id FROM members WHERE id = ?");
        $stmt->execute([$memberId]);
        if (!$stmt->fetch()) {
            sendJson(404, ["message" => "Member not found."]);
        }

        $stmtCheck = $db->prepare("SELECT id FROM attendances WHERE memberId = ? AND date = ?");
        $stmtCheck->execute([$memberId, $date]);
        $existing = $stmtCheck->fetch();

        if ($existing) {
            $stmtUpdate = $db->prepare("UPDATE attendances SET status = ? WHERE id = ?");
            $stmtUpdate->execute([$status, $existing['id']]);
            $attendanceId = $existing['id'];
        } else {
            $stmtInsert = $db->prepare("INSERT INTO attendances (memberId, date, status) VALUES (?, ?, ?)");
            $stmtInsert->execute([$memberId, $date, $status]);
            $attendanceId = $db->lastInsertId();
        }

        $fetchStmt = $db->prepare("SELECT * FROM attendances WHERE id = ?");
        $fetchStmt->execute([$attendanceId]);

        sendJson(200, [
            "message" => "Attendance marked successfully.",
            "attendance" => $fetchStmt->fetch()
        ]);
    }

    private function getDailyAttendance($req) {
        $date = isset($_GET['date']) ? $_GET['date'] : null;

        if (!$date) {
            sendJson(400, ["message" => "Date query parameter is required (YYYY-MM-DD)."]);
        }

        $db = Database::getConnection();
        
        $stmt = $db->prepare("SELECT id, name, phone, photo FROM members WHERE status = 'active'");
        $stmt->execute();
        $members = $stmt->fetchAll();

        $report = [];
        foreach ($members as $member) {
            $attStmt = $db->prepare("SELECT status FROM attendances WHERE memberId = ? AND date = ?");
            $attStmt->execute([$member['id'], $date]);
            $attendance = $attStmt->fetch();

            $report[] = [
                'id' => $member['id'],
                'name' => $member['name'],
                'phone' => $member['phone'],
                'photo' => $member['photo'],
                'status' => $attendance ? $attendance['status'] : 'unmarked'
            ];
        }

        sendJson(200, $report);
    }

    private function assignWorkoutPlan($input, $req) {
        $memberId = isset($input['memberId']) ? $input['memberId'] : null;
        $planName = isset($input['planName']) ? $input['planName'] : null;
        $details = isset($input['details']) ? $input['details'] : null;

        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT id FROM members WHERE id = ?");
        $stmt->execute([$memberId]);
        if (!$stmt->fetch()) {
            sendJson(404, ["message" => "Member not found."]);
        }

        $stmtCheck = $db->prepare("SELECT * FROM workouts WHERE memberId = ?");
        $stmtCheck->execute([$memberId]);
        $workout = $stmtCheck->fetch();

        if ($workout) {
            $pName = $planName ? $planName : $workout['planName'];
            $pDetails = $details !== null ? $details : $workout['details'];

            $stmtUpdate = $db->prepare("UPDATE workouts SET planName = ?, details = ? WHERE id = ?");
            $stmtUpdate->execute([$pName, $pDetails, $workout['id']]);
            $workoutId = $workout['id'];
        } else {
            $stmtInsert = $db->prepare("INSERT INTO workouts (memberId, planName, details) VALUES (?, ?, ?)");
            $stmtInsert->execute([$memberId, $planName, $details]);
            $workoutId = $db->lastInsertId();
        }

        $fetchStmt = $db->prepare("SELECT * FROM workouts WHERE id = ?");
        $fetchStmt->execute([$workoutId]);

        sendJson(200, [
            "message" => "Workout plan updated successfully.",
            "workout" => $fetchStmt->fetch()
        ]);
    }

    private function getWorkoutPlan($memberId, $req) {
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM workouts WHERE memberId = ?");
        $stmt->execute([$memberId]);
        $workout = $stmt->fetch();

        if (!$workout) {
            sendJson(200, null);
        } else {
            sendJson(200, $workout);
        }
    }
}
