<?php
class DB {
    private $host = 'localhost';
    private $dbname = 'worth-sc_Itinerary';
    private $username = 'mysql_user';
    private $password = 'Passw0rd!';
    private $conn;

    public function __construct() {
        $this->conn = new mysqli($this->host, $this->username, $this->password, $this->dbname);
        if ($this->conn->connect_error) {
            $this->conn = null;
        } else {
            $this->conn->set_charset('utf8mb4');
        }
    }

    public function isConnected_db(): bool {
        return $this->conn !== null;
    }

    public function getConnection() {
        return $this->conn;
    }

    public function disconnect_db(): bool {
        if ($this->conn !== null) {
            return $this->conn->close();
        }
        return false;
    }

    public function execute_select(string $sql, array $params = []) {
        if ($this->conn === null) return false;

        $stmt = $this->conn->prepare($sql);
        if ($stmt === false) {
            return false;
        }

        if (!empty($params)) {
            $types = str_repeat('s', count($params));
            $stmt->bind_param($types, ...$params);
        }

        if (!$stmt->execute()) {
            $stmt->close();
            return false;
        }

        $result = $stmt->get_result();
        if ($result === false) {
            $stmt->close();
            return false;
        }

        $rows = $result->fetch_all(MYSQLI_ASSOC);
        $stmt->close();

        return $rows;
    }

    public function execute_query(string $sql, array $params = []): bool {
        if ($this->conn === null) return false;

        $stmt = $this->conn->prepare($sql);
        if ($stmt === false) {
            return false;
        }

        if (!empty($params)) {
            $types = str_repeat('s', count($params));
            $stmt->bind_param($types, ...$params);
        }

        $res = $stmt->execute();
        $stmt->close();
        return $res;
    }
}
?>
