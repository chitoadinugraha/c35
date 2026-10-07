import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_view.dart';
import 'package:alienai_c35/widgets/sites/io_site_handle_claim_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_menu_position.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum _SitePreviewNav { home, products, member }

class SitePreviewData {
  SitePreviewData({
    required this.siteIid,
    required this.alienId,
    required this.name,
    required this.url,
    this.theme = 'dark',
    this.doc = const {},
    this.previewToken = '',
    this.previewExpiresTsMs = 0,
  });

  final int siteIid;
  final String alienId;
  final String name;
  final String url;
  final String theme;
  final Map<String, dynamic> doc;
  final String previewToken;
  final int previewExpiresTsMs;

  String get slug {
    final aid = alienId.trim();
    if (aid.isEmpty || aid == siteIid.toString()) return siteIid.toString();
    return aid;
  }

  bool get showAtSlug {
    final aid = alienId.trim();
    return aid.isNotEmpty && aid != siteIid.toString();
  }

  String get handleLabel => showAtSlug ? '@$slug' : siteIid.toString();

  String get publicHostPath => url.isNotEmpty && !url.startsWith('http') ? url : 'alienai.id/$slug';

  String get publicPathLabel => publicHostPath.replaceFirst(RegExp(r'^https?://'), '');

  String get publicHttpsUrl {
    final path = publicHostPath.replaceFirst(RegExp(r'^https?://'), '');
    return 'https://$path';
  }

  SitePreviewData copyWith({String? alienId, String? url}) => SitePreviewData(
        siteIid: siteIid,
        alienId: alienId ?? this.alienId,
        name: name,
        url: url ?? this.url,
        theme: theme,
        doc: doc,
        previewToken: previewToken,
        previewExpiresTsMs: previewExpiresTsMs,
      );

  factory SitePreviewData.fromJson(Map<String, dynamic> json) {
    final iid = json['site_iid'] as int? ?? json['siteIid'] as int? ?? 0;
    final alienId = json['alien_id']?.toString() ?? json['alienId']?.toString() ?? '';
    final name = json['name']?.toString() ?? 'Website';
    final theme = json['theme']?.toString() ?? 'dark';
    final previewToken = json['preview_token']?.toString() ?? json['previewToken']?.toString() ?? '';
    final previewExpiresTsMs =
        json['preview_expires_ts_ms'] as int? ?? json['previewExpiresTsMs'] as int? ?? 0;
    final docRaw = json['doc'];
    final doc = docRaw is Map<String, dynamic>
        ? docRaw
        : (docRaw is String ? (jsonDecode(docRaw) as Map<String, dynamic>? ?? const {}) : const <String, dynamic>{});
    final slug = () {
      final aid = alienId.trim();
      if (aid.isEmpty || aid == iid.toString()) return iid.toString();
      return aid;
    }();
    final urlRaw = json['url']?.toString() ?? '';
    final url = urlRaw.isNotEmpty ? urlRaw : 'alienai.id/$slug';

    return SitePreviewData(
      siteIid: iid,
      alienId: alienId,
      name: name,
      url: url,
      theme: theme,
      doc: doc,
      previewToken: previewToken,
      previewExpiresTsMs: previewExpiresTsMs,
    );
  }

  bool get hasProductBlocks => blocks.any((b) {
        final t = b['type']?.toString() ?? '';
        return t == 'product_grid' || t == 'gallery';
      });

