import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_post_media.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty media_json yields no paths', () {
    final post = SitePost();
    expect(sitePostMediaPaths(post), isEmpty);
    expect(sitePostThumbFromPaths([]), '');
  });

  test('encode and parse round-trip', () {
    const paths = ['f/a.jpg', 'f/b.jpg'];
    final json = sitePostMediaEncode(paths);
    expect(sitePostMediaPathsParse(json), paths);
    expect(sitePostThumbFromPaths(paths), 'f/a.jpg');
  });

  test('sitePostWithMedia sets thumb from first image', () {
    final post = sitePostWithMedia(SitePost(title: 't'), ['x/1', 'x/2']);
    expect(post.thumb, 'x/1');
    expect(sitePostMediaPaths(post), ['x/1', 'x/2']);
  });

  test('invalid json parses as empty', () {
    expect(sitePostMediaPathsParse('{'), isEmpty);
  });
}
