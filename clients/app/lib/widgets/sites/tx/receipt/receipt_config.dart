class ReceiptConfig {
  final String projectName;
  final String projectLogo;
  final String receiptHeader;
  final String receiptFooter;
  final String projectAddress;
  final String projectContact;
  final bool showQrLink;
  final bool showSiteName;
  /// PDF / preview margin (mm per edge).
  final int marginMm;
  /// Roll paper width: 58 or 80 mm.
  final int paperWidthMm;
  /// Site logo on receipt (px).
  final int logoSizePx;

  const ReceiptConfig({
    this.projectName = '',
    this.projectLogo = '',
    this.receiptHeader = '',
    this.receiptFooter = '',
    this.projectAddress = '',
    this.projectContact = '',
    this.showQrLink = true,
    this.showSiteName = true,
    this.marginMm = 0,
    this.paperWidthMm = 80,
    this.logoSizePx = 60,
  });
}