  List<Map<String, dynamic>> get blocks {
    final pages = doc['pages'];
    if (pages is List && pages.isNotEmpty) {
      final first = pages.first;
      if (first is Map<String, dynamic> && first['blocks'] is List) {
        return (first['blocks'] as List).whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  Color get accentColor {
    final t = doc['theme'];
    if (t is Map<String, dynamic> && t['accent'] != null) {
      final hex = t['accent'].toString().replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    switch (theme.toLowerCase()) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'midnight':
      case 'indigo':
        return const Color(0xFF6366F1);
      case 'sunset':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFFF97316); // Alien Orange
    }
  }
}

class UiSitePreviewCard extends StatefulWidget {
  const UiSitePreviewCard({
    super.key,
    required this.data,
    this.conn,
    this.initiallyExpanded = false,
  });

  final SitePreviewData data;
  final ChatConn? conn;
  final bool initiallyExpanded;

  @override
  State<UiSitePreviewCard> createState() => _UiSitePreviewCardState();
}

class _UiSitePreviewCardState extends State<UiSitePreviewCard> {
  late bool _expanded;
  late SitePreviewData _view;
  var _claimBusy = false;
  _SitePreviewNav _nav = _SitePreviewNav.home;
  String? _previewToken;
  int _previewExpiresTsMs = 0;
  final _previewScroll = ScrollController();
  final _blockKeys = <GlobalKey>[];
  final _memberSectionKey = GlobalKey();
  GuestSiteBoot? _boot;
  var _bootLoading = false;

  static const _cardBg = Color(0xFF141418);
  static const _canvasBg = Color(0xFF0D0D11);
  static const _border = Color(0xFF26262C);
  static const _textPrimary = Color(0xFFF4F4F5);
  static const _textSecondary = Color(0xFFA1A1AA);

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _view = widget.data;
    _previewToken = widget.data.previewToken.isNotEmpty ? widget.data.previewToken : null;
    _previewExpiresTsMs = widget.data.previewExpiresTsMs;
    _syncBlockKeys(widget.data.blocks.length);
    if (_expanded) _maybeLoadBoot();
  }

  @override
  void didUpdateWidget(covariant UiSitePreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.siteIid != widget.data.siteIid) {
      _view = widget.data;
      _previewToken = widget.data.previewToken.isNotEmpty ? widget.data.previewToken : null;
      _previewExpiresTsMs = widget.data.previewExpiresTsMs;
      _boot = null;
      _bootLoading = false;
    }
    if (oldWidget.conn != widget.conn && widget.conn != null && _expanded) {
      _boot = null;
      _maybeLoadBoot();
    }
    _syncBlockKeys(_previewBlocks.length);
  }

  SitePreviewData get _data => _view;

  GuestSiteBoot get _displayBoot => _boot ?? GuestSiteBoot.fromSiteDoc(
        siteIid: _data.siteIid,
        name: _data.name,
        alienId: _data.alienId,
        doc: _data.doc,
      );

  List<Map<String, dynamic>> get _previewBlocks => _displayBoot.homeBlocks;

  Color get _previewAccent => _displayBoot.accentColor;

  bool get _hasProductBlocks => _boot?.hasProductBlocks ?? _data.hasProductBlocks;

  void _maybeLoadBoot() {
    if (!_expanded || _bootLoading || _boot != null) return;
    final conn = widget.conn;
    if (conn == null) return;
    setState(() => _bootLoading = true);
    SiteApi(conn).bootGet(_data.siteIid).then((res) {
      final decoded = jsonDecode(res.bootJson);
      if (!mounted) return;
      if (decoded is! Map<String, dynamic>) throw StateError('invalid boot_json');
      final boot = GuestSiteBoot.fromJson(decoded);
      setState(() {
        _boot = boot;
        _bootLoading = false;
        _syncBlockKeys(boot.homeBlocks.length);
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _boot = null;
        _bootLoading = false;
        _syncBlockKeys(_data.blocks.length);
      });
    });
  }

  @override
  void dispose() {
    _previewScroll.dispose();
    super.dispose();
  }

  void _syncBlockKeys(int count) {
    while (_blockKeys.length < count) {
      _blockKeys.add(GlobalKey());
    }
    if (_blockKeys.length > count) {
      _blockKeys.removeRange(count, _blockKeys.length);
    }
  }

