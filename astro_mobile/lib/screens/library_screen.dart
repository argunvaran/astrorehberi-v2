import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';

class LibraryScreen extends StatefulWidget {
  final String lang;
  const LibraryScreen({super.key, required this.lang});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _categories = [];
  String _errorMessage = "";
  
  // Search
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
    _searchController.addListener(_onSearchChanged);
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _categories.map((cat) {
        final items = (cat['items'] as List).where((item) {
           final title = item['title'].toString().toLowerCase();
           final desc = (item['short_desc'] ?? '').toString().toLowerCase();
           return title.contains(query) || desc.contains(query);
        }).toList();
        
        if (items.isNotEmpty) {
           return {
             ...cat,
             'items': items,
             'expanded': true // Auto expand on search
           };
        }
        return null;
      }).where((e) => e != null).toList();
    });
  }

  Future<void> _fetchLibrary() async {
    try {
      final data = await _api.getLibraryItems();
      if(mounted) setState(() {
        _categories = data;
        _filteredCategories = data;
        _isLoading = false;
      });
    } catch (e) {
      if(mounted) setState(() {
         _errorMessage = widget.lang == 'tr' ? "Yüklenemedi: $e" : "Could not load: $e";
         _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.lang == 'tr' ? "Kozmik Kütüphane" : "Cosmic Library", style: GoogleFonts.cinzel(color: const Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
           gradient: LinearGradient(
             begin: Alignment.topCenter, end: Alignment.bottomCenter,
             colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]
           )
        ),
        child: SafeArea(
          child: Column(
            children: [
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: TextField(
                   controller: _searchController,
                   style: const TextStyle(color: Colors.white),
                   decoration: InputDecoration(
                     hintText: widget.lang == 'tr' ? "Kart, terim veya burç ara..." : "Search card, term or sign...",
                     hintStyle: const TextStyle(color: Colors.white54),
                     prefixIcon: const Icon(Icons.search, color: Colors.white54),
                     filled: true,
                     fillColor: Colors.white.withOpacity(0.1),
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                   ),
                 ),
               ),
               
               if (_isLoading)
                 const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
               else if (_errorMessage.isNotEmpty)
                 Expanded(child: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent))))
               else
                 Expanded(
                   child: ListView.builder(
                     padding: const EdgeInsets.all(16),
                     itemCount: _filteredCategories.length,
                     itemBuilder: (context, index) {
                       final cat = _filteredCategories[index];
                       final items = cat['items'] as List;
                       
                       return Container(
                         margin: const EdgeInsets.only(bottom: 20),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.05),
                           borderRadius: BorderRadius.circular(15),
                           border: Border.all(color: Colors.white10)
                         ),
                         child: ExpansionTile(
                           initiallyExpanded: cat['expanded'] ?? false,
                           leading: Icon(_getIcon(cat['icon']), color: Colors.amber),
                           title: Text(cat['name'], style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                           children: items.map((item) => _buildLibraryItem(item)).toList(),
                         ),
                       );
                     },
                   ),
                 )
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getIcon(String? iconClass) {
     // Map generic fontawesome classes to Flutter Icons if possible, or generic
     if (iconClass == null) return Icons.book;
     if (iconClass.contains('star')) return Icons.star;
     if (iconClass.contains('moon')) return Icons.dark_mode;
     if (iconClass.contains('sun')) return Icons.wb_sunny;
     if (iconClass.contains('heart')) return Icons.favorite;
     return Icons.local_library;
  }

  Widget _buildLibraryItem(dynamic item) {
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LibraryDetailScreen(slug: item['slug'], lang: widget.lang))),
      leading: item['image_url'] != null 
        ? CircleAvatar(backgroundImage: NetworkImage(item['image_url']))
        : const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.bookmark, color: Colors.white54)),
      title: Text(item['title'], style: const TextStyle(color: Colors.white)),
      subtitle: item['short_desc'] != null ? Text(item['short_desc'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white30)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
    );
  }
}

class LibraryDetailScreen extends StatefulWidget {
  final String slug;
  final String lang;
  const LibraryDetailScreen({super.key, required this.slug, required this.lang});

  @override
  State<LibraryDetailScreen> createState() => _LibraryDetailScreenState();
}

class _LibraryDetailScreenState extends State<LibraryDetailScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _item;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _api.getLibraryItemDetail(widget.slug);
      if(mounted) setState(() {
        _item = data;
        _isLoading = false;
      });
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F2027),
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    if (_item == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F2027),
        body: Center(child: Text("Not Found", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
          child: const BackButton(color: Colors.white),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]
            )
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               if (_item!['image_url'] != null)
                 Image.network(_item!['image_url'], width: double.infinity, height: 300, fit: BoxFit.cover)
               else
                 const SizedBox(height: 100),
                 
               Padding(
                 padding: const EdgeInsets.all(20),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                        child: Text(_item!['category'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 15),
                      Text(_item!['title'], style: GoogleFonts.cinzel(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Html(
                        data: _item!['content'],
                        style: {
                          "body": Style(color: Colors.white70, fontSize: FontSize(16), lineHeight: LineHeight(1.6)),
                          "h1": Style(color: Colors.amber),
                          "h2": Style(color: Colors.amberAccent),
                          "strong": Style(color: Colors.white, fontWeight: FontWeight.bold),
                        }
                      ),
                      const SizedBox(height: 50),
                   ],
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }
}
