class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final DateTime deliveredAt;
  final DateTime sentAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.deliveredAt,
    required this.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      notificationType: json['notification_type']?.toString() ?? 'general',
      isRead: json['is_read'] as bool? ?? false,
      deliveredAt: DateTime.tryParse(json['delivered_at']?.toString() ?? '') ?? DateTime.now(),
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      notificationType: notificationType,
      isRead: isRead ?? this.isRead,
      deliveredAt: deliveredAt,
      sentAt: sentAt,
    );
  }
}
