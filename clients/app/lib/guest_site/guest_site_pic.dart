/// Resolves site media paths the same way guest HTML / server `pic_url` does.
String guestSitePicUrl(String pic) {
  final p = pic.trim();
  if (p.isEmpty) return '';
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  if (p.startsWith('/fs/')) return 'https://f.alienai.id$p';
  return 'https://f.alienai.id/fs/$p?v=thumb';
}
