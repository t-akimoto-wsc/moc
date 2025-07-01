<?php

class DB {
    private $host = 'www1532.sakura.ne.jp';
    private $dbname = 'worth-sc_Itinerary';
    private $username = 'worth-sc_itinerary';
    private $password = 'itinerary0214';
    private $conn;

    // コンストラクタ
    public function __construct() {
        try {
            $this->conn = new mysqli($this->host, $this->username, $this->password, $this->dbname);
            if ($this->conn->connect_error) {
                throw new Exception('DB接続エラー: ' . $this->conn->connect_error);
            }
        } catch (Exception $e) {
            error_log($e->getMessage());
            $this->conn = null;
        }
    }

    // DB接続判定
    public function isConnected_db(): bool {
        return $this->conn !== null;
    }

    // DB切断
    public function disconnect_db(): bool {
        try {
            if ($this->conn !== null) {
                $result = $this->conn->close();
                return $result;
            }
        } catch (Exception $e) {
            error_log('DB切断エラー: ' . $e->getMessage());
        }
        return false;
    }

    // SQL実行（INSERT/UPDATE/DELETE等）
    public function execute_query(string $sql): bool {
        try {
            $result = $this->conn->query($sql);
            return $result === true;
        } catch (Exception $e) {
            error_log('SQL実行エラー: ' . $e->getMessage());
            return false;
        }
    }

    // SQL実行（SELECT用）
    public function execute_select(string $sql) {
        try {
            $result = $this->conn->query($sql);
            if ($result !== false) {
                return $result->fetch_all(MYSQLI_ASSOC);
            }
        } catch (Exception $e) {
            error_log('SELECT文エラー: ' . $e->getMessage());
        }
        return false;
    }
}
?>
