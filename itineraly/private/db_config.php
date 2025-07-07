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
            error_log('DB接続エラー: ' . $this->conn->connect_error);
            $this->conn = null;
        } else {
            $this->conn->set_charset('utf8mb4');
        }
    }

    public function isConnected_db(): bool {
        return $this->conn !== null;
    }

    // ★ 追加メソッド：コネクションを外部へ渡す
    public function getConnection() {
        return $this->conn;
    }

    public function disconnect_db(): bool {
        if ($this->conn !== null) {
            return $this->conn->close();
        }
        return false;
    }

    /**
     * プレースホルダー対応のSELECTクエリ実行
     *
     * @param string $sql SQL文（?プレースホルダー使用）
     * @param array $params バインドする値の配列
     * @return array|false 結果の連想配列 or false
     */
    public function execute_select(string $sql, array $params = []) {
        if ($this->conn === null) return false;

        $stmt = $this->conn->prepare($sql);
        if ($stmt === false) {
            error_log('ステートメント準備失敗: ' . $this->conn->error);
            return false;
        }

        if (!empty($params)) {
            $types = str_repeat('s', count($params));
            $stmt->bind_param($types, ...$params);
        }

        if (!$stmt->execute()) {
            error_log('クエリ実行失敗: ' . $stmt->error);
            $stmt->close();
            return false;
        }

        $result = $stmt->get_result();
        if ($result === false) {
            error_log('結果取得失敗: ' . $stmt->error);
            $stmt->close();
            return false;
        }

        $rows = $result->fetch_all(MYSQLI_ASSOC);
        $stmt->close();

        return $rows;
    }

    /**
     * プレースホルダー対応のINSERT/UPDATE/DELETEクエリ実行
     *
     * @param string $sql SQL文（?プレースホルダー使用）
     * @param array $params バインドする値の配列
     * @return bool 成功:true 失敗:false
     */
    public function execute_query(string $sql, array $params = []): bool {
        if ($this->conn === null) return false;

        $stmt = $this->conn->prepare($sql);
        if ($stmt === false) {
            error_log('ステートメント準備失敗: ' . $this->conn->error);
            return false;
        }

        if (!empty($params)) {
            $types = str_repeat('s', count($params));
            $stmt->bind_param($types, ...$params);
        }

        $res = $stmt->execute();
        if (!$res) {
            error_log('クエリ実行失敗: ' . $stmt->error);
        }

        $stmt->close();
        return $res;
    }
}
?>
