<?php

$errorCode = 1;

define('JWT_SECRET_KEY', 'a-string-secret-at-least-256-bits-long');

require_once '../private/db_config.php';
try 
{
    $db = new DB();

    $input = json_decode(file_get_contents('php://input'), true);
    $email = $input['emailAddress'] ?? '';
    $password = $input['password'] ?? '';

    if (empty($email) || empty($password)) {
        $errorCode = 50;
        throw new Exception("空チェックエラー");
    }

    if (!$db->isConnected_db()) {
        $errorCode = 90;
        throw new Exception("DB接続失敗");
    }

    $sql = "SELECT password FROM Mst_User WHERE EmailAddress = ? AND DeleteFg = false";
    $result = $db->execute_select($sql, [$email]);

    if ($result === false) {
        $errorCode = 51;
        throw new Exception("ユーザー取得失敗");
    }

    $dbPasswordHash = $result[0]['password'];

    if (!password_verify($password, $dbPasswordHash)) {
        $errorCode = 52;
        throw new Exception("パスワード不一致");
    }

    $token = generate_jwt($email);

} catch (Exception $e) {
    error_log('認証処理エラー: ' . $e->getMessage());
    $token = null;
} finally {
    if (isset($db)) $db->disconnect_db();
    echo json_encode(['result' => $errorCode, 'token' => $token]);
}

function generate_jwt(string $email): string
{
    $header = json_encode(['alg' => 'HS256', 'typ' => 'JWT']);
    $iat = time();
    $exp = $iat + 3600;
    $payload = json_encode([
        'emailAddress' => $email,
        'iat' => $iat,
        'exp' => $exp
    ]);

    $base64UrlHeader = base64url_encode($header);
    $base64UrlPayload = base64url_encode($payload);
    $signature = hash_hmac('sha256', "$base64UrlHeader.$base64UrlPayload", JWT_SECRET_KEY, true);
    $base64UrlSignature = base64url_encode($signature);

    return "$base64UrlHeader.$base64UrlPayload.$base64UrlSignature";
}

function base64url_encode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}
