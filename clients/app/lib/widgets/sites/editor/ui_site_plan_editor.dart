import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_history_sheet.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

/// Owner wallet summary. There is no site-plan route; billing opens the existing history sheet.
class UiSitePlanEditor extends StatefulWidget {
  const UiSitePlanEditor({super.key});

  @override
  State<UiSitePlanEditor> createState() => _UiSitePlanEditorState();
}

class _UiSitePlanEditorState extends State<UiSitePlanEditor> {
  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_onStore);
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final account = store.billing;
    final plan = billingPlanTierLabel(store.planTier);
    final balance = account == null ? 'Wallet not loaded' : billingBalanceLabel(account);
    return UiSiteEditorFormScroll(
      children: [
        const Text('Billing', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'This site uses your Alien AI wallet. Plan and balance are the account you are signed in with.',
          style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 16),
        UiSiteEditorFormSection(
          children: [
            _row('Plan', plan),
            const SizedBox(height: 10),
            _row('Wallet', balance),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => billingHistorySheet(context, conn: ReferralConn()),
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: const Text('Open billing'),
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E1F)),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 13))),
          Text(value, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );
}
