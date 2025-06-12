// ▼ 開発 or 本番をここで切り替える
const bool isProduction = false; // ← true にすると本番URLが使われる

// ▼ ベースURLの切り替え
const String baseUrl = isProduction
    ? 'https://worthapp.worth-sc.jp/Itinerary/public' // 本番
    : 'http://10.0.2.2/myapp'; // Androidエミュレータ用ローカル

// ▼ 各エンドポイント
const String loginEndpoint = '$baseUrl/login.php';
const String registerEndpoint = '$baseUrl/register.php'; // 必要があれば