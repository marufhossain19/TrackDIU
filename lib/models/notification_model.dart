class TransportNotification {
  final String id;
  final String message;
  final DateTime createdAt;

  const TransportNotification({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  factory TransportNotification.fromMap(Map<String, dynamic> map) {
    return TransportNotification(
      id: map['id']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
