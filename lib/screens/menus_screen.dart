import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;

import '../core/themes.dart';
import '../core/providers.dart';
import '../core/services.dart';
import '../widgets/gallery_grid.dart';
import 'search_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              image: const DecorationImage(image: AssetImage('assets/images/banner.png'), fit: BoxFit.cover),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('NekoView', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(offset: const Offset(1, 1), blurRadius: 3, color: Colors.black.withValues(alpha: 0.7))])),
                const SizedBox(height: 8),
                Text('v2.3.1', style: TextStyle(color: Colors.white, shadows: [Shadow(offset: const Offset(1, 1), blurRadius: 2, color: Colors.black.withValues(alpha: 0.7))])),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.palette), title: Text(themeProvider.themeName), onTap: () => themeProvider.cycleTheme()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Content Rating', prefixIcon: Icon(Icons.security), border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: settingsProvider.rating,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All (Unfiltered)')),
                    DropdownMenuItem(value: 'g', child: Text('General (Safe)')),
                    DropdownMenuItem(value: 's', child: Text('Sensitive')),
                    DropdownMenuItem(value: 'q', child: Text('Questionable')),
                    DropdownMenuItem(value: 'e', child: Text('Explicit (NSFW)')),
                  ],
                  onChanged: (v) {
                    if (v != null) { settingsProvider.setRating(v); }
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.star_rounded), title: const Text('Favorite Tags'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteTagsScreen())); }),
          ListTile(leading: const Icon(Icons.block_rounded), title: const Text('Blacklist'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const BlacklistScreen())); }),
          ListTile(leading: const Icon(Icons.bookmark_rounded), title: const Text('Bookmarks'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryResultScreen(tags: 'BOOKMARKS'))); }),
          ListTile(leading: const Icon(Icons.collections_bookmark_rounded), title: const Text('Pools'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PoolsScreen())); }),
          ListTile(leading: const Icon(Icons.download_done_rounded), title: const Text('Downloads'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen())); }),
          const Divider(),
          ListTile(leading: const Icon(Icons.storage_rounded), title: const Text('Data & Storage'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DataAndStorageScreen())); }),
          ListTile(leading: const Icon(Icons.info_outline_rounded), title: const Text('About'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())); }),
        ],
      ),
    );
  }
}

