<?php

$errorCode = 1;
$token = null;

require_once '../private/env.php';
require_once '../private/db_config.php';
require_once '../private/ValidationException.php';

$jwtSecretKey = JWT_SECRET_KEY;

if (empty($jwtSecretKey) || strlen($jwtSecretKey) < 32) {
    http_response_code(500);
    echo json_encode([
        'result' => 99,
        'token' => null,
        'message' => 'JWT_SECRET_KEYが設定されていません'
    ]);
    exit;
}

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    try {
        $db = new DB();
    } catch (mysqli_sql_exception $e) {
        throw new ValidationException("DB接続失敗", 90);
    }

    if (!$db->isConnected_db()) {
        throw new ValidationException("DB接続失敗", 90);
    }

    $input = json_decode(file_get_contents('php://input'), true);
    $email = trim($input['emailAddress'] ?? '');
    $password = trim($input['password'] ?? '');

    if (empty($email) || empty($password)) {
        throw new ValidationException("空チェックエラー", 50);
    }

    $sql = "SELECT password FROM Mst_User WHERE EmailAddress = ? AND DeleteFg = 0";
    $result = $db->execute_select($sql, [$email]);

    if ($result === false || count($result) === 0) {
        throw new ValidationException("ユーザー取得失敗", 51);
    }

    $dbPasswordHash = $result[0]['password'];

    if (!password_verify($password, $dbPasswordHash)) {
        throw new ValidationException("パスワード不一致", 52);
    }

    $token = generate_jwt($email, $jwtSecretKey);

} catch (ValidationException $e) {
    $errorCode = $e->getErrorCode();
    $token = null;
} catch (Exception $e) {
    $errorCode = 99;
    $token = null;
} finally {
    if (isset($db)) $db->disconnect_db();
    echo json_encode(['result' => $errorCode, 'token' => $token]);
}

function generate_jwt(string $email, string $secretKey): string
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
    $signature = hash_hmac('sha256', "$base64UrlHeader.$base64UrlPayload", $secretKey, true);
    $base64UrlSignature = base64url_encode($signature);

    return "$base64UrlHeader.$base64UrlPayload.$base64UrlSignature";
}

function base64url_encode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}
