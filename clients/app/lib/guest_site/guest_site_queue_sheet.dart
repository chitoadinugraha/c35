import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/guest_site/guest_site_modal.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _guestTextPrimary = Color(0xFFF4F4F5);
const _guestTextSecondary = Color(0xFFA1A1AA);
const _guestBorder = Color(0x33FFFFFF);

const _trackPollInterval = Duration(seconds: 15);

List<Map<String, dynamic>> guestQueueDefaultFields() => [
      {'name': 'name', 'label': 'Nama Lengkap', 'type': 'text', 'required': true},
      {'name': 'phone', 'label': 'WhatsApp / No. HP', 'type': 'tel', 'required': true},
    ];

List<Map<String, dynamic>> guestQueueResolveFields({
  required Map<String, dynamic> props,
  required List<Map<String, dynamic>> bootQueues,
  required int queueId,
}) {
  final fromProps = props['fields'];
  if (fromProps is List && fromProps.isNotEmpty) {
    return [
      for (final row in fromProps)
        if (row is Map) row.map((k, v) => MapEntry(k.toString(), v)),
    ];
  }
  for (final row in bootQueues) {
    final rawId = row['queue_id'];
    final id = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString().trim() ?? '') ?? 0;
    if (id != queueId) continue;
    final fields = row['fields'];
    if (fields is List && fields.isNotEmpty) {
      return [
        for (final f in fields)
          if (f is Map) f.map((k, v) => MapEntry(k.toString(), v)),
      ];
    }
  }
  return guestQueueDefaultFields();
}

bool guestQueueTakeOnline(Map<String, dynamic> props, List<Map<String, dynamic>> bootQueues, int queueId) {
  final prop = props['take_online'];
  if (prop is bool) return prop;
  for (final row in bootQueues) {
    final rawId = row['queue_id'];
    final id = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString().trim() ?? '') ?? 0;
    if (id != queueId) continue;
    final online = row['take_online'];
    if (online is bool) return online;
  }
  return true;
}

String guestQueueTrackPrefsKey(int siteIid, int queueId) => 'c35.guest.queue.track.$siteIid.$queueId';

String guestQueueFormatTrackStatus(Map<String, dynamic> data) {
  final label = data['display_label']?.toString().trim() ?? data['label']?.toString().trim() ?? '';
  final serving = data['serving_ticket_no'];
  final servingText = serving == null ? '' : serving.toString();
  if (label.isNotEmpty && servingText.isNotEmpty) {
    return '$label · Sedang dilayani: $servingText';
  }
  if (label.isNotEmpty) return label;
  if (servingText.isNotEmpty) return 'Sedang dilayani: $servingText';
  return '';
}

Future<Map<String, dynamic>> guestQueueTrackFetch({
  required int siteIid,
  required String trackToken,
}) async {
  final base = Uri.parse('$authApiProductionUrl/v1/site/guest-queue/track');
  var resp = await http.get(base.replace(queryParameters: {'track_token': trackToken}));
  if (resp.statusCode != 200) {
    resp = await http.post(
      base,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'site_iid': siteIid, 'track_token': trackToken}),
    );
  }
  final decoded = jsonDecode(resp.body);
  if (decoded is! Map) throw StateError('Gagal memuat status antrian');
  if (resp.statusCode != 200 || decoded['ok'] == false) {
    final err = decoded['error']?.toString().trim() ?? '';
    throw StateError(err.isEmpty ? 'Gagal memuat status antrian' : err);
  }
  return decoded.map((k, v) => MapEntry(k.toString(), v));
}

Future<Map<String, dynamic>> guestQueueTake({
  required int siteIid,
  required int queueId,
  required Map<String, String> answers,
}) async {
  final resp = await http.post(
    Uri.parse('$authApiProductionUrl/v1/site/guest-queue/take'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'site_iid': siteIid,
      'queue_id': queueId,
      'answers': answers,
    }),
  );
  final decoded = jsonDecode(resp.body);
  if (decoded is! Map) throw StateError('Gagal ambil nomor');
  if (resp.statusCode != 200 || decoded['ok'] != true) {
    final err = decoded['error']?.toString().trim() ?? '';
    throw StateError(err.isEmpty ? 'Gagal ambil nomor' : err);
  }
  return decoded.map((k, v) => MapEntry(k.toString(), v));
}

