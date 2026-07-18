import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io' show Platform, File, Directory;
import 'dart:typed_data';

Future<bool> downloadImage(String url, {String customPath = ''}) async {
  try {
    final response = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data);
    final fileName = "nekoview_${DateTime.now().millisecondsSinceEpoch}.jpg";

    if (customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return true;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(bytes);
        await Gal.putImage(tempFile.path, album: 'NekoView');
        return true;
      } catch (e) {
        debugPrint('Gallery save error: $e');
      }
      return false;
    } else {
      final dir = await getDownloadsDirectory();
      if (dir != null) {
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        return true;
      }
    }
  } catch (e) {
    debugPrint('Download error: $e');
  }
  return false;
}

class DanbooruService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://danbooru.donmai.us/'));

  String buildRatingTag(String rating) {
    switch (rating) {
      case 'g': return 'rating:g';
      case 's': return 'rating:s';
      case 'q': return 'rating:q';
      case 'e': return 'rating:e';
      default: return '';
    }
  }

  Future<List<dynamic>> fetchPosts({String tags = '', int page = 1, required String rating}) async {
    try {
      String finalTags = tags.trim();
      final ratingTag = buildRatingTag(rating);
      if (ratingTag.isNotEmpty && !finalTags.contains('rating:')) {
        finalTags = finalTags.isEmpty ? ratingTag : '$finalTags $ratingTag';
      }
      final response = await _dio.get(
        'posts.json',
        queryParameters: {'tags': finalTags, 'page': page, 'limit': 30},
      );
      return response.data;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> fetchTags(String query) async {
    try {
      final response = await _dio.get(
        'tags.json',
        queryParameters: {
          'search[name_matches]': '*$query*',
          'limit': 10,
          'search[order]': 'count',
        },
      );
      return response.data;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> fetchTrendingTags() async {
    try {
      final response = await _dio.get(
        'tags.json',
        queryParameters: {'search[order]': 'count', 'limit': 20},
      );
      return response.data;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchArtist(String name) async {
    try {
      final response = await _dio.get(
        'artists.json',
        queryParameters: {'search[any_name_matches]': name},
      );
      if (response.data.isNotEmpty) {
        return response.data[0];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> fetchPools({int page = 1, String category = 'series', required String rating}) async {
    try {
      final response = await _dio.get(
        'pools.json',
        queryParameters: {
          'search[category]': category,
          'page': page,
          'limit': 20,
        },
      );
      List<dynamic> pools = response.data;

      List<String> firstPostIds = [];
      for (var pool in pools) {
        if (pool['post_ids'] != null && (pool['post_ids'] as List).isNotEmpty) {
          firstPostIds.add(pool['post_ids'][0].toString());
        }
      }

      if (firstPostIds.isNotEmpty) {
        final ratingTag = buildRatingTag(rating);
        final tags = ratingTag.isEmpty ? 'id:${firstPostIds.join(',')}' : 'id:${firstPostIds.join(',')} $ratingTag';
        final postsResponse = await _dio.get('posts.json', queryParameters: {'tags': tags});
        List<dynamic> posts = postsResponse.data;
        Map<String, String> idToPreview = {};
        for (var post in posts) {
          idToPreview[post['id'].toString()] = post['preview_file_url'] ?? post['file_url'] ?? '';
        }
        for (var pool in pools) {
          if (pool['post_ids'] != null && (pool['post_ids'] as List).isNotEmpty) {
            pool['preview_url'] = idToPreview[pool['post_ids'][0].toString()];
          }
        }
      }
      return pools;
    } catch (_) {
      return [];
    }
  }
}