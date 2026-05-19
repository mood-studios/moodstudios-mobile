/// Copy aligned with the landing site email verification flow.
class AuthMessages {
  AuthMessages._();

  static const otpSpamShort =
      "If you don't see the code within a minute, check your Spam or Promotions folder.";

  static const otpSpamDetail =
      "Can't find it? Check your Spam or Promotions folder. "
      'Open the Mood Studios email and mark it as Not spam so the next code goes to your inbox.';

  static String codeSentTo(String email) =>
      'We sent a 6-digit code to $email.\n\n$otpSpamShort';
}
