import 'package:flutter_test/flutter_test.dart';
import 'package:nekoview/core/services.dart';

void main() {
  test('buildRatingTag maps content ratings for pools', () {
    final service = DanbooruService();

    expect(service.buildRatingTag('all'), isEmpty);
    expect(service.buildRatingTag('g'), 'rating:g');
    expect(service.buildRatingTag('s'), 'rating:s');
    expect(service.buildRatingTag('q'), 'rating:q');
    expect(service.buildRatingTag('e'), 'rating:e');
  });
}