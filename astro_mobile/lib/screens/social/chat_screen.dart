import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/interactive_models.dart';

class ChatScreen extends StatefulWidget {
  final String targetUsername;
  const ChatScreen({super.key, required this.targetUsername});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _msgController = TextEditingController();
  List<DirectMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _api.getMessages(widget.targetUsername);
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final txt = _msgController.text.trim();
    if(txt.isEmpty) return;

    _msgController.clear();
    // Optimistic
    setState(() {
       _messages.add(DirectMessage(sender: 'Me', body: txt, isMe: true, createdAt: 'Now'));
    });

    try {
      await _api.sendMessage(widget.targetUsername, txt);
      // Reload to get timestamp/confirm
      _loadMessages(); 
    } catch (e) {
      // Error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.targetUsername),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 250),
                      decoration: BoxDecoration(
                        color: msg.isMe ? const Color(0xFFE94560) : Colors.white24,
                        borderRadius: BorderRadius.circular(15)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg.body, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(msg.createdAt, style: const TextStyle(fontSize: 10, color: Colors.white70))
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF1E1E2E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Mesaj yaz...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFFE94560)), onPressed: _send)
              ],
            ),
          )
        ],
      ),
    );
  }
}
