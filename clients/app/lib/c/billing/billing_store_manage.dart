import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

const _playPackage = 'id.alienai';

/// Opens the platform subscription management page (recurring native store plans).
Future<bool> billingStoreManageSubscriptions() async {
  if (kIsWeb) return false;
  final Uri uri;
  if (Platform.isAndroid) {
    uri = Uri.parse('https://play.google.com/store/account/subscriptions?package=$_playPackage');
  } else if (Platform.isIOS) {
    uri = Uri.parse('https://apps.apple.com/account/subscriptions');
  } else {
    return false;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
