import 'dart:convert';

class VizChartSeries {
  VizChartSeries({required this.name, required this.values});
  final String name;
  final List<double> values;

  static VizChartSeries? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name']?.toString().trim() ?? 'Series';
    final vals = raw['values'];
    if (vals is! List) return null;
    final numbers = <double>[];
    for (final v in vals) {
      final n = v is num ? v.toDouble() : double.tryParse('$v');
      if (n == null || !n.isFinite) return null;
      numbers.add(n);
    }
    return VizChartSeries(name: name.isEmpty ? 'Series' : name, values: numbers);
  }
}

class VizChartData {
  VizChartData({
    required this.chartType,
    required this.title,
    required this.labels,
    required this.series,
    this.xLabel = '',
    this.yLabel = '',
  });

  final String chartType;
  final String title;
  final List<String> labels;
  final List<VizChartSeries> series;
  final String xLabel;
  final String yLabel;

  static VizChartData? fromBlockBody(Map<String, dynamic> body) {
    final chartType = (body['chart_type'] ?? body['type'] ?? '').toString().trim().toLowerCase();
    if (!{'bar', 'line', 'pie'}.contains(chartType)) return null;
    final labels = _strings(body['labels']);
    if (labels.isEmpty) return null;
    final rawSeries = body['series'];
    if (rawSeries is! List || rawSeries.isEmpty) return null;
    final series = <VizChartSeries>[];
    for (final item in rawSeries) {
      final s = VizChartSeries.fromJson(item);
      if (s == null || s.values.length != labels.length) return null;
      series.add(s);
    }
    return VizChartData(
      chartType: chartType,
      title: body['title']?.toString().trim() ?? '',
      labels: labels,
      series: series,
      xLabel: body['x_label']?.toString().trim() ?? '',
      yLabel: body['y_label']?.toString().trim() ?? '',
    );
  }

  static VizChartData? fromFenceJson(String raw) {
    try {
      final v = jsonDecode(raw.trim());
      if (v is! Map) return null;
      return fromBlockBody(Map<String, dynamic>.from(v));
    } catch (_) {
      return null;
    }
  }

  static List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
  }
}
