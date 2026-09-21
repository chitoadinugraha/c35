import 'package:alienai_c35/c/device/device_store.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/widgets/devices/ui_remote_device.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

class UiDeviceDetail extends StatelessWidget {
  const UiDeviceDetail({super.key, required this.row});

  final IdentityListRow row;

  @override
  Widget build(BuildContext context) {
    final id = row.identity;
    final kind = id.kind.toLowerCase();
    final tabs = kind == 'iot'
        ? const ['Control', 'Wiring']
        : const ['Remote', 'Task', 'Skill', 'Settings'];
    return DefaultTabController(
      length: tabs.length,
      child: ColoredBox(
        color: const Color(0xFF08080A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(id.name.isNotEmpty ? id.name : id.type, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: _text,
              unselectedLabelColor: _muted,
              indicatorColor: const Color(0xFF34D399),
              dividerColor: _border,
              tabs: [for (final t in tabs) Tab(text: t)],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final t in tabs) _tabBody(kind, t, id.name, deviceOnlineFromMeta(id.metaJson)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBody(String kind, String tab, String name, bool online) {
    if (kind == 'remote' && tab == 'Remote') return UiRemoteDevice(deviceName: name, online: online);
    return Center(
      child: Text(
        '$tab — coming soon',
        style: const TextStyle(color: _muted, fontSize: 14),
      ),
    );
  }
}
