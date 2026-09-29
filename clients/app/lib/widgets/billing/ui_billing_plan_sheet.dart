import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_package_sheet.dart';
import 'package:flutter/material.dart';

/// Show the Plans Sheet as a bottom sheet.
///
/// Lets the user subscribe, upgrade, downgrade, or cancel their plan.
/// Calls `billingPlanQuote` when a plan is tapped and `billingPlanChange`
/// on confirm, then updates [AppStore] automatically via
/// `billingPlanChangeAndSync`.
///
/// This is the canonical entry point from the account menu and any
/// "Upgrade" / "Subscribe" CTA in the app.
Future<void> showBillingPlanSheet(BuildContext context, ReferralConn conn) =>
    billingPackageSheet(context, conn: conn);
