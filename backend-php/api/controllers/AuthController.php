<?php
// backend-php/api/controllers/AuthController.php
require_once 'database.php';
require_once 'jwt.php';

class AuthController {
    public function handleRequest($action, $input) {
        $method = $_SERVER['REQUEST_METHOD'];

        if ($method === 'POST' && $action === 'register') {
            $this->register($input);
        } else if ($method === 'POST' && $action === 'login') {
            $this->login($input);
        } else if ($method === 'GET' && $action === 'pending-requests') {
            $req = verifyAuth();
            $this->getPendingRequests($req);
        } else if ($method === 'POST' && $action === 'update-status') {
            $req = verifyAuth();
            $this->updateRequestStatus($input, $req);
        } else if ($method === 'POST' && $action === 'change-password') {
            $req = verifyAuth();
            $this->changePassword($input, $req);
        } else if ($method === 'PUT' && $action === 'update-profile') {
            $req = verifyAuth();
            $this->updateProfile($input, $req);
        } else if ($method === 'GET' && $action === 'staff') {
            $req = verifyAuth();
            $this->getStaffList($req);
        } else if ($method === 'DELETE' && $action === 'staff') { // We need to extract the ID from the route. Wait, the router currently passes action as routeParts[1]. So if route is auth/staff/id, action is staff. We should check $_SERVER['REQUEST_URI'] or routeParts.
            // But handleRequest currently only takes $action and $input. I need to modify handleRequest to take $routeParts.
            sendJson(405, ["message" => "Method not mapped correctly. Adjust router."]);
        } else if ($method === 'POST' && $action === 'admin-reset-password') {
            $req = verifyAuth();
            $this->adminResetPassword($input, $req);
        } else {
            sendJson(404, ["message" => "Auth endpoint not found"]);
        }
    }

    public function handleRequestWithParts($routeParts, $input) {
        $method = $_SERVER['REQUEST_METHOD'];
        $action = isset($routeParts[1]) ? $routeParts[1] : '';

        if ($method === 'POST' && $action === 'register') {
            $this->register($input);
        } else if ($method === 'POST' && $action === 'login') {
            $this->login($input);
        } else if ($method === 'GET' && $action === 'pending-requests') {
            $req = verifyAuth();
            if ($req['user']['role'] !== 'admin') sendJson(403, ["message" => "Admin only"]);
            $this->getPendingRequests($req);
        } else if ($method === 'POST' && $action === 'update-status') {
            $req = verifyAuth();
            if ($req['user']['role'] !== 'admin') sendJson(403, ["message" => "Admin only"]);
            $this->updateRequestStatus($input, $req);
        } else if ($method === 'POST' && $action === 'change-password') {
            $req = verifyAuth();
            $this->changePassword($input, $req);
        } else if ($method === 'PUT' && $action === 'update-profile') {
            $req = verifyAuth();
            $this->updateProfile($input, $req);
        } else if ($method === 'GET' && $action === 'staff') {
            $req = verifyAuth();
            if ($req['user']['role'] !== 'admin') sendJson(403, ["message" => "Admin only"]);
            $this->getStaffList($req);
        } else if ($method === 'DELETE' && $action === 'staff' && isset($routeParts[2])) {
            $req = verifyAuth();
            if ($req['user']['role'] !== 'admin') sendJson(403, ["message" => "Admin only"]);
            $this->deleteStaff($routeParts[2], $req);
        } else if ($method === 'POST' && $action === 'admin-reset-password') {
            $req = verifyAuth();
            if ($req['user']['role'] !== 'admin') sendJson(403, ["message" => "Admin only"]);
            $this->adminResetPassword($input, $req);
        } else {
            sendJson(404, ["message" => "Auth endpoint not found"]);
        }
    }

    private function generateUuid() {
        return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x', mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0x0fff) | 0x4000, mt_rand(0, 0x3fff) | 0x8000, mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff));
    }

