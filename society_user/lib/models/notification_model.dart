class NotificationModel {
  final dynamic id;
  final dynamic userId;
  final dynamic title;
  final dynamic message;
  final dynamic type; // info, warning, success, alert
  final dynamic refType; // visitor, complaint, payment, booking, guard, etc
  final dynamic refId;
  final dynamic isRead;
  final dynamic readAt;
  final dynamic createdAt;
  final dynamic updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.refType,
    this.refId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      refType: json['ref_type'],
      refId: json['ref_id'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
