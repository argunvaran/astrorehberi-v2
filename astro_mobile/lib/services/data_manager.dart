import '../models/chart_model.dart';

class DataManager {
  // Singleton pattern
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  static DataManager get instance => _instance;

  ChartData? _currentChart;

  void setChartData(ChartData data) {
    _currentChart = data;
  }

  ChartData? get currentChart => _currentChart;

  bool get hasData => _currentChart != null;
  
  // Clean data on logout or reset
  void clear() {
    _currentChart = null;
  }
}