  bool _previewTokenValid() {
    final token = _previewToken;
    if (token == null || token.isEmpty) return false;
    if (_previewExpiresTsMs <= 0) return true;
    return DateTime.now().millisecondsSinceEpoch < _previewExpiresTsMs - 30000;
  }

  Future<String> _ensurePreviewToken() async {
    if (_previewTokenValid()) return _previewToken!;
    final conn = widget.conn;
    if (conn == null) throw StateError('Connect to refresh site preview');
    final res = await SiteApi(conn).sitePreviewToken(_data.siteIid);
    if (res.token.isEmpty) throw StateError('Preview token missing');
    if (!mounted) return res.token;
    setState(() {
      _previewToken = res.token;
      _previewExpiresTsMs = res.expiresTsMs.toInt();
    });
    return res.token;
  }

  Future<String> _draftPreviewUrl() async {
    final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
    final token = await _ensurePreviewToken();
    return '$origin/${_data.slug}?draft=1&ptoken=${Uri.encodeComponent(token)}';
  }

  Future<void> _claimOrChangeHandle(BuildContext context, {required bool isChange}) async {
    final picked = await ioSiteHandleClaimDialogOpen(
      context,
      siteName: _data.name,
      initialHandle: isChange ? _data.slug : siteAlienIdSlug(_data.name),
      isChange: isChange,
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    final conn = widget.conn;
    if (conn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save your site handle'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _claimBusy = true);
    try {
      final res = await SiteApi(conn).handlePut(_data.siteIid, picked);
      if (!mounted) return;
      setState(() {
        _view = _view.copyWith(alienId: res.alienId, url: res.url);
        _claimBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Handle claimed: @${res.alienId}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _claimBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _copyUrl(BuildContext context) {
    final u = _data.publicHttpsUrl;
    Clipboard.setData(ClipboardData(text: u));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL copied: $u'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareVisit(BuildContext context) async {
    try {
      final u = await _draftPreviewUrl();
      Clipboard.setData(ClipboardData(text: u));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft preview link copied'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open preview: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openSite(BuildContext context) async {
    try {
      final u = await _draftPreviewUrl();
      final uri = Uri.tryParse(u);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open preview: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToNav(_SitePreviewNav nav) {
    setState(() => _nav = nav);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (nav == _SitePreviewNav.home) {
        if (_previewScroll.hasClients) {
          _previewScroll.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
        }
        return;
      }
      final blocks = _previewBlocks;
      if (nav == _SitePreviewNav.products) {
        final targetIdx = blocks.indexWhere((b) {
          final t = b['type']?.toString() ?? '';
          return t == 'product_grid' || t == 'gallery';
        });
        if (targetIdx < 0 || targetIdx >= _blockKeys.length) return;
        final ctx = _blockKeys[targetIdx].currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
        return;
      }
      final memberCtx = _memberSectionKey.currentContext;
      if (memberCtx != null) {
        Scrollable.ensureVisible(
          memberCtx,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  PopupMenuItem<String> _siteMenuItem(String value, IconData icon, String label) => PopupMenuItem(
        value: value,
        height: 40,
        child: Row(
          children: [
            Icon(icon, size: 18, color: _textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );

  Future<void> _openSiteMenu(BuildContext anchorContext) async {
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final action = await showMenu<String>(
      context: anchorContext,
      color: _cardBg,
      position: uiMenuPositionBelow(anchorContext, box),
      items: [
        _siteMenuItem('visit', Icons.launch_rounded, 'Visit site'),
        _siteMenuItem('share', Icons.share_outlined, 'Share draft link'),
        _siteMenuItem('copy', Icons.link_rounded, 'Copy URL'),
        if (_data.showAtSlug)
          _siteMenuItem('handle', Icons.edit_outlined, 'Change handle')
        else
          _siteMenuItem('handle', Icons.badge_outlined, 'Claim handle'),
        const PopupMenuDivider(),
        _siteMenuItem('collapse', Icons.unfold_less_rounded, 'Minimize'),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'handle':
        if (!mounted) return;
        await _claimOrChangeHandle(context, isChange: _data.showAtSlug);
      case 'visit':
        if (!mounted) return;
        await _openSite(context);
      case 'share':
        if (!mounted) return;
        await _shareVisit(context);
      case 'copy':
        _copyUrl(context);
      case 'collapse':
        setState(() => _expanded = false);
    }
  }

  String _navLabel(_SitePreviewNav nav) => switch (nav) {
        _SitePreviewNav.home => 'Home',
        _SitePreviewNav.products => 'Products',
        _SitePreviewNav.member => 'Member area',
      };

  Future<void> _onPublicUrlTap(BuildContext context) async {
    if (!_data.showAtSlug) {
      await _claimOrChangeHandle(context, isChange: false);
      return;
    }
    _copyUrl(context);
  }

  Widget _publicUrlLink(BuildContext context, Color accent, {double fontSize = 11}) => GestureDetector(
        onTap: () => _onPublicUrlTap(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            _data.publicPathLabel,
            style: TextStyle(
              color: accent,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              decoration: _data.showAtSlug ? TextDecoration.none : TextDecoration.underline,
              decorationColor: accent.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

  Widget _sectionNavDropdown(Color accent) {
    final options = <_SitePreviewNav>[_SitePreviewNav.home];
    if (_hasProductBlocks) options.add(_SitePreviewNav.products);
    options.add(_SitePreviewNav.member);
    return PopupMenuButton<_SitePreviewNav>(
      tooltip: 'Jump to section',
      color: _cardBg,
      initialValue: _nav,
      onSelected: _scrollToNav,
      itemBuilder: (ctx) => options
          .map(
            (n) => PopupMenuItem(
              value: n,
              height: 36,
              child: Text(
                _navLabel(n),
                style: TextStyle(
                  color: n == _nav ? accent : _textPrimary,
                  fontSize: 13,
                  fontWeight: n == _nav ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _navLabel(_nav),
              style: const TextStyle(color: _textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 16, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: _expanded ? _buildExpanded(context) : _buildCollapsed(context),
      ),
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    final accent = _data.accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    setState(() => _expanded = true);
                    _maybeLoadBoot();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accent.withValues(alpha: 0.25)),
                        ),
                        child: Icon(Icons.language_rounded, size: 19, color: accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _data.name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 46),
                  child: _publicUrlLink(context, accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              setState(() => _expanded = true);
              _maybeLoadBoot();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Open',
                style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final accent = _previewAccent;
    final boot = _displayBoot;
    final blocks = boot.homeBlocks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.language_rounded, size: 15, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _data.name,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          _publicUrlLink(context, accent, fontSize: 10.5),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _sectionNavDropdown(accent),
              const SizedBox(width: 4),
              Builder(
                builder: (btnCtx) => IconButton(
                  tooltip: 'Options',
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  icon: const Icon(Icons.menu_rounded, color: _textPrimary),
                  onPressed: () => _openSiteMenu(btnCtx),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF101014),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border.withValues(alpha: 0.7)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _previewScroll,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (blocks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Empty Site Document',
                                style: TextStyle(color: _textSecondary.withValues(alpha: 0.7), fontSize: 13),
                              ),
                            ),
                          )
                        else
                          GuestSiteView(
                            boot: boot,
                            blockKeyAt: (i) => i < _blockKeys.length ? _blockKeys[i] : null,
                          ),
                        KeyedSubtree(
                          key: _memberSectionKey,
                          child: _buildMemberAreaMock(accent),
                        ),
                      ],
                    ),
                  ),
                  if (_bootLoading)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAreaMock(Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x15FFFFFF))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member area',
              style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to access member-only pages and perks.',
              style: TextStyle(color: _textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Sign in',
                style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

}
