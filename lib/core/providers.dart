import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  String _rating = 'g';
  String _downloadPath = '';

  SettingsProvider(this._prefs) {
    _rating = _prefs.getString('content_rating') ?? 'g';
    _downloadPath = _prefs.getString('download_path') ?? '';
  }

  String get rating => _rating;
  String get downloadPath => _downloadPath;

  void setRating(String newRating) {
    _rating = newRating;
    _prefs.setString('content_rating', newRating);
    notifyListeners();
  }

  Future<void> setDownloadPath() async {
    final String? path = await FilePicker.getDirectoryPath();
    if (path != null) {
      _downloadPath = path;
      _prefs.setString('download_path', path);
      notifyListeners();
    }
  }
}

class SelectionProvider extends ChangeNotifier {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => _selectedIds;
  int get count => _selectedIds.length;

  void toggle(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void start(String id) {
    _isSelectionMode = true;
    _selectedIds.add(id);
    notifyListeners();
  }

  void clear() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  void selectAll(List<String> ids) {
    _selectedIds.addAll(ids);
    notifyListeners();
  }
}

class UserDataProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  List<String> _blacklist = [];
  List<String> _favoriteTags = [];
  List<String> _searchHistory = [];
  Map<String, dynamic> _bookmarks = {};

  UserDataProvider(this._prefs) {
    _blacklist = _prefs.getStringList('blacklist') ?? [];
    _favoriteTags = _prefs.getStringList('favorite_tags') ?? [];
    _searchHistory = _prefs.getStringList('search_history') ?? [];
    try {
      _bookmarks = jsonDecode(_prefs.getString('bookmarks') ?? '{}');
    } catch (_) {
      _bookmarks = {};
    }
  }

  List<String> get blacklist => _blacklist;
  List<String> get favoriteTags => _favoriteTags;
  List<String> get searchHistory => _searchHistory;
  List<dynamic> get bookmarkedPosts => _bookmarks.values.toList().reversed.toList();
  bool isBookmarked(String id) => _bookmarks.containsKey(id);

  void toggleBookmark(String id, dynamic postData) {
    if (_bookmarks.containsKey(id)) {
      _bookmarks.remove(id);
    } else {
      _bookmarks[id] = postData;
    }
    _prefs.setString('bookmarks', jsonEncode(_bookmarks));
    notifyListeners();
  }

  void removeBookmarkMultiple(Set<String> ids) {
    for (var id in ids) {
      _bookmarks.remove(id);
    }
    _prefs.setString('bookmarks', jsonEncode(_bookmarks));
    notifyListeners();
  }

  void toggleFavoriteTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty) { return; }
    if (_favoriteTags.contains(t)) {
      _favoriteTags.remove(t);
    } else {
      _favoriteTags.add(t);
    }
    _prefs.setStringList('favorite_tags', _favoriteTags);
    notifyListeners();
  }

  void addBlacklist(String tag) {
    final t = tag.trim();
    if (t.isNotEmpty && !_blacklist.contains(t)) {
      _blacklist.add(t);
      _prefs.setStringList('blacklist', _blacklist);
      notifyListeners();
    }
  }

  void removeBlacklist(String tag) {
    _blacklist.remove(tag);
    _prefs.setStringList('blacklist', _blacklist);
    notifyListeners();
  }

  void addSearchHistory(String tag) {
    final t = tag.trim();
    if (t.isNotEmpty) {
      _searchHistory.remove(t);
      _searchHistory.insert(0, t);
      if (_searchHistory.length > 20) {
        _searchHistory = _searchHistory.sublist(0, 20);
      }
      _prefs.setStringList('search_history', _searchHistory);
      notifyListeners();
    }
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    _prefs.setStringList('search_history', _searchHistory);
    notifyListeners();
  }

  Future<void> exportData() async {
    try {
      final data = {
        'blacklist': _blacklist,
        'favorite_tags': _favoriteTags,
        'bookmarks': _bookmarks,
        'search_history': _searchHistory,
      };
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/nekoview_backup.json');
      await file.writeAsString(jsonEncode(data));
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'NekoView Backup'),
      );
    } catch (e) {
      debugPrint("Export Error: $e");
    }
  }

  Future<void> importData() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString);

        if (data['blacklist'] != null) {
          _blacklist = List<String>.from(data['blacklist']);
        }
        if (data['favorite_tags'] != null) {
          _favoriteTags = List<String>.from(data['favorite_tags']);
        }
        if (data['bookmarks'] != null) {
          _bookmarks = Map<String, dynamic>.from(data['bookmarks']);
        }
        if (data['search_history'] != null) {
          _searchHistory = List<String>.from(data['search_history']);
        }

        await _prefs.setStringList('blacklist', _blacklist);
        await _prefs.setStringList('favorite_tags', _favoriteTags);
        await _prefs.setString('bookmarks', jsonEncode(_bookmarks));
        await _prefs.setStringList('search_history', _searchHistory);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Import Error: $e");
    }
  }

  Future<void> clearAllData() async {
    _bookmarks.clear();
    _blacklist.clear();
    _favoriteTags.clear();
    _searchHistory.clear();
    await _prefs.clear();
    notifyListeners();
  }
}