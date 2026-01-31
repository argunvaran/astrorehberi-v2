class WallPost {
  final int id;
  final String user;
  final String content;
  final String createdAt;
  final int likes;

  WallPost({
    required this.id,
    required this.user,
    required this.content,
    required this.createdAt,
    required this.likes,
  });

  factory WallPost.fromJson(Map<String, dynamic> json) {
    return WallPost(
      id: json['id'] ?? 0,
      user: json['user'] ?? 'Unknown',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
      likes: json['likes'] ?? 0,
    );
  }
}

class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String date;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.date,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      date: json['date'] ?? '',
    );
  }
}

class UserSummary {
  final int id;
  final String username;
  final bool isFollowing;

  UserSummary({
    required this.id,
    required this.username,
    required this.isFollowing,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      isFollowing: json['is_following'] ?? false,
    );
  }
}

class Conversation {
  final String username;
  final String lastMessage;
  final String timestamp;

  Conversation({
    required this.username,
    required this.lastMessage,
    required this.timestamp,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      username: json['username'] ?? '',
      lastMessage: json['last_message'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class DirectMessage {
  final String sender;
  final String body;
  final bool isMe;
  final String createdAt;

  DirectMessage({
    required this.sender,
    required this.body,
    required this.isMe,
    required this.createdAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      sender: json['sender'] ?? '',
      body: json['body'] ?? '',
      isMe: json['is_me'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Appointment {
  final int id;
  final String user;
  final String topic;
  final String message;
  final String status;
  final String contact; // Added contact field
  final String date;

  Appointment({
    required this.id,
    required this.user,
    required this.topic,
    required this.message,
    required this.status,
    required this.contact,
    required this.date,
  });
  
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? 0,
      user: json['user'] ?? '',
      topic: json['topic'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      contact: json['contact'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class ContactMessage {
  final int id;
  final String name;
  final String email;
  final String message;
  final String date;

  ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.date,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      message: json['message'] ?? '',
      date: json['created_at'] ?? '', 
    );
  }
}

class LogEntry {
  final String timestamp;
  final String user;
  final String action;
  final String ip;

  LogEntry({
    required this.timestamp,
    required this.user,
    required this.action,
    required this.ip,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: json['timestamp'] ?? '',
      user: json['user'] ?? 'Ziyaretçi',
      action: json['action'] ?? '',
      ip: json['ip_address'] ?? '',
    );
  }
}
