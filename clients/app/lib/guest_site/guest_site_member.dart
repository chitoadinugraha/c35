import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/site/guest_assistant_api.dart';
import 'package:alienai_c35/c/site/guest_member_api.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:alienai_c35/guest_site/guest_site_modal.dart';
import 'package:flutter/material.dart';

bool guestSiteMemberPortalEnabled(Map<String, dynamic> capabilities) {
  if (capabilities['member_portal'] is bool) {
    return capabilities['member_portal'] as bool;
  }
  final commerce = capabilities['commerce'];
  if (commerce is bool) return commerce;
  return true;
}

Future<void> guestSiteShowMemberPortal({
  required BuildContext context,
  required int siteIid,
  required Color accent,
  void Function(int txId)? onOpenOrder,
}) async {
  final signedIn = sessionAuthToken().isNotEmpty;
  await guestSiteShowModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF18181B),
    builder: (ctx) => _GuestMemberPortalSheet(
      siteIid: siteIid,
      accent: accent,
      signedIn: signedIn,
      onOpenOrder: onOpenOrder,
    ),
  );
}

class _GuestMemberPortalSheet extends StatefulWidget {
  const _GuestMemberPortalSheet({
    required this.siteIid,
    required this.accent,
    required this.signedIn,
    this.onOpenOrder,
  });

  final int siteIid;
  final Color accent;
  final bool signedIn;
  final void Function(int txId)? onOpenOrder;

  @override
  State<_GuestMemberPortalSheet> createState() => _GuestMemberPortalSheetState();
}

class _GuestMemberPortalSheetState extends State<_GuestMemberPortalSheet> {
  GuestMemberProfile? _profile;
  List<GuestMemberOrderSummary> _serverOrders = [];
  List<Map<String, dynamic>> _localOrders = [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _localOrders = await GuestSiteMemberStore.ordersList(widget.siteIid);
      if (widget.signedIn) {
        _profile = await GuestMemberApi.me(siteIid: widget.siteIid);
        final visitorId = await GuestAssistantApi.visitorIdForSite(widget.siteIid);
        final ids = _localOrders.map((e) => (e['tx_id'] as num?)?.toInt() ?? 0).where((id) => id > 0).toList();
        if (ids.isNotEmpty) {
          await GuestMemberApi.merge(siteIid: widget.siteIid, visitorId: visitorId, orderIds: ids);
        }
        _serverOrders = await GuestMemberApi.orderList(siteIid: widget.siteIid);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (!widget.signedIn)
              Text(
                'Masuk dengan akun Alien untuk melihat pesanan di semua perangkat.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))
            else ...[
              if (_profile != null)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _profile!.pic.isNotEmpty ? NetworkImage(_profile!.pic) : null,
                    child: _profile!.pic.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(_profile!.displayName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(_profile!.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              const Text('Pesanan saya', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(child: _ordersList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ordersList() {
    final orders = widget.signedIn && _serverOrders.isNotEmpty
        ? _serverOrders
        : _localOrders
            .map(
              (o) => GuestMemberOrderSummary(
                txId: (o['tx_id'] as num?)?.toInt() ?? 0,
                state: '',
                total: (o['total'] as num?)?.toInt() ?? 0,
                progressLabel: '',
              ),
            )
            .toList();
    if (orders.isEmpty) {
      return const Text('Belum ada pesanan', style: TextStyle(color: Colors.white54));
    }
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final o = orders[i];
        return ListTile(
          title: Text('#${o.txId}', style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            o.progressLabel.isNotEmpty ? o.progressLabel : 'IDR ${o.total}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          onTap: o.txId > 0 ? () => widget.onOpenOrder?.call(o.txId) : null,
        );
      },
    );
  }
}
