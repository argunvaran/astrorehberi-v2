import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/interactive_models.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  
  List<AppNotification> _notifications = [];
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final notifRes = await _api.getNotifications();
      final convRes = await _api.getConversations();
      
      setState(() {
         _notifications = (notifRes['notifications'] as List).map((e) => AppNotification.fromJson(e)).toList();
         _conversations = convRes;
         _isLoading = false;
      });
      
      // Mark notifications as read
      _api.markRead();
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          tabs: const [
            Tab(text: "Bildirimler"),
            Tab(text: "Mesajlar"),
          ],
        ),
        Expanded(
          child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
            controller: _tabController,
            children: [
              // 1. Notifications
              _notifications.isEmpty
                ? const Center(child: Text("Bildirim yok", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return ListTile(
                        leading: Icon(n.isRead ? Icons.notifications_none : Icons.notifications_active, color: n.isRead ? Colors.white54 : const Color(0xFFE94560)),
                        title: Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(n.message, style: const TextStyle(color: Colors.white70)),
                        trailing: Text(n.date, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                      );
                    },
                  ),
                  
              // 2. Messages
              _conversations.isEmpty
                ? const Center(child: Text("Mesaj yok", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final c = _conversations[index];
                      return ListTile(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUsername: c.username))),
                        leading: CircleAvatar(child: Text(c.username[0].toUpperCase())),
                        title: Text(c.username, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                        trailing: Text(c.timestamp, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                      );
                    },
                  ),
            ],
          ),
        )
      ],
    );
  }
}
