import 'package:alienai_c35/c/viz/viz_chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses bar chart body', () {
    final data = VizChartData.fromBlockBody({
      'chart_type': 'bar',
      'title': 'Sales',
      'labels': ['A', 'B'],
      'series': [
        {'name': 'IDR', 'values': [10, 20]},
      ],
    });
    expect(data, isNotNull);
    expect(data!.chartType, 'bar');
    expect(data.series.first.values, [10, 20]);
  });

  test('parses chart fence json', () {
    final data = VizChartData.fromFenceJson(
      '{"chart_type":"line","labels":["Jan","Feb"],"series":[{"name":"x","values":[1,3]}]}',
    );
    expect(data?.chartType, 'line');
  });
}
