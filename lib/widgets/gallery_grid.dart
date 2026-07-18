import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../core/providers.dart';
import '../core/services.dart';
import '../screens/detail_screen.dart';

class GalleryGrid extends StatefulWidget {
  final String tags;
  final EdgeInsets padding;
  final List<dynamic>? preloadedPosts;
  const GalleryGrid({super.key, required this.tags, this.padding = const EdgeInsets.all(8.0), this.preloadedPosts});
  @override
  State<GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<GalleryGrid> {
  final DanbooruService _api = DanbooruService();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _posts = [];
  bool _isLoading = true, _isFetchingMore = false, _hasMore = true, _showBackToTopButton = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedPosts != null) {
      _posts = widget.preloadedPosts!;
      _isLoading = false;
      _hasMore = false;
    } else if (widget.tags != 'BOOKMARKS') {
      _fetchInitialData();
    }
    _scrollController.addListener(() {
      if (_hasMore && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) { _fetchMoreData(); }
      if (_scrollController.offset >= 400 && !_showBackToTopButton) { setState(() => _showBackToTopButton = true); }
      else if (_scrollController.offset < 400 && _showBackToTopButton) { setState(() => _showBackToTopButton = false); }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    final blacklist = Provider.of<UserDataProvider>(context, listen: false).blacklist;
    final rating = Provider.of<SettingsProvider>(context, listen: false).rating;

    final rawPosts = await _api.fetchPosts(tags: widget.tags, rating: rating, page: 1);
    final filteredPosts = rawPosts.where((post) {
      final String tagString = post['tag_string'] ?? '';
      final List<String> postTags = tagString.split(' ');
      return !blacklist.any((blacklistedTag) => postTags.contains(blacklistedTag));
    }).toList();

    if (mounted) {
      setState(() { _posts = filteredPosts; _isLoading = false; _currentPage = 1; _hasMore = rawPosts.isNotEmpty; });
    }
  }

  Future<void> _fetchMoreData() async {
    if (_isFetchingMore || !_hasMore || widget.tags == 'BOOKMARKS') { return; }
    setState(() => _isFetchingMore = true);

    final blacklist = Provider.of<UserDataProvider>(context, listen: false).blacklist;
    final rating = Provider.of<SettingsProvider>(context, listen: false).rating;
    List<dynamic> newlyFetched = [];

    while (newlyFetched.isEmpty && _hasMore) {
      _currentPage++;
      final rawPosts = await _api.fetchPosts(tags: widget.tags, rating: rating, page: _currentPage);
      if (rawPosts.isEmpty) { _hasMore = false; break; }

      newlyFetched = rawPosts.where((post) {
        final String tagString = post['tag_string'] ?? '';
        final List<String> postTags = tagString.split(' ');
        return !blacklist.any((blacklistedTag) => postTags.contains(blacklistedTag));
      }).toList();
    }

    if (mounted) {
      setState(() { _posts.addAll(newlyFetched); _isFetchingMore = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = Provider.of<SelectionProvider>(context);
    final userData = Provider.of<UserDataProvider>(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (widget.tags == 'BOOKMARKS') {
      _posts = userData.bookmarkedPosts;
      _isLoading = false;
      _hasMore = false;
    }
    if (_isLoading) { return const Center(child: CircularProgressIndicator()); }
    if (_posts.isEmpty) { return const Center(child: Text('No images found.')); }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: widget.tags != 'BOOKMARKS' ? _fetchInitialData : () async {},
          child: MasonryGridView.builder(
            controller: _scrollController, padding: widget.padding,
            gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: MediaQuery.of(context).size.width < 500 ? 2 : MediaQuery.of(context).size.width < 800 ? 3 : 4),
            mainAxisSpacing: 8, crossAxisSpacing: 8, itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              final imageUrl = post['large_file_url'] ?? post['file_url'] ?? post['preview_file_url'] ?? '';
              final postId = post['id'].toString();
              final isSelected = selection.selectedIds.contains(postId);
              return GestureDetector(
                onLongPress: () { if (!selection.isSelectionMode) { selection.start(postId); } },
                onTap: () {
                  if (selection.isSelectionMode) {
                    selection.toggle(postId);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(initialIndex: index, posts: _posts, onFetchMore: _fetchMoreData)));
                  }
                },
                child: Stack(
                  children: [
                    Hero(
                      tag: postId,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: ((post['image_width'] ?? 1) / (post['image_height'] ?? 1)).toDouble(),
                          child: CachedNetworkImage(imageUrl: imageUrl, memCacheWidth: 400, fit: BoxFit.cover, placeholder: (c, u) => Container(color: Colors.grey[800]), errorWidget: (c, u, e) => const Icon(Icons.error)),
                        ),
                      ),
                    ),
                    if (selection.isSelectionMode) Positioned.fill(child: Container(decoration: BoxDecoration(color: isSelected ? Colors.black.withValues(alpha: 0.4) : Colors.transparent, borderRadius: BorderRadius.circular(8)))),
                    Positioned(
                      bottom: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => !selection.isSelectionMode ? selection.start(postId) : selection.toggle(postId),
                        child: Container(padding: const EdgeInsets.all(6), child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6), size: 26, shadows: const [Shadow(color: Colors.black54, blurRadius: 6)])),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        if (_isFetchingMore) Positioned(bottom: selection.isSelectionMode ? 90.0 : 16.0, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.all(8.0), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)]), child: const CircularProgressIndicator()))),
        AnimatedPositioned(duration: const Duration(milliseconds: 200), bottom: selection.isSelectionMode ? 90.0 : 16.0, right: 16.0, child: AnimatedScale(scale: _showBackToTopButton ? 1.0 : 0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutBack, child: FloatingActionButton(mini: true, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9), onPressed: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut), child: Icon(Icons.keyboard_arrow_up_rounded, color: Theme.of(context).colorScheme.onPrimary)))),
        
        AnimatedPositioned(duration: const Duration(milliseconds: 200), top: selection.isSelectionMode ? 0 : -100, left: 0, right: 0, child: Material(elevation: 4, color: Theme.of(context).colorScheme.surface, child: SafeArea(bottom: false, child: SizedBox(height: 56, child: Row(children: [IconButton(icon: const Icon(Icons.close), onPressed: selection.clear), const SizedBox(width: 8), Text('${selection.count} items selected', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.select_all), onPressed: () => selection.selectAll(_posts.map((p) => p['id'].toString()).toList()))]))))),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200), bottom: selection.isSelectionMode ? 0 : -100, left: 0, right: 0,
          child: Material(
            elevation: 8, color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 70,
                child: Row(
                  children: [
                    Expanded(child: InkWell(onTap: () async { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading ${selection.count} items...'))); for (var id in selection.selectedIds) { await downloadImage(_posts.firstWhere((p) => p['id'].toString() == id)['file_url'], customPath: settings.downloadPath); } selection.clear(); }, child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.download_rounded), SizedBox(height: 4), Text('Download', style: TextStyle(fontSize: 12))]))),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (widget.tags == 'BOOKMARKS') {
                            userData.removeBookmarkMultiple(selection.selectedIds);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmarks Removed')));
                          } else {
                            for (var id in selection.selectedIds) { userData.toggleBookmark(id, _posts.firstWhere((p) => p['id'].toString() == id)); }
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmarks Updated')));
                          }
                          selection.clear();
                        },
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(widget.tags == 'BOOKMARKS' ? Icons.bookmark_remove : Icons.bookmark_border_rounded), const SizedBox(height: 4), Text(widget.tags == 'BOOKMARKS' ? 'Remove' : 'Bookmark', style: const TextStyle(fontSize: 12))]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}