Future<void> showGuestSiteQueueSheet({
  required BuildContext context,
  required int siteIid,
  required int queueId,
  required String title,
  required List<Map<String, dynamic>> fields,
  required Color accent,
  required void Function(Map<String, dynamic> takeResult) onTaken,
}) async {
  await guestSiteShowModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF18181B),
    builder: (ctx) => GuestSiteQueueSheet(
      siteIid: siteIid,
      queueId: queueId,
      title: title,
      fields: fields,
      accent: accent,
      onTaken: onTaken,
    ),
  );
}

class GuestSiteQueueSheet extends StatefulWidget {
  const GuestSiteQueueSheet({
    super.key,
    required this.siteIid,
    required this.queueId,
    required this.title,
    required this.fields,
    required this.accent,
    required this.onTaken,
  });

  final int siteIid;
  final int queueId;
  final String title;
  final List<Map<String, dynamic>> fields;
  final Color accent;
  final void Function(Map<String, dynamic> takeResult) onTaken;

  @override
  State<GuestSiteQueueSheet> createState() => _GuestSiteQueueSheetState();
}

class _GuestSiteQueueSheetState extends State<GuestSiteQueueSheet> {
  final _controllers = <String, TextEditingController>{};
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      final name = field['name']?.toString().trim() ?? field['label']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      _controllers[name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _guestTextSecondary, fontSize: 12),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _guestBorder)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.accent)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
    );
  }

  Map<String, String> _collectAnswers() {
    final answers = <String, String>{};
    for (final field in widget.fields) {
      final name = field['name']?.toString().trim() ?? field['label']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      answers[name] = _controllers[name]?.text.trim() ?? '';
    }
    return answers;
  }

  String? _validate(Map<String, String> answers) {
    for (final field in widget.fields) {
      if (field['required'] != true) continue;
      final name = field['name']?.toString().trim() ?? field['label']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      if ((answers[name] ?? '').isEmpty) {
        final label = field['label']?.toString() ?? name;
        return 'Lengkapi $label';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final answers = _collectAnswers();
    final validation = _validate(answers);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await guestQueueTake(
        siteIid: widget.siteIid,
        queueId: widget.queueId,
        answers: answers,
      );
      if (!mounted) return;
      widget.onTaken(result);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is StateError ? e.message : 'Gagal ambil nomor');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _guestTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: _guestTextSecondary),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final field in widget.fields) ...[
                      Builder(
                        builder: (context) {
                          final name = field['name']?.toString().trim() ??
                              field['label']?.toString().trim() ??
                              '';
                          final label = field['label']?.toString() ?? name;
                          if (name.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextField(
                              key: Key('guest-queue-field-$name'),
                              controller: _controllers[name],
                              decoration: _decoration(label),
                              style: const TextStyle(color: _guestTextPrimary, fontSize: 13),
                              textInputAction: TextInputAction.next,
                              keyboardType: field['type']?.toString() == 'tel'
                                  ? TextInputType.phone
                                  : TextInputType.text,
                            ),
                          );
                        },
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                        ),
                      ),
                    FilledButton(
                      key: const Key('guest-queue-submit'),
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: widget.accent),
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Ambil nomor'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Polls track endpoint until [dispose].
class GuestQueueTrackPoller {
  GuestQueueTrackPoller({
    required this.siteIid,
    required this.trackToken,
    required this.onStatus,
  });

  final int siteIid;
  final String trackToken;
  final void Function(String statusLabel) onStatus;

  Timer? _timer;

  void start() {
    _timer?.cancel();
    unawaited(_tick());
    _timer = Timer.periodic(_trackPollInterval, (_) => unawaited(_tick()));
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    try {
      final data = await guestQueueTrackFetch(siteIid: siteIid, trackToken: trackToken);
      onStatus(guestQueueFormatTrackStatus(data));
    } catch (_) {
      // ignore transient errors while polling
    }
  }
}

Future<void> guestQueuePersistTrackToken(int siteIid, int queueId, String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(guestQueueTrackPrefsKey(siteIid, queueId), token);
}

Future<String?> guestQueueReadTrackToken(int siteIid, int queueId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(guestQueueTrackPrefsKey(siteIid, queueId));
}
