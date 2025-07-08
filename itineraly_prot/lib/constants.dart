// constants.dart

const bool isProduction = false;

const String baseUrl =
    isProduction
        ? 'https://worthapp.worth-sc.jp/Itinerary/public'
        : 'http://10.0.2.2/public';

class ApiEndpoints {
  static const String login = '$baseUrl/login.php';
  static const String register = '$baseUrl/register.php';
}

class AppMessages {
  static const String success = 'アカウントが正常に作成されました';
  static const String errorInvalid = 'メールアドレスまたはパスワードが間違っています';
  static const String errorEmpty = 'メールアドレスまたはパスワードが未入力です';
  static const String errorRegistered = '登録済みのメールアドレスです';
  static const String errorSystemException = 'システムエラーが発生しました。管理者に連絡してください';
}
