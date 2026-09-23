import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/pb/c35/admin.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF18181B);
const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _hover = Color(0xFF27272A);
const _accent = Color(0xFF34D399);

class IoAdminUserPick extends StatefulWidget {
  const IoAdminUserPick({
    super.key,
    required this.api,
    this.value,
    this.onChanged,
    this.width = 220,
  });

  final AdminApi api;
  final AdminUserHit? value;
  final ValueChanged<AdminUserHit?>? onChanged;
  final double width;

  @override
  State<IoAdminUserPick> createState() => _IoAdminUserPickState();
}

class _IoAdminUserPickState extends State<IoAdminUserPick> {
  final _ctrl = TextEditingController();
  var _hits = <AdminUserHit>[];
  var _open = false;
  var _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _hits = [];
        _open = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final hits = await widget.api.userSearch(query, limit: 12);
      if (!mounted) return;
      setState(() {
        _hits = hits;
        _open = hits.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _pick(AdminUserHit hit) {
    _ctrl.clear();
    setState(() {
      _open = false;
      _hits = [];
    });
    widget.onChanged?.call(hit);
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _open = false;
      _hits = [];
    });
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value;
    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selected != null)
            Material(
              color: _hover,
              borderRadius: BorderRadius.circular(8),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: UiUserAvatar(name: selected.name, email: selected.email, handle: selected.handle, pic: selected.avatarUrl, size: 28),
                title: Text(selected.name.isNotEmpty ? selected.name : selected.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 12)),
                trailing: IconButton(icon: const Icon(Icons.close, size: 16, color: _muted), onPressed: _clear),
              ),
            )
          else
            TextField(
              controller: _ctrl,
              style: const TextStyle(color: _text, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'User search',
                hintStyle: const TextStyle(color: _muted, fontSize: 13),
                prefixIcon: _loading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))) : const Icon(Icons.person_search_outlined, size: 18, color: _muted),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent)),
              ),
              onChanged: _search,
            ),
          if (_open && _hits.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _hits.length,
                itemBuilder: (context, i) {
                  final hit = _hits[i];
                  return ListTile(
                    dense: true,
                    leading: UiUserAvatar(name: hit.name, email: hit.email, handle: hit.handle, pic: hit.avatarUrl, size: 24),
                    title: Text(hit.name.isNotEmpty ? hit.name : hit.email, style: const TextStyle(color: _text, fontSize: 12)),
                    subtitle: hit.handle.isNotEmpty ? Text(hit.handle, style: const TextStyle(color: _muted, fontSize: 11)) : null,
                    onTap: () => _pick(hit),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
