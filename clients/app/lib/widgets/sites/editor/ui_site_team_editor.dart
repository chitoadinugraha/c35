import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class UiSiteTeamEditor extends StatefulWidget {
  const UiSiteTeamEditor({
    super.key,
    required this.row,
    required this.api,
    required this.siteIid,
    this.onCapabilitiesSaved,
  });

  final SiteRow row;
  final SiteApi api;
  final int siteIid;
  final Future<void> Function()? onCapabilitiesSaved;

  @override
  State<UiSiteTeamEditor> createState() => _UiSiteTeamEditorState();
}

class _UiSiteTeamEditorState extends State<UiSiteTeamEditor> {
  var _loading = true;
  var _busy = false;
  String? _error;
  List<SiteGrant> _grants = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final grants = await widget.api.grantList(widget.siteIid);
      if (!mounted) return;
      setState(() {
        _grants = grants;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = uiFriendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _revoke(SiteGrant grant) async {
    setState(() => _busy = true);
    try {
      await widget.api.grantDelete(widget.siteIid, grant.granteeIid.toInt());
      await widget.onCapabilitiesSaved?.call();
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_grants.isEmpty) {
      return const Center(
        child: Text(
          'No staff yet. Grant staff or manage access via chat.',
          style: TextStyle(color: _muted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _grants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final g = _grants[i];
        final handle = g.granteeAlienId.isNotEmpty ? '@${g.granteeAlienId}' : g.granteeIid.toString();
        final title = g.granteeName.isNotEmpty ? g.granteeName : handle;
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
          ),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('$handle · ${g.role}', style: const TextStyle(fontSize: 12, color: _muted)),
          trailing: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(icon: const Icon(Icons.person_remove_outlined, size: 20), onPressed: () => _revoke(g)),
        );
      },
    );
  }
}
