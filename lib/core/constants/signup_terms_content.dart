/// Sign-up terms and conditions (same policy as web landing).
class SignupTermsSection {
  const SignupTermsSection({required this.title, required this.body, this.bullets = const []});

  final String title;
  final String body;
  final List<String> bullets;
}

const kSignupTermsSections = <SignupTermsSection>[
  SignupTermsSection(
    title: 'Reservation and Payment',
    body:
        'Clients are encouraged to settle their payment before the scheduled booking date. '
        'Unpaid bookings may still proceed; however, confirmed and fully paid clients will be '
        'prioritized in the event of overlapping schedules or walk-in bookings.',
  ),
  SignupTermsSection(
    title: 'Walk-In Priority Policy',
    body:
        'If a client has not completed payment prior to their scheduled booking, the slot may be '
        'subject to availability. In cases where walk-in clients arrive during the reserved schedule, '
        'management reserves the right to prioritize confirmed paying clients.',
  ),
  SignupTermsSection(
    title: 'No Refund Policy',
    body: 'All payments made are non-refundable.',
  ),
  SignupTermsSection(
    title: 'Exceptions for Refunds',
    body:
        'Refunds will only be granted in cases where the service issue is due to the fault or '
        'negligence of the provider. Examples include, but are not limited to:',
    bullets: [
      'Failure to properly record or save files due to missing or faulty memory cards;',
      'Technical malfunctions resulting in unusable outputs (e.g., black or corrupted photos caused by equipment failure);',
      'Other verified service-related errors directly caused by the provider.',
    ],
  ),
  SignupTermsSection(
    title: 'Agreement',
    body:
        'By completing the registration and booking process, the client acknowledges and agrees to these terms and conditions.',
  ),
];
