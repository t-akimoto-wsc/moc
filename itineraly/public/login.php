<?php

$errorCode = 1; 

define('JWT_SECRET_KEY', 'a-string-secret-at-least-256-bits-long'); 

require_once '../private/db_config.php';
$db = new DB();

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);
$email = $data['emailAddress'] ?? '';
$password = $data['password'] ?? '';

if (empty($email) || empty($password)) {
    echo json_encode(['result' => 50, 'token' => null]);
    exit;
}

if (!$db->isConnected_db()) {
    echo json_encode(['result' => 90, 'token' => null]);
    exit;
}

$sql = "SELECT password FROM Mst_User WHERE EmailAddress = ? AND DeleteFg = false";
$result = $db->execute_select($sql, [$email]);

if (!$result) {
    echo json_encode(['result' => 51, 'token' => null]);
    exit;
}

$dbPasswordHash = $result[0]['password'];

if (!password_verify($password, $dbPasswordHash)) {
    echo json_encode(['result' => 52, 'token' => null]);
    exit;
}

$db->disconnect_db();

$token = generate_jwt($email);
echo json_encode(['result' => 1, 'token' => $token]);
exit;

function generate_jwt(string $email): string {
    $header = json_encode(['alg' => 'HS256', 'typ' => 'JWT']);
    $iat = time();
    $exp = $iat + 3600;
    $payload = json_encode([
        'emailAddress' => $email,
        'iat' => $iat,
        'exp' => $exp,
    ]);

    $base64UrlHeader = base64url_encode($header);
    $base64UrlPayload = base64url_encode($payload);
    $signature = hash_hmac('sha256', "$base64UrlHeader.$base64UrlPayload", JWT_SECRET_KEY, true);
    $base64UrlSignature = base64url_encode($signature);

    return "$base64UrlHeader.$base64UrlPayload.$base64UrlSignature";
}

function base64url_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}
