import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/ai/ui_serve_image.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/pos_queue_store.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/tx_queue_helpers.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiPosQueuePaymentDetail extends StatelessWidget {
  const UiPosQueuePaymentDetail({super.key, required this.store, required this.tx});

  final PosQueueStore store;
  final Tx tx;

  Future<void> _decline(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Decline payment?', style: TextStyle(color: _text)),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: _text),
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            hintStyle: TextStyle(color: _muted),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.declinePayment(tx.txId, reason: reasonCtrl.text);
    reasonCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proof = txQueueFirstProofPath(tx);
    final placed = txQueuePlacedAt(tx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  moneyFmtIdr(tx.total.toInt()),
                  style: const TextStyle(color: _accent, fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${tx.txId} · ${txQueueCustomerLabel(tx)}',
                  style: const TextStyle(color: _text, fontSize: 15),
                ),
                if (placed != null) ...[
                  const SizedBox(height: 4),
                  Text(txQueueFormatTimeAgo(placed), style: const TextStyle(color: _muted, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                const Text('Payment method', style: TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(txQueuePaymentMethodLabel(tx), style: const TextStyle(color: _text, fontSize: 15)),
                const SizedBox(height: 20),
                const Text('Payment proof', style: TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 8),
                if (proof != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: InteractiveViewer(
                        child: UiServeImage(path: proof, fit: BoxFit.contain),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: const Text('No proof attached', style: TextStyle(color: _muted)),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: store.busy ? null : () => _decline(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: store.busy ? null : () => store.confirmPayment(tx.txId),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF052E1B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: store.busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF052E1B)),
                        )
                      : const Text('Confirm payment'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
