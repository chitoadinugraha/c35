import 'dart:async';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/mail/mail_models.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const mailStagedAttachmentMaxCount = 10;
const mailStagedAttachmentMaxBytes = 5 * 1024 * 1024;

const _mailDocPickExtensions = ['pdf', 'txt', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'zip'];
const _imagePickExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

List<String> get mailAttachmentPickExtensions => [..._imagePickExtensions, ..._mailDocPickExtensions];

String mailAttachmentGuessMime(String name, String? ext) {
  final e = (ext ?? '').toLowerCase();
  final n = name.toLowerCase();
  if (e == 'png' || n.endsWith('.png')) return 'image/png';
  if (e == 'jpg' || e == 'jpeg' || n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
  if (e == 'gif' || n.endsWith('.gif')) return 'image/gif';
  if (e == 'webp' || n.endsWith('.webp')) return 'image/webp';
  if (e == 'pdf' || n.endsWith('.pdf')) return 'application/pdf';
  if (e == 'txt' || n.endsWith('.txt')) return 'text/plain';
  return 'application/octet-stream';
}

bool mailAttachmentMimeIsImage(String mime) => mime.startsWith('image/');

class StagedMailAttachment {
  StagedMailAttachment({required this.id, required this.name, required this.mime, required this.bytes, this.uploading = true, this.path, this.size, this.error});
  final String id;
  final String name;
  String mime;
  final Uint8List bytes;
  bool uploading;
  String? path;
  int? size;
  String? error;
  bool get isReady => path != null && path!.trim().isNotEmpty && !uploading && (error == null || error!.isEmpty);
  bool get isImage => mailAttachmentMimeIsImage(mime);
  MailAttachment toMailAttachment() => MailAttachment(path: path!, name: name, mime: mime, size: size ?? bytes.length);
}

class MailStagedAttachmentsController {
  MailStagedAttachmentsController({required this.onChanged});
  final VoidCallback onChanged;
  final List<StagedMailAttachment> items = [];
  var _seq = 0;
  bool get anyUploading => items.any((i) => i.uploading);
  bool get anyFailed => items.any((i) => i.error != null && i.error!.isNotEmpty);
  bool get canSend => !anyUploading && !anyFailed;
  List<MailAttachment> readyAttachments() => [for (final i in items) if (i.isReady) i.toMailAttachment()];

  Future<String?> pickAndStage({BuildContext? context}) async {
    if (items.length >= mailStagedAttachmentMaxCount) return null;
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: mailAttachmentPickExtensions, lockParentWindow: !kIsWeb, withData: kIsWeb);
    if (result == null || result.files.isEmpty) return null;
    String? tooLargeName;
    for (final file in result.files) {
      if (items.length >= mailStagedAttachmentMaxCount) break;
      final staged = await _stageFromPickerFile(file);
      if (staged == null) { tooLargeName = file.name; continue; }
      items.add(staged);
      onChanged();
      unawaited(_upload(staged));
    }
    return tooLargeName;
  }

  Future<StagedMailAttachment?> _stageFromPickerFile(PlatformFile file) async {
    final bytes = await platformFileBytes(file);
    if (bytes == null || bytes.isEmpty) return null;
    final mime = mailAttachmentGuessMime(file.name, file.extension);
    if (bytes.length > mailStagedAttachmentMaxBytes) return null;
    _seq += 1;
    return StagedMailAttachment(id: 'mail_att_$_seq', name: file.name, mime: mime, bytes: bytes);
  }

  Future<void> _upload(StagedMailAttachment item) async {
    item.uploading = true;
    item.error = null;
    onChanged();
    try {
      final res = await casUpload(bytes: item.bytes, mime: item.mime, name: item.name);
      if (res == null) throw 'upload failed';
      item..path = fileStoragePath(res.hash)..size = item.bytes.length..uploading = false..error = null;
    } catch (e, st) {
      lError('$e\n$st');
      item..uploading = false..error = 'errors.uploadFailed'.tr();
    }
    onChanged();
  }

  void removeAt(int index) { if (index < 0 || index >= items.length) return; items.removeAt(index); onChanged(); }
  Future<void> retryAt(int index) async { if (index < 0 || index >= items.length) return; final item = items[index]; if (item.isReady) return; await _upload(item); }
}
