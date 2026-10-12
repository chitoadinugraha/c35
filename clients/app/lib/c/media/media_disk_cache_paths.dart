import 'package:path_provider/path_provider.dart';

Future<String> mediaDiskCacheApplicationDir() async {
  final base = await getApplicationCacheDirectory();
  return base.path;
}
