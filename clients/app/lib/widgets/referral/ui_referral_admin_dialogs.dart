import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/admin.pb.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

Future<AdminUserHit?> referralAdminReferredByDialog(
  BuildContext context, {
  required ReferralConn conn,
  required ReferralTreeNode target,
}) =>
    showDialog<AdminUserHit>(
      context: context,
      builder: (ctx) => _ReferralReferredByDialog(conn: conn, target: target),
    );

class _ReferralReferredByDialog extends StatefulWidget {
  const _ReferralReferredByDialog({required this.conn, required this.target});

  final ReferralConn conn;
  final ReferralTreeNode target;

  @override
  State<_ReferralReferredByDialog> createState() => _ReferralReferredByDialogState();
}

class _ReferralReferredByDialogState extends State<_ReferralReferredByDialog> {
  static const _bg = Color(0xFF18181B);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);
  static const _accent = Color(0xFF22C55E);

  late final _queryCtrl = TextEditingController();
  late final AdminApi _admin = AdminApi(widget.conn);
  Timer? _debounce;
  var _searching = false;
  var _loading = false;
  var _error = '';
  List<AdminUserHit> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
        _error = '';
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    try {
      final hits = await _admin.userSearch(q, limit: 20);
      if (!mounted) return;
      setState(() {
        _results = hits.where((h) => h.identityId.toInt() != widget.target.identityId.toInt()).toList();
        _searching = false;
        _error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = uiReferralError(e, fallback: 'Could not save changes.');
      });
    }
  }

  Future<void> _select(AdminUserHit hit) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await _admin.userPut(targetId: widget.target.identityId.toInt(), referredByUid: hit.identityId.toInt());
      if (!mounted) return;
      Navigator.pop(context, hit);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiReferralError(e, fallback: 'Could not save changes.');
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: _bg,
        title: Text('Set referred by', style: const TextStyle(color: _text)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Target: ${widget.target.name}', style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 10),
              TextField(
                controller: _queryCtrl,
                autofocus: true,
                style: const TextStyle(color: _text),
                decoration: UiInputDecoration.of(context, labelText: 'Search user', hintText: 'Name, handle, or email'),
                onChanged: _onQueryChanged,
              ),
              const SizedBox(height: 10),
              if (_searching) const UILoading(message: 'Searching…'),
              if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
              if (!_searching && _results.isEmpty && _queryCtrl.text.trim().isNotEmpty)
                const Text('No users found', style: TextStyle(color: _muted, fontSize: 13)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (ctx, i) {
                    final hit = _results[i];
                    return ListTile(
                      dense: true,
                      leading: UiUserAvatar(name: hit.name, handle: hit.handle, pic: hit.avatarUrl, size: 28, showBorder: false),
                      title: Text(hit.name, style: const TextStyle(color: _text, fontSize: 14)),
                      subtitle: Text(
                        hit.handle.isNotEmpty ? hit.handle : hit.email,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                      onTap: _loading ? null : () => _select(hit),
                    );
                  },
                ),
              ),
              if (_loading) const Padding(padding: EdgeInsets.only(top: 8), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      );
}
