import 'package:flutter/material.dart';
import '../core/constants/auth_messages.dart';
import '../core/theme/app_colors.dart';

/// Reminds users to check spam when waiting for SendGrid OTP emails.
class OtpSpamNotice extends StatelessWidget {
  const OtpSpamNotice({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFbeb),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            size: compact ? 18 : 20,
            color: const Color(0xFF92400E),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              compact ? AuthMessages.otpSpamShort : AuthMessages.otpSpamDetail,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                height: 1.4,
                color: Colors.brown.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
