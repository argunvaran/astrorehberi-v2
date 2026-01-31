import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/interactive_models.dart';
import 'package:google_fonts/google_fonts.dart';

class WallFeedScreen extends StatefulWidget {
  const WallFeedScreen({super.key});

  @override
  State<WallFeedScreen> createState() => _WallFeedScreenState();
}

class _WallFeedScreenState extends State<WallFeedScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  List<WallPost> _posts = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, following, self
  int _page = 1;
  bool _hasNext = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasNext && !_isLoading) _loadPosts(more: true);
    }
  }

  Future<void> _loadPosts({bool more = false}) async {
    if (more) {
      if (!_hasNext) return;
      _page++;
    } else {
      _page = 1;
      _posts.clear();
      setState(() => _isLoading = true);
    }

    try {
      final res = await _api.getWallPosts(filter: _filter, page: _page);
      final List<dynamic> list = res['posts'];
      final bool hasNext = res['has_next'];

      setState(() {
        if (more) {
          _posts.addAll(list.map((e) => WallPost.fromJson(e)));
        } else {
          _posts = list.map((e) => WallPost.fromJson(e)).toList();
        }
        _hasNext = hasNext;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreatePostDialog() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text("Yeni Gönderi", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Ne düşünüyorsun?",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
            onPressed: () async {
              if (_controller.text.trim().isEmpty) return;
              Navigator.pop(context);
              await _api.createPost(_controller.text.trim());
              _loadPosts(); // Refresh
            },
            child: const Text("Paylaş"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE94560),
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filters
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              children: [
                _filterChip('Tümü', 'all'),
                _filterChip('Takip Ettiklerim', 'following'),
                _filterChip('Benim', 'self'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadPosts(),
              child: _posts.isEmpty && !_isLoading
                  ? const Center(child: Text("Henüz gönderi yok.", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _posts.length + (_isLoading ? 1 : 0),
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (context, index) {
                        if (index == _posts.length) return const Center(child: CircularProgressIndicator());
                        final post = _posts[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1))
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blueGrey,
                                    radius: 16,
                                    child: Text(post.user[0].toUpperCase()),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(post.user, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text(post.createdAt, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(post.content, style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.favorite_border, size: 16, color: Colors.white54),
                                  const SizedBox(width: 5),
                                  Text("${post.likes}", style: const TextStyle(color: Colors.white54)),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final bool isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (v) {
          if (v) {
            setState(() {
              _filter = value;
              _loadPosts();
            });
          }
        },
        selectedColor: const Color(0xFFE94560),
        backgroundColor: Colors.white10,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      ),
    );
  }
}
