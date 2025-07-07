<?php
header("Content-Type: application/json");

define('JWT_SECRET_KEY', 'a-string-secret-at-least-256-bits-long');

$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (!$authHeader || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    http_response_code(401);
    echo json_encode(['result' => 401, 'message' => 'Unauthorized: No token provided']);
    exit;
}

$jwt = $matches[1];

if (!verify_jwt($jwt)) {
    http_response_code(401);
    echo json_encode(['result' => 401, 'message' => 'Unauthorized: Invalid token']);
    exit;
}

$payload = get_jwt_payload($jwt);
echo json_encode(['result' => 1, 'message' => 'Token valid', 'emailAddress' => $payload['emailAddress'] ?? null]);
exit;

function verify_jwt(string $jwt): bool {
    $parts = explode('.', $jwt);
    if (count($parts) !== 3) return false;

    [$base64UrlHeader, $base64UrlPayload, $base64UrlSignature] = $parts;
    $data = $base64UrlHeader . '.' . $base64UrlPayload;
    // 署名はバイナリ出力で比較
    $expectedSignature = hash_hmac('sha256', $data, JWT_SECRET_KEY, true);
    $signature = base64url_decode($base64UrlSignature);

    if (!hash_equals($expectedSignature, $signature)) {
        return false;
    }

    $payload = json_decode(base64url_decode($base64UrlPayload), true);
    if (!$payload) return false;

    $now = time();
    if (isset($payload['exp']) && $payload['exp'] < $now) return false;
    if (isset($payload['iat']) && $payload['iat'] > $now) return false;

    return true;
}

function get_jwt_payload(string $jwt): ?array {
    $parts = explode('.', $jwt);
    if (count($parts) !== 3) return null;

    return json_decode(base64url_decode($parts[1]), true);
}

function base64url_decode(string $data): string {
    $b64 = strtr($data, '-_', '+/');
    $pad = strlen($b64) % 4;
    if ($pad) $b64 .= str_repeat('=', 4 - $pad);
    return base64_decode($b64);
}
