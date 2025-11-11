const bool isProduction = true;

String get baseUrl {
  return 'https://worthapp.worth-sc.jp/Itinerary/public';
}

class ApiEndpoints {
  static final String login = '$baseUrl/login.php';
  static final String register = '$baseUrl/register.php';
}

class AppMessages {
  static const String successDialog = 'ユーザー登録が完了しました。ログイン画面に移動します';
  static const String errorInvalid = 'メールアドレスまたはパスワードが間違っています';
  static const String errorEmpty = 'メールアドレスまたはパスワードが未入力です';
  static const String errorRegistered = '登録済みのメールアドレスです';
  static const String errorSystemException = 'システムエラーが発生しました。管理者に連絡してください';
  static const String errorEmptyEmail = 'メールアドレスが未入力です';
  static const String errorEmptyPassword = 'パスワードが未入力です';
  static const String errorEmptyConfirmPassword = 'パスワード（確認）が未入力です';
  static const String errorNotMatch = 'パスワードと一致しません';
  static const String errorPasswordLengthShort = 'パスワードは8文字以上で入力してください';
  static const String errorPasswordLengthLong = 'パスワードは32文字以内で入力してください';
  static const String errorPasswordRequireLower = 'パスワードには英小文字を1文字以上含めてください';
  static const String errorPasswordRequireUpper = 'パスワードには英大文字を1文字以上含めてください';
  static const String errorPasswordRequireNumber = 'パスワードには数字を1文字以上含めてください';
  static const String errorPasswordInvalidChar = '使用できない文字が含まれています';
  static const String errorInvalidEmailFormat = '正しいメールアドレスの形式で入力してください';
  static const String errorInvalidInput = '入力項目の内容に問題があります';
  static const String showPolicy = 'パスワードポリシー';
  static const String dialogClose = '閉じる';
}

class RegexPatterns {
  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp passwordLower = RegExp(r'[a-z]');
  static final RegExp passwordUpper = RegExp(r'[A-Z]');
  static final RegExp passwordNumber = RegExp(r'[0-9]');
  static final RegExp passwordAllowedChars = RegExp(
    r'^[a-zA-Z0-9~!@#\$%\^&\*\(\)_\+\-=\{\}\[\]\\|:;\"<>,\.\?\/]+$',
  );
}

class PasswordPolicy {
  static const String description =
      '■ 文字数：8文字以上～32文字以下\n'
      '■ 条件：英小文字、英大文字、数字を最低1文字ずつ使用\n'
      '■ 使用可能な文字：\n'
      '・半角英数字（a〜z, A〜Z, 0〜9）\n'
      '\n'
      '・使用可能な記号：\n'
      ' ˜ ! @ # \$ % ^ & * ( ) _ + - = { } [ ]\n'
      '| : ; " < > , . ? /\n';
}

class LoginResultCodes {
  static const int success = 1;
  static const int emptyInput = 50;
  static const int invalidInput1 = 51;
  static const int invalidInput2 = 52;
}

class RegisterResultCodes {
  static const int success = 1;
  static const int emptyInput = 50;
  static const int invalidInput1 = 51;
  static const int invalidInput2 = 52;
  static const int alreadyRegistered = 53;
}
