/// Compile-time gate: Play Store AAB must not link wallet top-up (Midtrans / transfer UI).
const String _billingDistribution = String.fromEnvironment('C35_BILLING_DISTRIBUTION', defaultValue: '');

const bool billingPlayStoreArtifact =
    _billingDistribution == 'play' || _billingDistribution == 'store';
