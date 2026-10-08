import 'package:alienai_c35/c/media/media_disk_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mediaUrlResolve keeps absolute http', () {
    expect(mediaUrlResolve('https://cdn.example/a.png'), 'https://cdn.example/a.png');
  });

  test('mediaUrlResolve joins relative paths to auth base', () {
    expect(mediaUrlResolve('/fs/abc'), contains('/fs/abc'));
  });

  test('mediaDiskCacheKey is stable', () {
    final a = mediaDiskCacheKey('https://example.com/x');
    final b = mediaDiskCacheKey('https://example.com/x');
    expect(a, b);
    expect(a.length, greaterThan(10));
  });
}
