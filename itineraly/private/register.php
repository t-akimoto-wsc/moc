<?php
require_once '../private/db_config.php'; // DBクラスが含まれているファイル

$errorCode = 1; // 初期値

try {
    // リクエストのJSONデータを取得
    $input = json_decode(file_get_contents('php://input'), true);
    $email = trim($input['EmailAddress'] ?? '');
    $Password = trim($input['Password'] ?? '');

    // バリデーション：空チェック
    if (empty($email) || empty($Password)) {
        $errorCode = 50;
    }

    // メールアドレス形式チェック
    if (!preg_match('/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/', $email)) {
        $errorCode = 51;
    }

    // パスワード形式チェック
    if (
        strlen($Password) < 8 || strlen($Password) > 32 ||
        !preg_match('/[a-z]/', $Password) ||
        !preg_match('/[A-Z]/', $Password) ||
        !preg_match('/[0-9]/', $Password)
    ) {
        $errorCode = 52;
    }

    // DB接続
    $db = new DB();
    if (!$db->isConnected_db()) {
        $errorCode = 90;
    }

    // メールアドレス重複チェック
    $safeEmail = mysqli_real_escape_string($db->conn, $email);
    $selectSql = "SELECT EmailAddress FROM Mst_User WHERE EmailAddress = '$safeEmail' AND DeleteFg = 0";
    $result = $db->execute_select($selectSql);

    if ($result === false) {
        $errorCode = 99;
    }
    if (count($result) > 0) {
        $errorCode = 53;
    }

    // パスワードハッシュ化してINSERT
	$hashedPw = password_hash($Password, PASSWORD_DEFAULT);
    $insertSql = "
        INSERT INTO Mst_User (EmailAddress, Password, CreateDate, UpdateDate, DeleteFg)
        VALUES ('$safeEmail', '$hashedPw', NOW(), NOW(), 0)
    ";

    if (!$db->execute_query($insertSql)) {
        $errorCode = 99;
    }

    $errorCode = 1; // 成功

} catch (Exception $e) {
    error_log('処理エラー: ' . $e->getMessage());
} finally {
    if (isset($db)) $db->disconnect_db();
    echo json_encode(['result' => $errorCode]);
}
