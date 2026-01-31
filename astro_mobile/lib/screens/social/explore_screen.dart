import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/interactive_models.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<UserSummary> _users = [];
  bool _isLoading = false;

  void _search() async {
    final q = _searchController.text.trim();
    if (q.length < 2) return;
    
    setState(() => _isLoading = true);
    try {
      final list = await _api.searchUsers(q);
      setState(() => _users = list);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _toggleFollow(int index) async {
    final user = _users[index];
    // Optimistic update
    setState(() {
      // Cannot modify final field, so we replace the object
      _users[index] = UserSummary(
        id: user.id, 
        username: user.username, 
        isFollowing: !user.isFollowing
      );
    });

    try {
      await _api.toggleFollow(user.username);
    } catch (e) {
      // Revert if failed
      setState(() {
        _users[index] = user; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: "Kullanıcı Ara...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                   icon: const Icon(Icons.arrow_forward, color: Color(0xFFE94560)),
                   onPressed: _search,
                )
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(user.username[0].toUpperCase())),
                  title: Text(user.username, style: const TextStyle(color: Colors.white)),
                  trailing: ElevatedButton(
                    onPressed: () => _toggleFollow(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isFollowing ? Colors.grey : const Color(0xFFE94560),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                    ),
                    child: Text(user.isFollowing ? "Takibi Bırak" : "Takip Et", 
                      style: const TextStyle(fontSize: 12)),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
