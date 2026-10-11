import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:flutter/material.dart';

enum UiAdminConsoleScope { server, pods }

class UiAdminConsoleScopeTabs extends StatelessWidget {
  const UiAdminConsoleScopeTabs({
    super.key,
    required this.scope,
    required this.onChanged,
    this.compact = false,
  });

  final UiAdminConsoleScope scope;
  final ValueChanged<UiAdminConsoleScope> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: compact ? 0 : 10),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            _tab('Server', UiAdminConsoleScope.server),
            SizedBox(width: compact ? 12 : 16),
            _tab('Pods', UiAdminConsoleScope.pods),
          ],
        ),
      );

  Widget _tab(String label, UiAdminConsoleScope value) {
    final selected = scope == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? adminText : adminMuted,
          fontSize: compact ? 12 : 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
