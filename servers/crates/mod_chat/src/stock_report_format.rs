#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StockReportFormat {
    Table,
    Pdf,
    Xlsx,
    Slides,
    Gsheet,
}
