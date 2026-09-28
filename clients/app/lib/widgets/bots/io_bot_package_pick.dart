import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);
const _accent = Color(0xFF34D399);
const _strike = Color(0xFFF97316);
const _panelBg = Color(0xFF100F12);

enum BotBillingPackage {
  shared('shared'),
  lite('bot.lite'),
  small('bot.small');

  const BotBillingPackage(this.slug);

  final String slug;

  bool get usesOwnerQuota => this == BotBillingPackage.shared;

  String titleKey() => switch (this) {
        BotBillingPackage.shared => 'botCreate.packageFreeTitle',
        BotBillingPackage.lite => 'botCreate.packageLiteTitle',
        BotBillingPackage.small => 'botCreate.packageSmallTitle',
      };

  String priceKey(bool yearly) => switch (this) {
        BotBillingPackage.shared => 'botCreate.packageFreePrice',
        BotBillingPackage.lite =>
          yearly ? 'botCreate.packageLitePriceYearly' : 'botCreate.packageLitePriceMonthly',
        BotBillingPackage.small =>
          yearly ? 'botCreate.packageSmallPriceYearly' : 'botCreate.packageSmallPriceMonthly',
      };

  String? priceWasKey(bool yearly) => switch (this) {
        BotBillingPackage.lite =>
          yearly ? 'botCreate.packageLitePriceWasYearly' : 'botCreate.packageLitePriceWasMonthly',
        BotBillingPackage.small =>
          yearly ? 'botCreate.packageSmallPriceWasYearly' : 'botCreate.packageSmallPriceWasMonthly',
        _ => null,
      };

  String infoKey() => switch (this) {
        BotBillingPackage.shared => 'botCreate.packageFreeInfo',
        BotBillingPackage.lite => 'botCreate.packageLiteInfo',
        BotBillingPackage.small => 'botCreate.packageSmallInfo',
      };

  String line1Key() => switch (this) {
        BotBillingPackage.shared => 'botCreate.packageFreeLine1',
        BotBillingPackage.lite => 'botCreate.packageLiteLine1',
        BotBillingPackage.small => 'botCreate.packageSmallLine1',
      };

  String line2Key() => switch (this) {
        BotBillingPackage.shared => 'botCreate.packageFreeLine2',
        BotBillingPackage.lite => 'botCreate.packageLiteLine2',
        BotBillingPackage.small => 'botCreate.packageSmallLine2',
      };
}

BillingPlanDoc? botPlanDocFor(List<BillingPlanDoc> plans, BotBillingPackage pkg) {
  for (final p in plans) {
    if (p.slug == pkg.slug) return p;
  }
  return null;
}

String botPlanPerMonthSuffix(BuildContext context) => context.locale.languageCode == 'id' ? '/bln' : '/mo';

class IoBotPackagePick extends StatelessWidget {
  const IoBotPackagePick({
    super.key,
    required this.value,
    required this.onChanged,
    required this.yearly,
    required this.onYearlyChanged,
    this.botPlans = const [],
    this.busy = false,
    this.planExpiresTsMs,
    this.packageLabelKey = 'botCreate.packageLabel',
  });

  final BotBillingPackage? value;
  final ValueChanged<BotBillingPackage> onChanged;
  final bool yearly;
  final ValueChanged<bool> onYearlyChanged;
  final List<BillingPlanDoc> botPlans;
  final bool busy;
  final int? planExpiresTsMs;
  final String packageLabelKey;

  Future<void> _openDialog(BuildContext context) async {
    if (busy) return;
    final result = await showDialog<({BotBillingPackage pkg, bool yearly})>(
      context: context,
      builder: (ctx) => _BotPackagePickDialog(
        value: value,
        yearly: yearly,
        botPlans: botPlans,
      ),
    );
    if (result == null) return;
    onYearlyChanged(result.yearly);
    onChanged(result.pkg);
  }

  String _fieldLine(BuildContext context) {
    final pkg = value;
    if (pkg == null) return '';
    final title = pkg.titleKey().tr();
    if (pkg.usesOwnerQuota) return title;
    final period = yearly ? 'botCreate.billingYearly'.tr() : 'botCreate.billingMonthly'.tr();
    return '$title · $period';
  }

  @override
  Widget build(BuildContext context) {
    final pkg = value;
    final line = _fieldLine(context);
    final hasValue = pkg != null;
    return Opacity(
      opacity: busy ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : () => _openDialog(context),
          borderRadius: BorderRadius.circular(UiInputDecoration.kRadius),
          child: InputDecorator(
            decoration: UiInputDecoration.of(
              context,
              labelText: packageLabelKey.tr(),
              floatingLabel: true,
              suffixIcon: const Icon(Icons.chevron_right_rounded, color: _muted, size: 22),
              suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            isEmpty: !hasValue,
            child: hasValue
                ? Text(line, style: const TextStyle(color: _title, fontSize: 14, fontWeight: FontWeight.w500))
                : Text(
                    'botCreate.packageChoosePrompt'.tr(),
                    style: TextStyle(color: _muted.withValues(alpha: 0.65), fontSize: 14),
                  ),
          ),
        ),
      ),
    );
  }
}

class _BotPackagePickDialog extends StatefulWidget {
  const _BotPackagePickDialog({required this.value, required this.yearly, required this.botPlans});

  final BotBillingPackage? value;
  final bool yearly;
  final List<BillingPlanDoc> botPlans;

