import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../core/providers.dart';
import '../core/services.dart';
import '../widgets/gallery_grid.dart';

class TagSearchScreen extends StatefulWidget {
  const TagSearchScreen({super.key});
  @override
  State<TagSearchScreen> createState() => _TagSearchScreenState();
}

class _TagSearchScreenState extends State<TagSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DanbooruService _api = DanbooruService();
  List<dynamic> _trendingTags = [];

  @override
  void initState() {
    super.initState();
    _fetchTrending();
  }

  Future<void> _fetchTrending() async {
    final tags = await _api.fetchTrendingTags();
    if (mounted) {
      setState(() {
        _trendingTags = tags;
      });
    }
  }

  void _submitSearch(String tags) {
    if (tags.trim().isNotEmpty) {
      Provider.of<UserDataProvider>(context, listen: false).addSearchHistory(tags.trim());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GalleryResultScreen(tags: tags.trim())),
      );
    }
  }

  void _appendTag(String tag) {
    final current = _searchController.text;
    _searchController.text = current.isEmpty ? '$tag ' : '$current$tag ';
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TypeAheadField<dynamic>(
            controller: _searchController,
            builder: (context, controller, focusNode) => TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _submitSearch,
              decoration: const InputDecoration(hintText: 'Enter tags...', border: InputBorder.none),
            ),
            suggestionsCallback: (pattern) async {
              final terms = pattern.split(' ');
              final lastTerm = terms.last;
              if (lastTerm.length < 2) { return []; }
              final results = await _api.fetchTags(lastTerm);
              results.removeWhere((tag) => userData.blacklist.contains(tag['name']));
              return results;
            },
            itemBuilder: (context, suggestion) => ListTile(
              leading: Icon(Icons.tag, color: Theme.of(context).colorScheme.primary),
              title: Text(suggestion['name'] ?? ''),
              trailing: Text((suggestion['post_count'] ?? 0).toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            onSelected: (suggestion) {
              final terms = _searchController.text.split(' ')..removeLast()..add(suggestion['name'] ?? '');
              _searchController.text = '${terms.join(' ')} ';
            },
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('METATAGS', Icons.auto_awesome),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(label: const Text('rating:g'), backgroundColor: Colors.green.withValues(alpha: 0.2), onPressed: () => _appendTag('rating:g')),
                ActionChip(label: const Text('rating:s'), backgroundColor: Colors.orange.withValues(alpha: 0.2), onPressed: () => _appendTag('rating:s')),
                ActionChip(label: const Text('rating:e'), backgroundColor: Colors.red.withValues(alpha: 0.2), onPressed: () => _appendTag('rating:e')),
                ActionChip(label: const Text('score:>50'), backgroundColor: Colors.blue.withValues(alpha: 0.2), onPressed: () => _appendTag('score:>50')),
                ActionChip(label: const Text('order:rank'), backgroundColor: Colors.purple.withValues(alpha: 0.2), onPressed: () => _appendTag('order:rank')),
              ],
            ),

            _buildSectionHeader('TRENDING', Icons.trending_up),
            _trendingTags.isEmpty
                ? const CircularProgressIndicator()
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _trendingTags.map((tag) => ActionChip(
                      label: Text(tag['name']),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      onPressed: () => _submitSearch(tag['name']),
                    )).toList(),
                  ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('HISTORY', Icons.history),
                if (userData.searchHistory.isNotEmpty)
                  IconButton(icon: const Icon(Icons.delete_sweep), onPressed: userData.clearSearchHistory),
              ],
            ),
            if (userData.searchHistory.isEmpty)
              const Text('No recent searches.', style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: userData.searchHistory.map((tag) => ActionChip(
                  label: Text(tag),
                  onPressed: () => _submitSearch(tag),
                )).toList(),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class GalleryResultScreen extends StatefulWidget {
  final String tags;
  final List<dynamic>? preloadedPosts;
  const GalleryResultScreen({super.key, required this.tags, this.preloadedPosts});
  @override
  State<GalleryResultScreen> createState() => _GalleryResultScreenState();
}

class _GalleryResultScreenState extends State<GalleryResultScreen> {
  bool _isSearchBarVisible = true;
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);
    final isFavorite = userData.favoriteTags.contains(widget.tags);

    return Consumer<SelectionProvider>(
      builder: (context, selection, child) {
        return Scaffold(
          body: Stack(
            children: [
              NotificationListener<UserScrollNotification>(
                onNotification: (notif) {
                  if (notif.direction == ScrollDirection.reverse && _isSearchBarVisible) {
                    setState(() => _isSearchBarVisible = false);
                  } else if (notif.direction == ScrollDirection.forward && !_isSearchBarVisible) {
                    setState(() => _isSearchBarVisible = true);
                  }
                  return false;
                },
                child: GalleryGrid(
                  tags: widget.tags,
                  preloadedPosts: widget.preloadedPosts,
                  padding: const EdgeInsets.only(top: 100, bottom: 20, left: 8, right: 8),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                top: (selection.isSelectionMode || !_isSearchBarVisible) ? -100 : 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 4,
                  color: Theme.of(context).colorScheme.surface,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                          Expanded(
                            child: Text(
                              widget.tags,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.tags != 'BOOKMARKS')
                            IconButton(
                              icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? Colors.amber : null),
                              onPressed: () => userData.toggleFavoriteTag(widget.tags),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}