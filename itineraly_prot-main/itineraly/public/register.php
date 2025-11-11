<?php

require_once '../private/db_config.php';
require_once '../private/validation_exception.php';

$errorCode = 1;

try {
    $input = json_decode(file_get_contents('php://input'), true);
    $email = trim($input['emailAddress'] ?? '');
    $password = trim($input['password'] ?? '');

    if (empty($email) || empty($password)) {
        throw new ValidationException("空チェックエラー", 50);
    }

    if (!preg_match('/^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/', $email)) {
        throw new ValidationException("メール形式エラー", 51);
    }

    if (
        strlen($password) < 8 || strlen($password) > 32 ||
        !preg_match('/[a-z]/', $password) ||
        !preg_match('/[A-Z]/', $password) ||
        !preg_match('/[0-9]/', $password) ||
        !preg_match('/^[a-zA-Z0-9~!@#\$%\^&\*\(\)_\+\-=\{\}\[\]\|:;\"<>,\.\?\/]+$/', $password)
    ) {
        throw new ValidationException("パスワード形式エラー", 52);
    }

    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
    try {
        $db = new DB();
    } catch (mysqli_sql_exception $e) {
        throw new ValidationException("DB接続失敗", 90);
    }

    if (!$db->isConnected_db()) {
        throw new ValidationException("DB接続失敗", 90);
    }

    $conn = $db->getConnection();

    $stmt = $conn->prepare("SELECT EmailAddress FROM Mst_User WHERE EmailAddress = ? AND DeleteFg = 0");
    if (!$stmt) {
        throw new ValidationException("SELECTプリペア失敗: " . $conn->error, 99);
    }

    $stmt->bind_param("s", $email);
    if (!$stmt->execute()) {
        throw new ValidationException("SELECT実行失敗: " . $stmt->error, 99);
    }

    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        throw new ValidationException("既に登録済み", 53);
    }
    $stmt->close();

    $hashedPw = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $conn->prepare("
        INSERT INTO Mst_User (EmailAddress, Password, CreateDate, UpdateDate, DeleteFg)
        VALUES (?, ?, NOW(), NOW(), 0)
    ");
    if (!$stmt) {
        throw new ValidationException("INSERTプリペア失敗: " . $conn->error, 99);
    }

    $stmt->bind_param("ss", $email, $hashedPw);
    if (!$stmt->execute()) {
        throw new ValidationException("INSERT実行失敗: " . $stmt->error, 99);
    }
    $stmt->close();

} catch (ValidationException $e) {
    $errorCode = $e->getErrorCode();
} catch (Exception $e) {
    $errorCode = 99;
} finally {
    if (isset($db)) $db->disconnect_db();
    echo json_encode(['result' => $errorCode]);
}
