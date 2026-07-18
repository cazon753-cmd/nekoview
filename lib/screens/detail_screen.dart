import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers.dart';
import '../core/services.dart';
import 'menus_screen.dart';

class DetailScreen extends StatefulWidget {
  final int initialIndex;
  final List<dynamic> posts;
  final Future<void> Function() onFetchMore;

  const DetailScreen({super.key, required this.initialIndex, required this.posts, required this.onFetchMore});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;

  bool _isSlideshowActive = false;
  late AnimationController _slideshowController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _slideshowController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _slideshowController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_currentIndex < widget.posts.length - 1) {
          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        } else {
          widget.onFetchMore().then((_) {
            if (mounted) { setState(() {}); }
            if (_currentIndex < widget.posts.length - 1) {
              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            } else {
              _stopSlideshow();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideshowController.dispose();
    super.dispose();
  }

  void _startSlideshow() {
    setState(() {
      _isSlideshowActive = true;
      _showUI = false;
    });
    _slideshowController.forward(from: 0);
  }

  void _stopSlideshow() {
    setState(() {
      _isSlideshowActive = false;
      _showUI = true;
    });
    _slideshowController.stop();
  }

  Widget _buildTagSection(String title, String? tagString, Color color) {
    if (tagString == null || tagString.trim().isEmpty) { return const SizedBox(); }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tagString.split(' ').where((t) => t.isNotEmpty).map((tag) => GestureDetector(
            onTap: title == 'Artist' ? () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ArtistProfileScreen(artistName: tag)));
            } : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12)),
              child: Text(tag.replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final currentPost = widget.posts[_currentIndex];
    final String postId = currentPost['id'].toString();
    final bool isBookmarked = userData.isBookmarked(postId);
    final String currentImageUrl = currentPost['large_file_url'] ?? currentPost['file_url'] ?? currentPost['preview_file_url'] ?? '';
    final String characters = currentPost['tag_string_character'] ?? '';
    final String copyright = currentPost['tag_string_copyright'] ?? '';
    final String artist = currentPost['tag_string_artist'] ?? 'Unknown Artist';
    final String titleText = characters.isNotEmpty ? characters.split(' ').first.replaceAll('_', ' ') : (copyright.isNotEmpty ? copyright.split(' ').first.replaceAll('_', ' ') : 'Danbooru Post');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.posts.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              if (index >= widget.posts.length - 3) {
                widget.onFetchMore().then((_) {
                  if (mounted) { setState(() {}); }
                });
              }
              if (_isSlideshowActive) { _slideshowController.forward(from: 0); }
            },
            itemBuilder: (context, index) {
              final post = widget.posts[index];
              final imgUrl = post['file_url'] ?? post['large_file_url'] ?? post['preview_file_url'] ?? '';
              final hero = post['id'].toString();
              return ZoomableImage(
                imageUrl: imgUrl,
                heroTag: hero,
                onTap: () {
                  if (!_isSlideshowActive) { setState(() => _showUI = !_showUI); }
                },
              );
            },
          ),

          if (_isSlideshowActive)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _slideshowController,
                      builder: (context, child) => LinearProgressIndicator(
                        value: _slideshowController.value,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 32, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                        onPressed: _stopSlideshow,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isSlideshowActive)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              top: _showUI ? 0 : -100, left: 0, right: 0,
              child: AppBar(
                backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(icon: const Icon(Icons.play_circle_outline_rounded), onPressed: _startSlideshow, tooltip: "Slideshow"),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Post Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ListTile(leading: const Icon(Icons.image), title: const Text('Resolution'), subtitle: Text('${currentPost['image_width'] ?? '?'} x ${currentPost['image_height'] ?? '?'}')),
                              ListTile(leading: const Icon(Icons.source), title: const Text('Source'), subtitle: Text(currentPost['source'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ListTile(leading: const Icon(Icons.security), title: const Text('Rating'), subtitle: Text(currentPost['rating']?.toString().toUpperCase() ?? 'G')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isSlideshowActive)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: _showUI ? 0 : -250, left: 0, right: 0,
              child: IgnorePointer(
                ignoring: !_showUI,
                child: Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87, Colors.black]),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(titleText.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(copyright.isNotEmpty ? copyright.replaceAll('_', ' ') : 'Original', style: TextStyle(fontSize: 14, color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArtistProfileScreen(artistName: artist.split(' ').first))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red[900]?.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                                child: Text(artist.split(' ').first.replaceAll('_', ' '), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(currentPost['created_at']?.split('T').first ?? 'Unknown', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: Colors.white),
                              onPressed: () => userData.toggleBookmark(postId, currentPost),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded, color: Colors.white),
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading...')));
                                bool success = await downloadImage(currentImageUrl, customPath: settings.downloadPath);
                                if (!context.mounted) { return; }
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Saved!' : 'Failed')));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, color: Colors.white),
                              onPressed: () => SharePlus.instance.share(
                                ShareParams(text: 'https://danbooru.donmai.us/posts/$postId'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                builder: (_) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.tag), title: const Text('View Tags'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          showModalBottomSheet(
                                            context: context, isScrollControlled: true,
                                            builder: (_) => SafeArea(
                                              child: Container(
                                                padding: const EdgeInsets.all(20.0), height: MediaQuery.of(context).size.height * 0.6,
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('Tags', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 16),
                                                      _buildTagSection('Artist', currentPost['tag_string_artist'], Colors.red[900]!),
                                                      _buildTagSection('Copyright', currentPost['tag_string_copyright'], Colors.purple[900]!),
                                                      _buildTagSection('Character', currentPost['tag_string_character'], Colors.green[900]!),
                                                      _buildTagSection('General', currentPost['tag_string_general'], Colors.blue[900]!),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(leading: const Icon(Icons.open_in_browser), title: const Text('View in Browser'), onTap: () => launchUrl(Uri.parse('https://danbooru.donmai.us/posts/$postId'))),
                                      ListTile(leading: const Icon(Icons.comment), title: const Text('Comments'), onTap: () => launchUrl(Uri.parse('https://danbooru.donmai.us/posts/$postId#comments'))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
  }
}

class ZoomableImage extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final VoidCallback onTap;

  const ZoomableImage({super.key, required this.imageUrl, required this.heroTag, required this.onTap});

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() => _transformationController.value = _animation!.value);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) => _doubleTapDetails = details;

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _animation = Matrix4Tween(begin: _transformationController.value, end: Matrix4.identity()).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
    } else {
      final position = _doubleTapDetails!.localPosition;
      const double scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);
      
      final zoomed = Matrix4.identity()
        ..translateByDouble(x, y, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
      _animation = Matrix4Tween(begin: _transformationController.value, end: zoomed).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
    }
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap, onDoubleTapDown: _handleDoubleTapDown, onDoubleTap: _handleDoubleTap,
      child: SizedBox.expand(
        child: InteractiveViewer(
          transformationController: _transformationController, minScale: 1.0, maxScale: 4.0,
          child: Center(
            child: Hero(
              tag: widget.heroTag,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl, fit: BoxFit.contain, width: double.infinity, height: double.infinity,
                placeholder: (c, u) => const Center(child: SizedBox(width: 48, height: 48, child: CircularProgressIndicator(color: Colors.white54))),
                errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}