/// Notification Model
/// 
/// Represents a notification for the customer
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'order', 'promotion', 'payment', etc.
  final bool isRead;
  final DateTime createdOn;
  final Map<String, dynamic>? data; // Additional data

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdOn,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'general',
      isRead: json['is_read'] as bool? ?? false,
      createdOn: DateTime.parse(json['created_on'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_on': createdOn.toIso8601String(),
      if (data != null) 'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdOn,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdOn: createdOn ?? this.createdOn,
      data: data ?? this.data,
    );
  }
}

