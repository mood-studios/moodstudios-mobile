class TimeSlot {
  final String time;
  final String value;
  final bool available;

  const TimeSlot({
    required this.time,
    required this.value,
    required this.available,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      available: json['available'] == true,
    );
  }
}
