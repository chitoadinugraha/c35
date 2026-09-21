import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_forest.dart';
import 'package:alienai_c35/c/referral/referral_shares.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_forest_chart.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_code_list.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_user_profile_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PageReferralTree extends StatefulWidget {
  const PageReferralTree({super.key, required this.conn, required this.viewerId});

  final ReferralConn conn;
  final int viewerId;

  @override
  State<PageReferralTree> createState() => _PageReferralTreeState();
}

class _PageReferralTreeState extends State<PageReferralTree> {
  static const _bg = Color(0xFF08080A);
  static const _accent = Color(0xFF22C55E);

  late final UiReferralForestController _forestCtrl = UiReferralForestController();
  var _loading = true;
  var _loadBusy = false;
  String? _error;
  List<ReferralTreeNode> _nodes = [];
  Map<String, int> _percentages = {};
  var _expandingId = 0;
  late var _rootId = _initialRootId;
  var _focusId = 0;
  var _searchOpen = false;
  String _searchQuery = '';
  var _searchMatchIndex = 0;
  late final _searchCtrl = TextEditingController();
  late final _searchFocus = FocusNode();

  int get _initialRootId => referralTreeWideAccess(viewerId: widget.viewerId, nodes: const []) ? 0 : widget.viewerId;

  bool get _wideAccess => referralTreeWideAccess(viewerId: widget.viewerId, nodes: _nodes);

  void _applySlice(ReferralTreeSlice slice) {
    final shareResult = referralSharesFromBranchList(slice.nodes, slice.branchShares);
    setState(() {
      _nodes = List<ReferralTreeNode>.from(slice.nodes);
      _percentages = shareResult.shares;
    });
  }

  void _mergeSlice(ReferralTreeSlice incoming) {
    final merged = referralTreeSliceMerge(
      ReferralTreeSlice(
        nodes: _nodes,
        branchShares: _percentages.entries.map((e) {
          final parts = e.key.split(':');
          return ReferralShareDoc(parentUid: Int64(int.parse(parts[0])), childUid: Int64(int.parse(parts[1])), sharePercent: e.value);
        }),
      ),
      incoming,
    );
    final shareResult = referralSharesFromBranchList(merged.nodes, merged.branchShares);
    setState(() {
      _nodes = List<ReferralTreeNode>.from(merged.nodes);
      _percentages = shareResult.shares;
    });
  }

  Future<ReferralTreeSlice> _treeGet({required int rootId, int depth = 2}) async {
    final res = await widget.conn.invoke(
      InvokeReq(
        reqId: const Uuid().v4(),
        referralTreeGet: ReqReferralTreeGet(rootId: Int64(rootId), depth: depth),
      ),
      timeout: const Duration(seconds: 8),
    );
    invokeResThrow(res, fallback: 'Failed to load referral tree');
    if (!res.hasReferralTreeGet()) throw 'No referral tree data';
    return res.referralTreeGet.slice;
  }

  Future<void> _setPercent(int parentId, int childId, int value) async {
    if (!_wideAccess && parentId != widget.viewerId) return;
    final result = referralShareSet(referralForestFromAccounts(_nodes), _percentages, parentId, childId, value);
    for (final edge in result.changed) {
      final res = await widget.conn.invoke(InvokeReq(
        reqId: const Uuid().v4(),
        referralShareSet: ReqReferralShareSet(parentUid: Int64(edge.parentId), childUid: Int64(edge.childId), sharePercent: edge.sharePercent),
      ));
      invokeResThrow(res, fallback: 'Failed to save share');
    }
    if (!mounted) return;
    setState(() => _percentages = result.shares);
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    serverHostTick.addListener(_onServerHostChanged);
    _load(rootId: _rootId);
  }

  void _onServerHostChanged() {
    if (!mounted) return;
    setState(() {
      _nodes = [];
      _percentages = {};
      _error = null;
      _loading = true;
      _rootId = _initialRootId;
    });
    _load(rootId: _rootId);
  }