  @override
  State<_BotPackagePickDialog> createState() => _BotPackagePickDialogState();
}

class _BotPackagePickDialogState extends State<_BotPackagePickDialog> {
  BotBillingPackage? _pkg;
  late bool _yearly = widget.yearly;

  @override
  void initState() {
    super.initState();
    _pkg = widget.value;
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _border)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'botCreate.packageDialogTitle'.tr(),
                        style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: _muted, size: 20),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_pkg != null && !_pkg!.usesOwnerQuota)
                      _BillingPeriodToggle(yearly: _yearly, busy: false, onYearlyChanged: (v) => setState(() => _yearly = v)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  children: BotBillingPackage.values
                      .map(
                        (pkg) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PackageTile(
                            pkg: pkg,
                            yearly: _yearly,
                            planDoc: botPlanDocFor(widget.botPlans, pkg),
                            selected: _pkg == pkg,
                            onTap: () => setState(() => _pkg = pkg),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FilledButton(
                  onPressed: _pkg == null ? null : () => Navigator.pop(context, (pkg: _pkg!, yearly: _yearly)),
                  style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
                  child: Text('botCreate.packageDialogApply'.tr()),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BillingPeriodToggle extends StatelessWidget {
  const _BillingPeriodToggle({required this.yearly, required this.busy, required this.onYearlyChanged});

  final bool yearly;
  final bool busy;
  final ValueChanged<bool> onYearlyChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _periodLabel(
            'botCreate.billingYearly'.tr(),
            selected: yearly,
            onTap: busy ? null : () => onYearlyChanged(true),
          ),
          Text(' / ', style: TextStyle(color: _muted.withValues(alpha: 0.7), fontSize: 12)),
          _periodLabel(
            'botCreate.billingMonthly'.tr(),
            selected: !yearly,
            onTap: busy ? null : () => onYearlyChanged(false),
          ),
        ],
      );

  Widget _periodLabel(String label, {required bool selected, VoidCallback? onTap}) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? _title : _muted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      );
}

Widget _listPriceStrike(String label) => Stack(
      clipBehavior: Clip.none,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _strike.withValues(alpha: 0.88),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: _strike,
            ),
          ),
        ),
      ],
    );

class _PackagePrice extends StatelessWidget {
  const _PackagePrice({
    required this.pkg,
    required this.yearly,
    required this.selected,
    required this.planDoc,
  });

  final BotBillingPackage pkg;
  final bool yearly;
  final bool selected;
  final BillingPlanDoc? planDoc;

  @override
  Widget build(BuildContext context) {
    final saleStyle = TextStyle(
      color: selected ? _accent : _accent.withValues(alpha: 0.92),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    final periodStyle = TextStyle(color: _muted.withValues(alpha: 0.85), fontSize: 10, height: 1.2);
    final suffix = botPlanPerMonthSuffix(context);
    if (pkg.usesOwnerQuota) {
      return Text(pkg.priceKey(yearly).tr(), style: saleStyle, textAlign: TextAlign.right);
    }

    final doc = planDoc;
    final saleAmount = doc != null ? (yearly ? doc.priceIdrYearly : doc.priceIdrMonthly) : 0.0;
    final listAmount = doc != null ? (yearly ? doc.priceIdrYearlyList : doc.priceIdrMonthlyList) : 0.0;
    final saleLabel = saleAmount > 0 ? '${billingFmtRp(saleAmount)}$suffix' : pkg.priceKey(yearly).tr();
    final listLabel = listAmount > saleAmount && saleAmount > 0
        ? '${billingFmtRp(listAmount)}$suffix'
        : (pkg.priceWasKey(yearly)?.tr());

    if (listLabel == null || listLabel.isEmpty) {
      return Text(saleLabel, style: saleStyle, textAlign: TextAlign.right);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _listPriceStrike(listLabel),
            const SizedBox(width: 8),
            Text(saleLabel, style: saleStyle),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          (yearly ? 'botCreate.priceBilledYearly' : 'botCreate.priceBilledMonthly').tr(),
          style: periodStyle,
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.pkg,
    required this.yearly,
    required this.planDoc,
    required this.selected,
    this.onTap,
  });

  final BotBillingPackage pkg;
  final bool yearly;
  final BillingPlanDoc? planDoc;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: selected ? _title : _title.withValues(alpha: 0.92),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    const infoStyle = TextStyle(color: _muted, fontSize: 12, height: 1.45, fontStyle: FontStyle.italic);
    const detailStyle = TextStyle(color: _muted, fontSize: 12, height: 1.4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: onTap == null ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            decoration: BoxDecoration(
              color: selected ? _accent.withValues(alpha: 0.08) : _panelBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? _accent.withValues(alpha: 0.65) : _border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (selected ? _accent : _muted).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.smart_toy_outlined, size: 20, color: selected ? _accent : _muted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(pkg.titleKey().tr(), style: titleStyle)),
                          const SizedBox(width: 8),
                          _PackagePrice(pkg: pkg, yearly: yearly, selected: selected, planDoc: planDoc),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(pkg.infoKey().tr(), style: infoStyle),
                      const SizedBox(height: 6),
                      Text(pkg.line1Key().tr(), style: detailStyle),
                      const SizedBox(height: 4),
                      Text(pkg.line2Key().tr(), style: detailStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