    private function register($input) {
        $name = isset($input['name']) ? $input['name'] : null;
        $email = isset($input['email']) ? $input['email'] : null;
        $password = isset($input['password']) ? $input['password'] : null;
        $role = isset($input['role']) ? $input['role'] : null;

        if (!$name || !$email || !$password) {
            sendJson(400, ["message" => "Please enter all fields"]);
        }

        $db = Database::getConnection();
        
        $stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->execute([$email]);
        if ($stmt->fetch()) {
            sendJson(400, ["message" => "Email already registered."]);
        }

        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
        
        $countStmt = $db->query("SELECT COUNT(*) FROM users");
        $userCount = $countStmt->fetchColumn();
        
        $isFirstUser = ($userCount == 0);
        $finalRole = $isFirstUser ? 'admin' : ($role ? $role : 'staff');
        $finalStatus = $isFirstUser ? 'approved' : 'pending';
        $userId = $this->generateUuid();

        $stmt = $db->prepare("INSERT INTO users (id, name, email, password, role, status) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([$userId, $name, $email, $hashedPassword, $finalRole, $finalStatus]);
        
        sendJson(201, [
            "message" => $isFirstUser ? "Admin account created and approved automatically." : "Registration successful. Waiting for Admin approval.",
            "user" => [
                "id" => $userId, 
                "name" => $name, 
                "email" => $email, 
                "role" => $finalRole,
                "status" => $finalStatus
            ]
        ]);
    }

    private function login($input) {
        $email = isset($input['email']) ? $input['email'] : null;
        $password = isset($input['password']) ? $input['password'] : null;

        if (!$email || !$password) {
            sendJson(400, ["message" => "Please enter all fields"]);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if (!$user) {
            sendJson(400, ["message" => "Invalid credentials."]);
        }

        if (!password_verify($password, $user['password'])) {
            sendJson(400, ["message" => "Invalid credentials."]);
        }

        if ($user['status'] === 'pending') {
            sendJson(403, ["message" => "Your account is pending admin approval.", "status" => "pending"]);
        }

        if ($user['status'] === 'rejected') {
            sendJson(403, ["message" => "Your request has been rejected by Admin.", "status" => "rejected"]);
        }

        $pSignature = substr($user['password'], 0, 15);
        $payload = [
            'id' => $user['id'],
            'email' => $user['email'],
            'role' => $user['role'],
            'pSignature' => $pSignature,
            'exp' => time() + (30 * 24 * 60 * 60) // 30 days
        ];
        // The original API nested under `user`, wait, no, the payload was `{ id, role, pSignature }`. 
        // Our PHP JWT expects `user` array if we used that. Let's stick to Node's format.
        $token = JWT::encode($payload, JWT_SECRET);

        sendJson(200, [
            "token" => $token,
            "user" => [
                "id" => $user['id'],
                "name" => $user['name'],
                "email" => $user['email'],
                "role" => $user['role'],
                "status" => $user['status']
            ]
        ]);
    }

    private function getPendingRequests($req) {
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT id, name, email, role, status, createdAt, updatedAt FROM users WHERE status = 'pending'");
        $stmt->execute();
        sendJson(200, $stmt->fetchAll());
    }

    private function updateRequestStatus($input, $req) {
        $userId = isset($input['userId']) ? $input['userId'] : null;
        $status = isset($input['status']) ? $input['status'] : null;

        if (!in_array($status, ['approved', 'rejected'])) {
            sendJson(400, ["message" => "Invalid status. Must be approved or rejected."]);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        if (!$user) {
            sendJson(404, ["message" => "User request not found."]);
        }

        $stmt = $db->prepare("UPDATE users SET status = ? WHERE id = ?");
        $stmt->execute([$status, $userId]);

        sendJson(200, [
            "message" => "User status updated to $status.",
            "userId" => $userId,
            "status" => $status
        ]);
    }

    private function changePassword($input, $req) {
        $oldPassword = isset($input['oldPassword']) ? $input['oldPassword'] : null;
        $newPassword = isset($input['newPassword']) ? $input['newPassword'] : null;

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$req['id']]); // Note: payload uses id now
        $user = $stmt->fetch();

        if (!$user) {
            sendJson(404, ["message" => "User not found."]);
        }

        if (!password_verify($oldPassword, $user['password'])) {
            sendJson(400, ["message" => "Incorrect current password."]);
        }

        $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
        $stmt = $db->prepare("UPDATE users SET password = ? WHERE id = ?");
        $stmt->execute([$hashedPassword, $user['id']]);

        sendJson(200, ["message" => "Password changed successfully."]);
    }

    private function updateProfile($input, $req) {
        $name = isset($input['name']) ? $input['name'] : null;
        $email = isset($input['email']) ? $input['email'] : null;

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$req['id']]);
        $user = $stmt->fetch();

        if (!$user) {
            sendJson(404, ["message" => "User not found."]);
        }

        if ($email && $email !== $user['email']) {
            $stmtCheck = $db->prepare("SELECT id FROM users WHERE email = ?");
            $stmtCheck->execute([$email]);
            if ($stmtCheck->fetch()) {
                sendJson(400, ["message" => "Email is already in use by another account."]);
            }
            $user['email'] = $email;
        }

        if ($name) {
            $user['name'] = $name;
        }

        $stmt = $db->prepare("UPDATE users SET name = ?, email = ? WHERE id = ?");
        $stmt->execute([$user['name'], $user['email'], $user['id']]);

        sendJson(200, [
            "message" => "Profile updated successfully.",
            "user" => [
                "id" => $user['id'],
                "name" => $user['name'],
                "email" => $user['email'],
                "role" => $user['role'],
                "status" => $user['status']
            ]
        ]);
    }

    private function getStaffList($req) {
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT id, name, email, role, status, createdAt, updatedAt FROM users WHERE role = 'staff' AND status = 'approved'");
        $stmt->execute();
        sendJson(200, $stmt->fetchAll());
    }

    private function deleteStaff($id, $req) {
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$id]);
        $staff = $stmt->fetch();

        if (!$staff) {
            sendJson(404, ["message" => "Staff member not found."]);
        }

        if ($staff['role'] === 'admin') {
            sendJson(403, ["message" => "Administrators cannot be deleted."]);
        }

        $stmt = $db->prepare("DELETE FROM users WHERE id = ?");
        $stmt->execute([$id]);

        sendJson(200, ["message" => "Staff member deleted from database successfully."]);
    }

    private function adminResetPassword($input, $req) {
        $targetId = isset($input['targetId']) ? $input['targetId'] : null;
        $newPassword = isset($input['newPassword']) ? $input['newPassword'] : null;

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$targetId]);
        $user = $stmt->fetch();

        if (!$user) {
            sendJson(404, ["message" => "User not found."]);
        }

        if ($user['role'] === 'admin' && $user['id'] !== $req['id']) {
            sendJson(403, ["message" => "You cannot reset password for other Administrators."]);
        }

        $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
        $stmt = $db->prepare("UPDATE users SET password = ? WHERE id = ?");
        $stmt->execute([$hashedPassword, $user['id']]);

        sendJson(200, ["message" => "Password for {$user['name']} has been reset successfully."]);
    }
}
