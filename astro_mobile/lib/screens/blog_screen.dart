import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // For rendering HTML content
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class BlogScreen extends StatefulWidget {
  final String lang;
  const BlogScreen({super.key, required this.lang});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasNext = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts({bool more = false}) async {
    if(!more) {
      if(mounted) setState(() => _isLoading = true);
    }
    
    try {
      final data = await _api.getBlogPosts(page: _page);
      final list = data['posts'] as List;
      final pagination = data['pagination'];
      
      if(mounted) {
        setState(() {
          if(more) {
            _posts.addAll(list);
          } else {
            _posts = list;
          }
          _hasNext = pagination['has_next'];
          _isLoading = false;
        });
      }
    } catch(e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTr = widget.lang == 'tr';
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: Text(isTr ? "Kozmik Yazılar" : "Cosmic Articles", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63)]
          )
        ),
        child: _isLoading && _posts.isEmpty 
          ? const Center(child: CircularProgressIndicator()) 
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _posts.length + (_hasNext ? 1 : 0),
              itemBuilder: (ctx, i) {
                if(i == _posts.length) {
                  return TextButton(
                    onPressed: () { _page++; _loadPosts(more:true); },
                    child: const Text("Daha Fazla Yükle", style: TextStyle(color: Colors.white70))
                  );
                }
                
                final p = _posts[i];
                return _buildBlogPostCard(p);
              },
            ),
      ),
    );
  }

  Widget _buildBlogPostCard(dynamic post) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post['title'], 
                    style: GoogleFonts.cinzel(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(post['published_date'], style: const TextStyle(color: Colors.white30, fontSize: 12)),
            const Divider(color: Colors.white10),
            // Preview Content
            Html(
              data: post['preview'],
              style: {
                "body": Style(color: Colors.white70, fontSize: FontSize(14)),
                "p": Style(color: Colors.white70),
              }
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _openFullPost(post),
                child: const Text("Devamını Oku ->", style: TextStyle(color: Color(0xFFE94560))),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _openFullPost(dynamic post) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(post['title'], style: const TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(post['date_range'], style: const TextStyle(color: Colors.amber, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Html(
              data: post['content'],
               style: {
                "body": Style(color: Colors.white, fontSize: FontSize(16), lineHeight: LineHeight(1.6)),
                "h2": Style(color: Colors.amber, fontSize: FontSize(20)),
                "strong": Style(color: Color(0xFFE94560), fontWeight: FontWeight.bold),
              }
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    )));
  }
}
