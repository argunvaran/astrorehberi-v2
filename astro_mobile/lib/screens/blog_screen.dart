import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // For rendering HTML content
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class BlogScreen extends StatefulWidget {
  final String lang;
  final bool embed; // New parameter
  const BlogScreen({super.key, required this.lang, this.embed = false});

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
      final bool hasNext = data['has_next'] ?? false;
      
      if(mounted) {
        setState(() {
          if(more) {
            _posts.addAll(list);
          } else {
            _posts = list;
          }
          _hasNext = hasNext;
          _isLoading = false;
        });
      }
    } catch(e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embed) {
       return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63)]
          )
        ),
        child: _buildList(),
       );
    }

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
        child: _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return _isLoading && _posts.isEmpty 
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
            );
  }

  Widget _buildBlogPostCard(dynamic post) {
    // New Structure: {id, title, slug, image, date, preview, content}
    String imageUrl = post['image'] ?? "";
    String date = post['date'] ?? "";
    String preview = post['preview'] ?? "";

    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFullPost(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Image
            if(imageUrl.isNotEmpty)
              Image.network(
                imageUrl, 
                height: 180, 
                width: double.infinity, 
                fit: BoxFit.cover,
                errorBuilder: (c,e,s) => Container(height:180, color:Colors.black26, child: const Icon(Icons.broken_image, color:Colors.white24)),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.amber, size: 14),
                      const SizedBox(width: 5),
                      Text(date, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post['title'], 
                    style: GoogleFonts.cinzel(fontSize: 19, color: Colors.white, fontWeight: FontWeight.bold, height: 1.3)
                  ),
                  const SizedBox(height: 10),
                  Html(
                    data: preview,
                    style: {
                      "body": Style(
                        color: Colors.white70, 
                        fontSize: FontSize(14), 
                        maxLines: 3, 
                        textOverflow: TextOverflow.ellipsis,
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero
                      ),
                      "p": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                    }
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Devamını Oku", style: GoogleFonts.outfit(color: const Color(0xFFE94560), fontWeight: FontWeight.bold)),
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward, color: Color(0xFFE94560), size: 16)
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullPost(dynamic post) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BlogDetailScreen(post: post)));
  }
}

class BlogDetailScreen extends StatelessWidget {
  final dynamic post;
  const BlogDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // If content is missing in list view (optimized API), we might want to fetch detail
    // For now assume full content is passed or fetchable
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
       body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0C29),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(post['title'], 
                style: GoogleFonts.cinzel(
                  fontSize: 16, 
                  color: Colors.white, 
                  shadows: [const Shadow(color: Colors.black, blurRadius: 10)]
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: post['image'] != null 
                ? Image.network(post['image'], fit: BoxFit.cover)
                : Container(color: Colors.black26),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Text(post['date'], style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 30),
                  Html(
                    data: post['content'],
                    style: {
                      "body": Style(color: Colors.white, fontSize: FontSize(16), lineHeight: LineHeight(1.8), fontFamily: 'Outfit'),
                      "p": Style(margin: Margins.only(bottom: 20)),
                      "h2": Style(color: Colors.amber, fontSize: FontSize(22), fontFamily: 'Cinzel', margin: Margins.only(top: 20)),
                      "h3": Style(color: const Color(0xFFE94560), fontSize: FontSize(19), fontFamily: 'Cinzel', margin: Margins.only(top: 15)),
                      "li": Style(color: Colors.white70, margin: Margins.only(bottom: 10)),
                      "strong": Style(color: Colors.amber),
                      "img": Style(width: Width(100, Unit.percent), height: Height.auto(), margin: Margins.symmetric(vertical: 20)),
                    }
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
