import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/site/pos_link.dart';
import 'package:alienai_c35/pages/page_site_pos.dart';
import 'package:flutter/material.dart';

/// Opens POS when the app was launched from a POS shortcut / deep link.
class UiPosLinkHost extends StatefulWidget {
  const UiPosLinkHost({super.key, required this.chatConn, required this.child});

  final ChatConn chatConn;
  final Widget child;

  @override
  State<UiPosLinkHost> createState() => _UiPosLinkHostState();
}

class _UiPosLinkHostState extends State<UiPosLinkHost> {
  var _opening = false;

  @override
  void initState() {
    super.initState();
    PosLink.listen(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    PosLink.unlisten(_open);
    super.dispose();
  }

  void _open() {
    if (!mounted || _opening) return;
    final siteIid = PosLink.pending;
    if (siteIid == null || siteIid.isEmpty) return;
    PosLink.pending = null;
    _opening = true;
    unawaited(_go(siteIid));
  }

  Future<void> _go(String siteIid) async {
    try {
      if (!mounted) return;
      await sitePosOpen(context: context, chatConn: widget.chatConn, siteIid: siteIid);
    } finally {
      _opening = false;
      if (mounted) _open();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
