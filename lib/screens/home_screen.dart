import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../core/providers.dart';
import '../widgets/gallery_grid.dart';
import 'menus_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearchBarVisible = true;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      drawer: const AppDrawer(),
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
              key: ValueKey(Provider.of<SettingsProvider>(context).rating),
              tags: '',
              padding: const EdgeInsets.only(top: 90, bottom: 20, left: 8, right: 8),
            ),
          ),
          Consumer<SelectionProvider>(
            builder: (ctx, selection, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                top: (selection.isSelectionMode || !_isSearchBarVisible) ? -100 : 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Builder(
                      builder: (ctx2) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            ctx2,
                            MaterialPageRoute(builder: (_) => const TagSearchScreen()),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.menu_rounded, color: Theme.of(context).colorScheme.onSurface),
                                      onPressed: () => Scaffold.of(ctx2).openDrawer(),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Search tags...',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}