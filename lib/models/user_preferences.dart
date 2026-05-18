class NotificationPreferences {
  final bool booking;
  final bool payment;
  final bool messages;
  final bool marketing;

  const NotificationPreferences({
    this.booking = true,
    this.payment = true,
    this.messages = true,
    this.marketing = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationPreferences();
    return NotificationPreferences(
      booking: json['booking'] != false,
      payment: json['payment'] != false,
      messages: json['messages'] != false,
      marketing: json['marketing'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'booking': booking,
        'payment': payment,
        'messages': messages,
        'marketing': marketing,
      };

  NotificationPreferences copyWith({
    bool? booking,
    bool? payment,
    bool? messages,
    bool? marketing,
  }) =>
      NotificationPreferences(
        booking: booking ?? this.booking,
        payment: payment ?? this.payment,
        messages: messages ?? this.messages,
        marketing: marketing ?? this.marketing,
      );
}

class UserPreferences {
  final NotificationPreferences notifications;
  final bool emailDigest;
  final String theme;
  final String language;

  const UserPreferences({
    this.notifications = const NotificationPreferences(),
    this.emailDigest = true,
    this.theme = 'system',
    this.language = 'en',
  });

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPreferences();
    return UserPreferences(
      notifications: NotificationPreferences.fromJson(
        json['notifications'] as Map<String, dynamic>?,
      ),
      emailDigest: json['emailDigest'] != false,
      theme: json['theme']?.toString() ?? 'system',
      language: json['language']?.toString() ?? 'en',
    );
  }

  Map<String, dynamic> toJson() => {
        'notifications': notifications.toJson(),
        'emailDigest': emailDigest,
        'theme': theme,
        'language': language,
      };

  UserPreferences copyWith({
    NotificationPreferences? notifications,
    bool? emailDigest,
    String? theme,
    String? language,
  }) =>
      UserPreferences(
        notifications: notifications ?? this.notifications,
        emailDigest: emailDigest ?? this.emailDigest,
        theme: theme ?? this.theme,
        language: language ?? this.language,
      );
}
