<?php
// backend-php/api/database.php

class CustomPDO extends PDO {
    private $isDemo = false;

    public function setIsDemo($demo) {
        $this->isDemo = $demo;
    }

    public function prepare($query, $options = []) {
        if ($this->isDemo) {
            $query = preg_replace('/\b(users|members|payments|attendances|workouts|inquiries|website_settings)\b/', 'demo_$1', $query);
        }
        return parent::prepare($query, $options);
    }

    public function query($query, $fetchMode = null, ...$fetchModeArgs) {
        if ($this->isDemo) {
            $query = preg_replace('/\b(users|members|payments|attendances|workouts|inquiries|website_settings)\b/', 'demo_$1', $query);
        }
        if ($fetchMode !== null) {
            return parent::query($query, $fetchMode, ...$fetchModeArgs);
        }
        return parent::query($query);
    }
    
    public function exec($statement) {
        if ($this->isDemo) {
            $statement = preg_replace('/\b(users|members|payments|attendances|workouts|inquiries|website_settings)\b/', 'demo_$1', $statement);
        }
        return parent::exec($statement);
    }
}

class Database {
    private static $connection = null;

    public static function getConnection($isDemo = null) {
        if (self::$connection === null) {
            try {
                // Ensure config.php constants are available
                require_once __DIR__ . '/config.php';
                self::$connection = new CustomPDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
                self::$connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                self::$connection->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            } catch (PDOException $e) {
                die(json_encode(["message" => "Database connection failed", "error" => $e->getMessage()]));
            }
        }
        
        if ($isDemo !== null) {
            self::$connection->setIsDemo($isDemo);
        }
        
        return self::$connection;
    }
}
