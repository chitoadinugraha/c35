import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

typedef ThisPcRegister = Future<int?> Function({String name});

Future<bool?> pageAllowControlShow(BuildContext context, {required AppStore store, ThisPcRegister? thisPcRegister, Future<void> Function()? thisPcUnregister}) async {
  final go = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: const Color(0xFF18181B),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => PageAllowControl(store: store, thisPcUnregister: thisPcUnregister),
  );
  if (go != true) return go;
  if (!context.mounted) return false;
  final name = Session.instance.name.isNotEmpty ? Session.instance.name : 'This PC';
  await Session.instance.thisPcNamePut(name);
  store.thisPcAllow(name: name);
  await thisPcRegister?.call(name: name);
  return true;
}

Future<void> pageAllowControlRevoke(BuildContext context, {required AppStore store, Future<void> Function()? thisPcUnregister}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: Text('settings.controlThisComputerRevokeTitle'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))),
      content: Text('settings.controlThisComputerRevokeBody'.tr(), style: const TextStyle(color: Color(0xFFA1A1AA))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white), child: Text('settings.revoke'.tr())),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await Session.instance.allowControlPut('no');
  await thisPcUnregister?.call();
  store.thisPcDeny();
}

class PageAllowControl extends StatelessWidget {
  const PageAllowControl({super.key, required this.store, this.onNotNow, this.thisPcUnregister});

  final AppStore store;
  final VoidCallback? onNotNow;
  final Future<void> Function()? thisPcUnregister;

  Future<void> _allow(BuildContext context) async {
    await Session.instance.allowControlPut('yes');
    if (context.mounted && Navigator.of(context).canPop()) Navigator.pop(context, true);
  }

  Future<void> _notNow(BuildContext context) async {
    await Session.instance.allowControlPut('no');
    await thisPcUnregister?.call();
    store.thisPcDeny();
    onNotNow?.call();
    if (context.mounted && Navigator.of(context).canPop()) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('settings.controlThisComputer'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5))),
            const SizedBox(height: 8),
            const Text(
              'Would you like Alien AI to control this computer when you ask? It only acts on your requests.',
              style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFFA1A1AA)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _notNow(context),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFA1A1AA), side: const BorderSide(color: Color(0xFF3F3F46))),
                    child: const Text('Do not allow'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _allow(context),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: const Color(0xFF052E1C)),
                    child: const Text('Allow'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
