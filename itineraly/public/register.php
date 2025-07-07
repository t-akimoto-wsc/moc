<?php

$errorCode = 1; 

require_once '../private/db_config.php'; 
try {
    // JSONのPOSTデータ取得
    $input = json_decode(file_get_contents('php://input'), true);
    $email = trim($input['EmailAddress'] ?? '');
    $password = trim($input['Password'] ?? '');

    // 空チェック
    if (empty($email) || empty($password)) {
        $errorCode = 50;
        throw new Exception("空チェックエラー");
    }

    // メール形式チェック
    if (!preg_match('/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/', $email)) {
        $errorCode = 51;
        throw new Exception("メール形式エラー");
    }

    // パスワード形式チェック
    if (
        strlen($password) < 8 || strlen($password) > 32 ||
        !preg_match('/[a-z]/', $password) ||
        !preg_match('/[A-Z]/', $password) ||
        !preg_match('/[0-9]/', $password)
    ) {
        $errorCode = 52;
        throw new Exception("パスワード形式エラー");
    }

    // DB接続
    $db = new DB();
    if (!$db->isConnected_db()) {
        $errorCode = 90;
        throw new Exception("DB接続失敗");
    }

    $conn = $db->getConnection(); 
    $safeEmail = mysqli_real_escape_string($conn, $email);

    // 重複チェック
    $selectSql = "SELECT EmailAddress FROM Mst_User WHERE EmailAddress = '$safeEmail' AND DeleteFg = 0";
    $result = $db->execute_select($selectSql);

    if ($result === false) {
        $errorCode = 99;
        throw new Exception("SELECT失敗");
    }
    if (count($result) > 0) {
        $errorCode = 53;
        throw new Exception("既に登録済み");
    }

    // パスワードハッシュしてINSERT
    $hashedPw = password_hash($password, PASSWORD_DEFAULT);
    $insertSql = "
        INSERT INTO Mst_User (EmailAddress, Password, CreateDate, UpdateDate, DeleteFg)
        VALUES ('$safeEmail', '$hashedPw', NOW(), NOW(), 0)
    ";

    if (!$db->execute_query($insertSql)) {
        $errorCode = 99;
        throw new Exception("INSERT失敗");
    }

    // 成功のまま終了
} catch (Exception $e) {
    error_log('処理エラー: ' . $e->getMessage());
} finally {
    if (isset($db)) $db->disconnect_db();
    echo json_encode(['result' => $errorCode]);
}
