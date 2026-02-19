import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/interactive_models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';

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
                                    if (post.compatibility > 50) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: post.compatibility > 80 ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: post.compatibility > 80 ? Colors.green : Colors.orange, width: 0.5),
                                        ),
                                        child: Text(
                                          "Uyum: %${post.compatibility}",
                                          style: TextStyle(
                                            color: post.compatibility > 80 ? Colors.green : Colors.orange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(post.createdAt, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(post.content, style: const TextStyle(color: Colors.white70)),
                                const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      // Like Button
                                      _actionButton(
                                        icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                                        label: "${post.likes}",
                                        color: post.isLiked ? Colors.red : Colors.white54,
                                        onTap: () async {
                                          final int idx = _posts.indexOf(post);
                                          if (idx == -1) return;
                                          final bool oldLiked = post.isLiked;
                                          final int oldLikes = post.likes;
                                          
                                          setState(() {
                                            _posts[idx] = WallPost(
                                              id: post.id, user: post.user, content: post.content, createdAt: post.createdAt,
                                              likes: oldLiked ? oldLikes - 1 : oldLikes + 1,
                                              isLiked: !oldLiked,
                                              compatibility: post.compatibility,
                                              commentCount: post.commentCount
                                            );
                                          });

                                          try {
                                            await _api.toggleLike(post.id);
                                          } catch(e) {
                                            setState(() { _posts[idx] = post; });
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 20),
                                      // Comment Button
                                      _actionButton(
                                        icon: Icons.chat_bubble_outline,
                                        label: "${post.commentCount}",
                                        color: Colors.white54,
                                        onTap: () => _showCommentsBottomSheet(post),
                                      ),
                                      const Spacer(),
                                      // DM Button for compatibility
                                      if (post.compatibility >= 75 && post.user != "Ben")
                                        TextButton.icon(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUsername: post.user))),
                                          icon: const Icon(Icons.flash_on, size: 16, color: Colors.amber),
                                          label: const Text("Sohbet Et", style: TextStyle(color: Colors.amber, fontSize: 12)),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.amber.withOpacity(0.1),
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                        ),
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

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  void _showCommentsBottomSheet(WallPost post) {
    final TextEditingController _commentCtrl = TextEditingController();
    List<PostComment>? _comments;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (_comments == null) {
            _api.getComments(post.id).then((value) => setModalState(() => _comments = value));
          }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 15, right: 15, top: 15),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 15),
                const Text("Yorumlar", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(color: Colors.white10),
                Expanded(
                  child: _comments == null 
                  ? const Center(child: CircularProgressIndicator())
                  : _comments!.isEmpty 
                    ? const Center(child: Text("Henüz yorum yok. İlk sen yaz!", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _comments!.length,
                        itemBuilder: (c, i) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_comments![i].user, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(_comments![i].content, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          trailing: Text(_comments![i].createdAt.split(' ')[1], style: const TextStyle(color: Colors.white24, fontSize: 10)),
                        ),
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Yorum yaz...",
                            hintStyle: TextStyle(color: Colors.white30),
                            border: InputBorder.none
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFFE94560)),
                        onPressed: () async {
                          if (_commentCtrl.text.trim().isEmpty) return;
                          final txt = _commentCtrl.text.trim();
                          _commentCtrl.clear();
                          try {
                            await _api.addComment(post.id, txt);
                            // Refresh
                            final updated = await _api.getComments(post.id);
                            setModalState(() => _comments = updated);
                            setState(() {
                               final idx = _posts.indexOf(post);
                               if(idx != -1) {
                                  _posts[idx] = WallPost(
                                    id: post.id, user: post.user, content: post.content, createdAt: post.createdAt,
                                    likes: post.likes, isLiked: post.isLiked, compatibility: post.compatibility,
                                    commentCount: post.commentCount + 1
                                  );
                               }
                            });
                          } catch(e) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorum gönderilemedi")));
                          }
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        }
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
