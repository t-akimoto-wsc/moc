<?php
header("Content-Type: application/json");

//初期設定
$errorCode = 1;
$token = null;

//リクエスト受信・デコード
$raw = file_get_contents("php://input");
$data = json_decode($raw, true);
$email = $data['emailAddress'] ?? '';
$password = $data['password'] ?? '';

//入力チェック
if (empty($email) || empty($password)) {
    echo json_encode(['result' => 50, 'token' => null]);
    exit;
}

//DB接続
require_once __DIR__ . '/../db_config.php';
$db = new DB();
if (!$db->isConnected_db()) {
    echo json_encode(['result' => 90, 'token' => null]);
    exit;
}

//メールアドレスでユーザー取得
$sql = "SELECT Password FROM Mst_User WHERE EmailAddress = :email AND DeleteFg = false";
$params = [':email' => $email];
$result = $db->execute_select($sql, $params);

if (!$result) {
    echo json_encode(['result' => 99, 'token' => null]);
    exit;
}

if (empty($result)) {
    echo json_encode(['result' => 51, 'token' => null]);
    exit;
}

$dbPasswordHash = $result[0]['password'];

//パスワード認証
if (!password_verify($password, $dbPasswordHash)) {
    echo json_encode(['result' => 52, 'token' => null]);
    exit;
}

//DB切断
$db->disconnect_db();

//JWT発行
$token = generate_jwt($email);

//レスポンス返却
echo json_encode(['result' => 1, 'token' => $token]);
exit;

// === JWT発行関数 ===
function generate_jwt($email) {
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
    $signature = hash_hmac('sha256', "$base64UrlHeader.$base64UrlPayload", 'your-secret-key', true);
    $base64UrlSignature = base64url_encode($signature);
    return "$base64UrlHeader.$base64UrlPayload.$base64UrlSignature";
}

function base64url_encode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}
