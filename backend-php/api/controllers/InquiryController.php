<?php
// backend-php/api/controllers/InquiryController.php
require_once 'database.php';
require_once 'jwt.php';

class InquiryController {
    public function handleRequest($action, $routeParts, $input) {
        $method = $_SERVER['REQUEST_METHOD'];

        if ($method === 'POST' && $action === '') {
            $this->createInquiry($input);
        } else if ($method === 'GET' && $action === '') {
            $req = verifyAuth();
            $this->getAllInquiries($req);
        } else if ($method === 'PUT' && isset($routeParts[1])) {
            $req = verifyAuth();
            $this->updateInquiryStatus($routeParts[1], $input, $req);
        } else if ($method === 'DELETE' && isset($routeParts[1])) {
            $req = verifyAuth();
            if ($req['user']['role'] !== 'admin') sendJson(403, ["message" => "Admin only"]);
            $this->deleteInquiry($routeParts[1], $req);
        } else {
            sendJson(405, ["message" => "Method not allowed"]);
        }
    }

    private function generateUuid() {
        return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x', mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0x0fff) | 0x4000, mt_rand(0, 0x3fff) | 0x8000, mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff));
    }

    private function createInquiry($input) {
        $name = isset($input['name']) ? $input['name'] : null;
        $phone = isset($input['phone']) ? $input['phone'] : null;
        $packageName = isset($input['packageName']) ? $input['packageName'] : null;
        $message = isset($input['message']) ? $input['message'] : null;

        if (!$name || !$phone || !$packageName) {
            sendJson(400, ["message" => "Name, Phone, and Package choice are required."]);
        }

        $cleanPhone = preg_replace('/\D/', '', $phone);
        if (strlen($cleanPhone) !== 10) {
            sendJson(400, ["message" => "Please enter a valid 10-digit phone number."]);
        }

        $id = $this->generateUuid();
        $db = Database::getConnection();

        $stmt = $db->prepare("INSERT INTO inquiries (id, name, phone, packageName, message, status) VALUES (?, ?, ?, ?, ?, 'pending')");
        try {
            $stmt->execute([$id, trim($name), $cleanPhone, $packageName, $message ? trim($message) : null]);
            
            $fetchStmt = $db->prepare("SELECT * FROM inquiries WHERE id = ?");
            $fetchStmt->execute([$id]);

            sendJson(201, [
                "message" => "Inquiry submitted successfully!",
                "inquiry" => $fetchStmt->fetch()
            ]);
        } catch (PDOException $e) {
            sendJson(500, ["message" => "Failed to submit inquiry.", "error" => $e->getMessage()]);
        }
    }

    private function getAllInquiries($req) {
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM inquiries ORDER BY createdAt DESC");
        $stmt->execute();
        sendJson(200, $stmt->fetchAll());
    }

    private function updateInquiryStatus($id, $input, $req) {
        $status = isset($input['status']) ? $input['status'] : null;
        $validStatuses = ['pending', 'contacted', 'joined'];

        if (!in_array($status, $validStatuses)) {
            sendJson(400, ["message" => "Invalid inquiry status."]);
        }

        $db = Database::getConnection();
        
        $stmt = $db->prepare("SELECT * FROM inquiries WHERE id = ?");
        $stmt->execute([$id]);
        $inquiry = $stmt->fetch();

        if (!$inquiry) {
            sendJson(404, ["message" => "Inquiry not found."]);
        }

        $updateStmt = $db->prepare("UPDATE inquiries SET status = ? WHERE id = ?");
        $updateStmt->execute([$status, $id]);

        $inquiry['status'] = $status;

        sendJson(200, [
            "message" => "Inquiry status updated successfully.",
            "inquiry" => $inquiry
        ]);
    }

    private function deleteInquiry($id, $req) {
        $db = Database::getConnection();
        
        $stmt = $db->prepare("SELECT id FROM inquiries WHERE id = ?");
        $stmt->execute([$id]);
        if (!$stmt->fetch()) {
            sendJson(404, ["message" => "Inquiry not found."]);
        }

        $delStmt = $db->prepare("DELETE FROM inquiries WHERE id = ?");
        $delStmt->execute([$id]);

        sendJson(200, ["message" => "Inquiry deleted successfully."]);
    }
}
