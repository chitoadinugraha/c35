import 'package:alienai_c35/c/admin/admin_stats_stream.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_host_metrics.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:flutter/material.dart';

class UiAdminPodSearchField extends StatelessWidget {
  const UiAdminPodSearchField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: adminText, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search namespace or pod',
        hintStyle: TextStyle(color: adminMuted.withValues(alpha: 0.75), fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: adminMuted),
        isDense: true,
        filled: true,
        fillColor: adminBarBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class UiAdminPodList extends StatefulWidget {
  const UiAdminPodList({
    super.key,
    required this.stats,
    required this.nodeName,
    required this.searchController,
  });

  final AdminStatsStream stats;
  final String nodeName;
  final TextEditingController searchController;

  @override
  State<UiAdminPodList> createState() => _UiAdminPodListState();
}

class _UiAdminPodListState extends State<UiAdminPodList> {
  final _nsExpanded = <String, bool>{};
  final _wlExpanded = <String, bool>{};

  String get _search => widget.searchController.text;

  bool _nsOpen(AdminPodNamespace ns) {
    if (_search.trim().isNotEmpty) return true;
    return _nsExpanded[ns.namespace] ?? (ns.podCount <= 8);
  }

  bool _wlOpen(AdminPodGroup group) {
    if (_search.trim().isNotEmpty) return true;
    return _wlExpanded[group.title] ?? (group.pods.length <= 2);
  }

  @override
  Widget build(BuildContext context) {
    final namespaces = widget.stats.podNamespacesForNode(widget.nodeName, search: _search);
    if (namespaces.isEmpty) {
      final emptyMsg = _search.trim().isEmpty ? 'No pod stats yet' : 'No pods match search';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(emptyMsg, style: const TextStyle(color: adminMuted, fontSize: 12)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'used / request / limit · tick = request · blue = no limit',
            style: TextStyle(color: adminMuted, fontSize: 11),
          ),
        ),
        for (final ns in namespaces) ...[
          _NamespaceTile(
            namespace: ns,
            stats: widget.stats,
            expanded: _nsOpen(ns),
            workloadExpanded: _wlOpen,
            onToggleNs: () {
              setState(() {
                _nsExpanded[ns.namespace] = !_nsOpen(ns);
              });
            },
            onToggleWl: (group) {
              setState(() {
                _wlExpanded[group.title] = !_wlOpen(group);
              });
            },
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _NamespaceTile extends StatelessWidget {
  const _NamespaceTile({
    required this.namespace,
    required this.stats,
    required this.expanded,
    required this.workloadExpanded,
    required this.onToggleNs,
    required this.onToggleWl,
  });

  final AdminPodNamespace namespace;
  final AdminStatsStream stats;
  final bool expanded;
  final bool Function(AdminPodGroup group) workloadExpanded;
  final VoidCallback onToggleNs;
  final void Function(AdminPodGroup group) onToggleWl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggleNs,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                  size: 22,
                  color: adminText,
                ),
                Expanded(
                  child: Text(
                    '${namespace.namespace} (${namespace.podCount})',
                    style: const TextStyle(color: adminText, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final group in namespace.workloads)
            _PodGroupTile(
              group: group,
              stats: stats,
              expanded: workloadExpanded(group),
              onToggle: () => onToggleWl(group),
            ),
      ],
    );
  }
}

class _PodGroupTile extends StatelessWidget {
  const _PodGroupTile({
    required this.group,
    required this.stats,
    required this.expanded,
    required this.onToggle,
  });

  final AdminPodGroup group;
  final AdminStatsStream stats;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2, right: 2),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                  size: 18,
                  color: adminMuted,
                ),
                Expanded(
                  child: Text(
                    '${group.workload} (${group.pods.length})',
                    style: const TextStyle(color: adminMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final pod in group.pods) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 2, top: 2),
              child: Text(
                pod.podName,
                style: const TextStyle(color: adminMuted, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: UiAdminPodMetrics(stats: stats, pod: pod),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}