class ArtistProfileScreen extends StatefulWidget {
  final String artistName;
  const ArtistProfileScreen({super.key, required this.artistName});
  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  Map<String, dynamic>? _artistData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DanbooruService().fetchArtist(widget.artistName).then((data) {
      if (mounted) { setState(() { _artistData = data; _loading = false; }); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.artistName.replaceAll('_', ' '))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_artistData != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('External Links', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: (_artistData!['urls'] as List<dynamic>?)?.map((urlObj) {
                            final url = urlObj['url'].toString();
                            return ActionChip(
                              label: Text(Uri.parse(url).host, style: const TextStyle(fontSize: 12)),
                              onPressed: () => launchUrl(Uri.parse(url)),
                            );
                          }).toList() ?? [const Text('No links found.')],
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Expanded(child: GalleryGrid(tags: widget.artistName, padding: const EdgeInsets.all(8))),
              ],
            ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About NekoView')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 24),
          const SizedBox(height: 16),
          const Center(child: Text('NekoView', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
          const Center(child: Text('Version 2.3.1', style: TextStyle(color: Colors.grey, fontSize: 16))),
          const SizedBox(height: 32),
          const Text('An open-source, ad-free booru client. Built to provide a better experience for browsing Danbooru.', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(leading: const Icon(Icons.api_rounded), title: const Text('Data Source'), subtitle: const Text('Powered by the Danbooru API.'), onTap: () => launchUrl(Uri.parse('https://danbooru.donmai.us'))),
          const ListTile(leading: Icon(Icons.code_rounded), title: Text('Framework'), subtitle: Text('Built with Flutter and Dart.')),
          ListTile(
            leading: const Icon(Icons.email_rounded),
            title: const Text('Developer Contact'),
            subtitle: const Text('mail@cazon.uk'),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Built by CazonUK team.', style: TextStyle(color: Colors.grey, fontSize: 14))),
          ),
        ],
      ),
    );
  }
}

class FavoriteTagsScreen extends StatefulWidget {
  const FavoriteTagsScreen({super.key});
  @override
  State<FavoriteTagsScreen> createState() => _FavoriteTagsScreenState();
}

class _FavoriteTagsScreenState extends State<FavoriteTagsScreen> {
  final TextEditingController _controller = TextEditingController();
  final DanbooruService _api = DanbooruService();

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Tags')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TypeAheadField<dynamic>(
              controller: _controller,
              builder: (context, controller, focusNode) => TextField(controller: controller, focusNode: focusNode, decoration: const InputDecoration(hintText: 'Add a tag to favorites...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.star)), onSubmitted: (val) { if (val.trim().isNotEmpty) { userData.toggleFavoriteTag(val.trim()); _controller.clear(); } }),
              suggestionsCallback: (pattern) async { if (pattern.length < 2) { return []; } final results = await _api.fetchTags(pattern); results.removeWhere((tag) => userData.blacklist.contains(tag['name'])); return results; },
              itemBuilder: (context, suggestion) => ListTile(leading: const Icon(Icons.tag), title: Text(suggestion['name'] ?? '')),
              onSelected: (suggestion) { userData.toggleFavoriteTag(suggestion['name'] ?? ''); _controller.clear(); },
            ),
          ),
          Expanded(
            child: userData.favoriteTags.isEmpty
                ? const Center(child: Text('No favorite tags added.'))
                : ListView.builder(
                    itemCount: userData.favoriteTags.length,
                    itemBuilder: (context, index) {
                      final tag = userData.favoriteTags[index];
                      return ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber), title: Text(tag),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => userData.toggleFavoriteTag(tag)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryResultScreen(tags: tag))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});
  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  final TextEditingController _controller = TextEditingController();
  final DanbooruService _api = DanbooruService();

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Blacklist')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TypeAheadField<dynamic>(
              controller: _controller,
              builder: (context, controller, focusNode) => TextField(controller: controller, focusNode: focusNode, decoration: const InputDecoration(hintText: 'Add a tag to blacklist...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.block)), onSubmitted: (val) { if (val.trim().isNotEmpty) { userData.addBlacklist(val.trim()); _controller.clear(); } }),
              suggestionsCallback: (pattern) async { if (pattern.length < 2) { return []; } final results = await _api.fetchTags(pattern); results.removeWhere((tag) => userData.blacklist.contains(tag['name'])); return results; },
              itemBuilder: (context, suggestion) => ListTile(leading: const Icon(Icons.tag), title: Text(suggestion['name'] ?? '')),
              onSelected: (suggestion) { userData.addBlacklist(suggestion['name'] ?? ''); _controller.clear(); },
            ),
          ),
          Expanded(
            child: userData.blacklist.isEmpty
                ? const Center(child: Text('No blacklisted tags.'))
                : ListView.builder(
                    itemCount: userData.blacklist.length,
                    itemBuilder: (context, index) {
                      final tag = userData.blacklist[index];
                      return ListTile(
                        leading: const Icon(Icons.block, color: Colors.redAccent), title: Text(tag),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => userData.removeBlacklist(tag)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DataAndStorageScreen extends StatefulWidget {
  const DataAndStorageScreen({super.key});
  @override
  State<DataAndStorageScreen> createState() => _DataAndStorageScreenState();
}

class _DataAndStorageScreenState extends State<DataAndStorageScreen> {
  String _cacheSize = "Calculating...";

  @override
  void initState() {
    super.initState();
    _calcCache();
  }

  Future<void> _calcCache() async {
    try {
      final dir = await getTemporaryDirectory();
      int size = 0;
      if (dir.existsSync()) {
        for (var file in dir.listSync(recursive: true, followLinks: false)) {
          if (file is File) { size += file.lengthSync(); }
        }
      }
      setState(() => _cacheSize = "${(size / 1024 / 1024).toStringAsFixed(2)} MB");
    } catch (_) {
      setState(() => _cacheSize = "Unknown");
    }
  }

  Future<void> _clearCache() async {
    final dir = await getTemporaryDirectory();
    if (dir.existsSync()) { dir.deleteSync(recursive: true); }
    _calcCache();
    if (!mounted) { return; }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared!')));
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Storage')),
      body: ListView(
        children: [
          const Padding(padding: EdgeInsets.all(16.0), child: Text("Backup & Restore", style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.upload_file), title: const Text('Export User Data'), subtitle: const Text('Saves settings, history, and bookmarks.'), onTap: () { userData.exportData(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing export...'))); }),
          ListTile(leading: const Icon(Icons.download), title: const Text('Import User Data'), subtitle: const Text('Restore from a backup JSON file.'), onTap: () { userData.importData(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Importing data...'))); }),
          const Divider(),
          const Padding(padding: EdgeInsets.all(16.0), child: Text("Cache & Erase", style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.cached), title: const Text('Clear Image Cache'), subtitle: Text(_cacheSize), trailing: IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: _clearCache)),
          ListTile(leading: const Icon(Icons.warning, color: Colors.red), title: const Text('Erase All Data', style: TextStyle(color: Colors.red)), subtitle: const Text('Deletes all bookmarks, settings, favorites, and blacklists.'), onTap: () { userData.clearAllData(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data wiped.'))); }),
        ],
      ),
    );
  }
}

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Download Manager')),
      body: Column(
        children: [
          ListTile(leading: const Icon(Icons.folder), title: const Text('Download Path'), subtitle: Text(settings.downloadPath.isEmpty ? 'Default (Device Gallery)' : settings.downloadPath), trailing: ElevatedButton(onPressed: settings.setDownloadPath, child: const Text('Change'))),
          const Divider(),
          const Expanded(child: Center(child: Text('Downloaded files appear here natively in gallery.', style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }
}

class PoolsScreen extends StatelessWidget {
  const PoolsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Pool Gallery'), bottom: const TabBar(tabs: [Tab(text: 'Series'), Tab(text: 'Collection')])),
        body: const TabBarView(children: [PoolGrid(category: 'series'), PoolGrid(category: 'collection')]),
      ),
    );
  }
}

class PoolGrid extends StatefulWidget {
  final String category;
  const PoolGrid({super.key, required this.category});
  @override
  State<PoolGrid> createState() => _PoolGridState();
}

class _PoolGridState extends State<PoolGrid> {
  final DanbooruService _api = DanbooruService();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _pools = [];
  bool _isLoading = true, _isFetchingMore = false, _hasMore = true;
  int _currentPage = 1;
  late String _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = Provider.of<SettingsProvider>(context, listen: false).rating;
    _fetchData();
    _scrollController.addListener(() {
      if (_hasMore && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) { _fetchMoreData(); }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentRating = Provider.of<SettingsProvider>(context, listen: false).rating;
    if (_selectedRating != currentRating) {
      _selectedRating = currentRating;
      _resetAndFetch();
    }
  }

  Future<void> _resetAndFetch() async {
    if (!mounted) { return; }
    setState(() { _pools = []; _isLoading = true; _isFetchingMore = false; _hasMore = true; _currentPage = 1; });
    await _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _api.fetchPools(category: widget.category, page: 1, rating: _selectedRating);
    if (mounted) { setState(() { _pools = data; _isLoading = false; _hasMore = data.isNotEmpty; }); }
  }

  Future<void> _fetchMoreData() async {
    if (_isFetchingMore || !_hasMore) { return; }
    setState(() => _isFetchingMore = true);
    _currentPage++;
    final data = await _api.fetchPools(category: widget.category, page: _currentPage, rating: _selectedRating);
    if (mounted) { setState(() { if (data.isEmpty) { _hasMore = false; } else { _pools.addAll(data); } _isFetchingMore = false; }); }
  }

  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        MasonryGridView.builder(
          controller: _scrollController, padding: const EdgeInsets.all(8),
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4),
          mainAxisSpacing: 8, crossAxisSpacing: 8, itemCount: _pools.length,
          itemBuilder: (context, index) {
            final pool = _pools[index];
            final previewUrl = pool['preview_url'];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryResultScreen(tags: 'pool:${pool['id']}'))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (previewUrl != null && previewUrl.toString().isNotEmpty) CachedNetworkImage(imageUrl: previewUrl, fit: BoxFit.cover) else const Center(child: Icon(Icons.collections, size: 50, color: Colors.white24)),
                      Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black54, Colors.transparent, Colors.black87]))),
                      Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Row(children: [Text('${pool['post_count']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(width: 4), const Icon(Icons.image, size: 14, color: Colors.white)]))),
                      Positioned(bottom: 8, left: 8, right: 8, child: Text(pool['name'].replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_isFetchingMore) Positioned(bottom: 16.0, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.all(8.0), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)]), child: const CircularProgressIndicator()))),
      ],
    );
  }
}