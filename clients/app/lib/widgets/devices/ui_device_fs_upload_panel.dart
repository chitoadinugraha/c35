import 'package:alienai_c35/c/remote/remote_fs_transfer.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _fail = Color(0xFFFCA5A5);

class UiDeviceFsUploadPanel extends StatelessWidget {
  const UiDeviceFsUploadPanel({super.key, required this.session});

  final RemoteSession session;

  @override
  Widget build(BuildContext context) {
    final transfer = RemoteFsTransfer.of(session);
    return ListenableBuilder(
      listenable: transfer,
      builder: (context, _) {
        final jobs = transfer.panelJobs;
        if (jobs.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Transfers (${transfer.activeCount} active)', style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              for (final j in jobs.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _jobBar(transfer, j),
                ),
              if (jobs.length > 4)
                Text('+${jobs.length - 4} more', style: const TextStyle(color: _muted, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _jobBar(RemoteFsTransfer transfer, RemoteFsJob job) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: job.status == RemoteFsJobStatus.failed ? _fail : _text, fontSize: 11),
                ),
              ),
              if (job.status == RemoteFsJobStatus.failed)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () => transfer.dismissJob(job.id),
                  icon: const Icon(Icons.close, size: 14, color: _muted),
                ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: job.status == RemoteFsJobStatus.failed ? null : (job.status == RemoteFsJobStatus.done ? 1 : job.progress),
              minHeight: 3,
              backgroundColor: const Color(0xFF27272A),
              color: job.status == RemoteFsJobStatus.failed ? const Color(0xFFEF4444) : _accent,
            ),
          ),
        ],
      );
}