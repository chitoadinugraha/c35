class ReceiptConfig {
  final String projectName;
  final String projectLogo;
  final String receiptHeader;
  final String receiptFooter;
  final String projectAddress;
  final String projectContact;
  final bool showQrLink;

  const ReceiptConfig({
    this.projectName = '',
    this.projectLogo = '',
    this.receiptHeader = '',
    this.receiptFooter = '',
    this.projectAddress = '',
    this.projectContact = '',
    this.showQrLink = true,
  });
}
