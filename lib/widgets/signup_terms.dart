import 'package:flutter/material.dart';

import '../core/constants/signup_terms_content.dart';
import '../core/theme/app_colors.dart';

/// Opens scrollable terms dialog; returns `true` when user taps **I Understand**.
Future<bool> showSignupTermsDialog(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const _SignupTermsDialog(),
  );
  return accepted == true;
}

class _SignupTermsDialog extends StatelessWidget {
  const _SignupTermsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          maxWidth: 480,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Terms and Conditions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final section in kSignupTermsSections) ...[
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        section.body,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.muted,
                        ),
                      ),
                      if (section.bullets.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        for (final bullet in section.bullets)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                children: [
                  Text(
                    'Please read the terms above before tapping "I Understand".',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.95)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('I Understand'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Agreement row with link + progress (SafeBite-style).
class SignupTermsAgreement extends StatelessWidget {
  const SignupTermsAgreement({
    super.key,
    required this.accepted,
    required this.onOpenTerms,
  });

  final bool accepted;
  final VoidCallback onOpenTerms;

  @override
  Widget build(BuildContext context) {
    final progress = accepted ? 1.0 : 0.0;
    final label = accepted ? '1/1 agreement accepted' : '0/1 agreement accepted';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accepted ? const Color(0xFFF0FDF4) : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accepted ? const Color(0xFF86EFAC) : AppColors.border.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (accepted)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
                ),
              Text(
                accepted ? 'I have read and agree to the ' : 'I agree to the ',
                style: TextStyle(
                  fontSize: 14,
                  color: accepted ? Colors.green.shade800 : AppColors.text,
                ),
              ),
              GestureDetector(
                onTap: onOpenTerms,
                child: const Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE5E7EB),
              color: AppColors.purple,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: accepted ? Colors.green.shade700 : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
