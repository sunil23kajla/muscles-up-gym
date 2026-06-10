<?php
// backend-php/api/jwt.php

class JWT {
    public static function encode($payload, $secret) {
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(json_encode($payload)));
        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $secret, true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }

    public static function decode($jwt, $secret) {
        $tokenParts = explode('.', $jwt);
        if (count($tokenParts) != 3) {
            return false;
        }
        $header = base64_decode(str_replace(['-', '_'], ['+', '/'], $tokenParts[0]));
        $payload = base64_decode(str_replace(['-', '_'], ['+', '/'], $tokenParts[1]));
        $signature_provided = $tokenParts[2];

        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $secret, true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

        if ($base64UrlSignature === $signature_provided) {
            $payload_obj = json_decode($payload);
            if (isset($payload_obj->exp) && $payload_obj->exp < time()) {
                return false; // Token expired
            }
            return $payload_obj;
        } else {
            return false;
        }
    }
}

function verifyAuth() {
    $headers = apache_request_headers();
    $token = '';
    if (isset($headers['Authorization'])) {
        $matches = [];
        if (preg_match('/Bearer\s(\S+)/', $headers['Authorization'], $matches)) {
            $token = $matches[1];
        }
    } else if (isset($headers['x-auth-token'])) {
        $token = $headers['x-auth-token'];
    }

    if (!$token) {
        sendJson(401, ["msg" => "No token, authorization denied"]);
    }

    $decoded = JWT::decode($token, JWT_SECRET);
    if (!$decoded) {
        sendJson(401, ["msg" => "Token is not valid"]);
    }

    // Support both old and new payload formats
    if (isset($decoded->user->id)) {
        return ['user' => ['id' => $decoded->user->id, 'role' => 'admin']];
    } else {
        return ['user' => ['id' => $decoded->id, 'role' => isset($decoded->role) ? $decoded->role : 'staff']];
    }
}