  @override
  void dispose() {
    serverHostTick.removeListener(_onServerHostChanged);
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _searchQuery) return;
    setState(() => _searchQuery = q);
    if (q.isEmpty) {
      setState(() {
        _searchMatchIndex = 0;
        _focusId = 0;
      });
      return;
    }
    _focusSearchMatch(0);
  }

  List<int> get _searchMatchIds {
    if (_searchQuery.isEmpty) return [];
    final lower = _searchQuery.toLowerCase();
    final layout = referralForestLayout(referralForestFromAccounts(_nodes), canExpand: (_) => false);
    return [
      for (final node in layout.nodes)
        if (node.name.toLowerCase().contains(lower) || node.displayHandle.toLowerCase().contains(lower)) node.id,
    ];
  }

  void _focusSearchMatch(int index) {
    final matches = _searchMatchIds;
    if (matches.isEmpty) {
      setState(() {
        _searchMatchIndex = 0;
        _focusId = 0;
      });
      return;
    }
    final i = index.clamp(0, matches.length - 1);
    final id = matches[i];
    setState(() {
      _searchMatchIndex = i;
      _focusId = id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _forestCtrl.centerOnUser(id);
    });
  }

  void _searchPrev() {
    final matches = _searchMatchIds;
    if (matches.length <= 1) return;
    _focusSearchMatch((_searchMatchIndex - 1 + matches.length) % matches.length);
  }

  void _searchNext() {
    final matches = _searchMatchIds;
    if (matches.length <= 1) return;
    _focusSearchMatch((_searchMatchIndex + 1) % matches.length);
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchOpen = false;
      _searchQuery = '';
      _searchMatchIndex = 0;
      _focusId = 0;
    });
  }

  Widget _searchTitle() => DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Search by name…',
                  hintStyle: TextStyle(color: Color(0xFF71717A)),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF71717A), size: 22),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              _SearchNavButton(tooltip: 'Previous match', icon: Icons.chevron_left_rounded, onPressed: _searchMatchIds.length > 1 ? _searchPrev : null),
              Text(
                _searchMatchIds.isEmpty ? '0 / 0' : '${_searchMatchIndex + 1} / ${_searchMatchIds.length}',
                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
              ),
              _SearchNavButton(tooltip: 'Next match', icon: Icons.chevron_right_rounded, onPressed: _searchMatchIds.length > 1 ? _searchNext : null),
            ],
            uiIconButton(
              tooltip: _searchQuery.isNotEmpty ? 'Clear' : 'Close search',
              icon: const Icon(Icons.close_rounded, color: Color(0xFF71717A), size: 20),
              onPressed: _searchQuery.isNotEmpty
                  ? () {
                      _searchCtrl.clear();
                      _searchFocus.requestFocus();
                    }
                  : _closeSearch,
            ),
          ],
        ),
      );

  Widget _pageTrailing(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_searchOpen) uiIconButton(tooltip: 'Search', onPressed: _openSearch, icon: const Icon(Icons.search_rounded)),
          uiIconButton(
            tooltip: 'Refresh',
            onPressed: _loadBusy
                ? null
                : () {
                    setState(() {
                      _rootId = 0;
                      _focusId = 0;
                    });
                    _load(rootId: 0);
                  },
            icon: _loadBusy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
                : const Icon(Icons.refresh),
          ),
          uiIconButton(tooltip: 'Referral codes', onPressed: () => referralCodeListDialog(context, conn: widget.conn), icon: const Icon(Icons.confirmation_number_outlined)),
        ],
      );

  Set<int>? get _searchMatchIdSet => _searchQuery.isEmpty ? null : _searchMatchIds.toSet();

  Future<void> _load({int? rootId}) async {
    final loadRoot = rootId ?? _rootId;
    setState(() {
      _loadBusy = true;
      if (_nodes.isEmpty) {
        _loading = true;
        _error = null;
      }
    });
    try {
      final slice = await _treeGet(rootId: loadRoot, depth: 2);
      if (!mounted) return;
      _applySlice(slice);
      setState(() {
        _rootId = loadRoot;
        _loading = false;
        _loadBusy = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = uiReferralError(e, fallback: 'Failed to load referral tree');
        _loading = false;
        _loadBusy = false;
      });
    }
  }

  Future<void> _expand(int parentId) async {
    if (_expandingId != 0) return;
    setState(() {
      _expandingId = parentId;
      _error = null;
    });
    try {
      _mergeSlice(await _treeGet(rootId: parentId, depth: 1));
    } catch (e) {
      if (mounted) setState(() => _error = uiReferralError(e, fallback: 'Failed to load referral tree'));
    }
    if (mounted) setState(() => _expandingId = 0);
  }

  ReferralTreeNode? _referrerOf(ReferralTreeNode node) {
    if (node.parentId <= 0) return null;
    for (final n in _nodes) {
      if (n.id == node.parentId) return n;
    }
    return null;
  }

  Future<void> _openProfile(ReferralTreeNode node) async {
    final result = await referralUserProfileDialog(
      context,
      conn: widget.conn,
      node: node,
      isSelf: node.id == widget.viewerId,
      viewerIsRoot: _wideAccess,
      referrer: _referrerOf(node),
      onOpenReferrer: _openProfile,
      onFocus: () {
        setState(() => _focusId = node.id);
        _forestCtrl.centerOnUser(node.id);
      },
    );
    if (!mounted || result == null) return;
    if (result.reloadTree) {
      await _load(rootId: _rootId == 0 ? null : _rootId);
      return;
    }
    final updated = result.node;
    if (updated != null) {
      setState(() => _nodes = _nodes.map((n) => n.id == updated.id ? updated : n).toList());
    }
  }

  @override
  Widget build(BuildContext context) => UiPage(
        title: 'Referral tree',
        onBack: () => Navigator.pop(context),
        titleWidget: _searchOpen ? _searchTitle() : null,
        trailing: _pageTrailing(context),
        backgroundColor: _bg,
        body: Stack(
          children: [
            if (_loading && _nodes.isEmpty)
              const UILoading(message: 'Loading referral tree…')
            else if (_error != null && _nodes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFF87171)),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA1A1AA))),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else ...[
              UiReferralForestChart(
                nodes: _nodes,
                currentId: widget.viewerId,
                percentages: _percentages,
                searchMatchIds: _searchMatchIdSet,
                viewerIsRoot: _wideAccess,
                expandingId: _expandingId == 0 ? null : _expandingId,
                focusId: _searchQuery.isNotEmpty && _focusId != 0 ? _focusId : (_focusId == 0 ? widget.viewerId : _focusId),
                controller: _forestCtrl,
                onExpand: _expand,
                onPercentChange: _setPercent,
                onNodeTap: _openProfile,
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: Material(
                  color: const Color(0xFF18181B).withValues(alpha: 0.94),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF3F3F46), width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      uiIconButton(tooltip: 'Center on me',
                        onPressed: () => _forestCtrl.centerOnUser(widget.viewerId),
                        icon: const Icon(Icons.my_location_rounded, size: 20, color: _accent),
                      ),
                      Container(width: 1, height: 20, color: const Color(0xFF27272A)),
                      uiIconButton(tooltip: 'View entire tree',
                        onPressed: _loadBusy
                            ? null
                            : () async {
                                if (_rootId != 0) {
                                  setState(() {
                                    _rootId = 0;
                                    _focusId = 0;
                                  });
                                  await _load(rootId: 0);
                                }
                                if (mounted) _forestCtrl.fitEntireTree();
                              },
                        icon: const Icon(Icons.filter_center_focus_rounded, size: 20, color: Color(0xFFA1A1AA)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null && _nodes.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                top: 8,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF450A0A),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 20, color: Color(0xFFF87171)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFECACA), fontSize: 13))),
                        uiIconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: 'Retry',
                          onPressed: _loadBusy ? null : _load,
                          icon: const Icon(Icons.refresh, size: 20, color: Color(0xFFFECACA)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _SearchNavButton extends StatelessWidget {
  const _SearchNavButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => uiIconButton(tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        icon: Icon(icon, size: 20, color: onPressed == null ? const Color(0xFF52525B) : const Color(0xFF71717A)),
      );
}
