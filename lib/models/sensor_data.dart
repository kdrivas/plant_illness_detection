class BlockSensorData {
  final String blockId;
  final String rowId;
  final double phLevel;
  final double ecLevel;
  final double waterTemp;
  final int vocIndex;
  final double weatherTemp;
  final double humidity;
  final double uvIndex;
  final double moisture;
  final double waterSupplied;
  final String timestamp;

  BlockSensorData({
    required this.blockId,
    this.rowId = 'row_1',
    required this.phLevel,
    required this.ecLevel,
    required this.waterTemp,
    required this.vocIndex,
    required this.weatherTemp,
    required this.humidity,
    required this.uvIndex,
    this.moisture = 0,
    this.waterSupplied = 0,
    required this.timestamp,
  });

  factory BlockSensorData.fromJson(Map<String, dynamic> json) {
    return BlockSensorData(
      blockId: json['blockId'] ?? json['block_id'] ?? '',
      rowId: json['rowId'] ?? json['row_id'] ?? 'row_1',
      phLevel: (json['phLevel'] ?? json['ph_level'] ?? 0).toDouble(),
      ecLevel: (json['ecLevel'] ?? json['ec_level'] ?? 0).toDouble(),
      waterTemp: (json['waterTemp'] ?? json['water_temp'] ?? 0).toDouble(),
      vocIndex: json['vocIndex'] ?? json['voc_index'] ?? 0,
      weatherTemp: (json['weatherTemp'] ?? json['weather_temp'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      uvIndex: (json['uvIndex'] ?? json['uv_index'] ?? 0).toDouble(),
      moisture: (json['moisture'] ?? json['soil_moisture'] ?? 0).toDouble(),
      waterSupplied: (json['waterSupplied'] ?? json['water_supplied'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockId': blockId,
      'rowId': rowId,
      'phLevel': phLevel,
      'ecLevel': ecLevel,
      'waterTemp': waterTemp,
      'vocIndex': vocIndex,
      'weatherTemp': weatherTemp,
      'humidity': humidity,
      'uvIndex': uvIndex,
      'moisture': moisture,
      'waterSupplied': waterSupplied,
      'timestamp': timestamp,
    };
  }

  BlockSensorData copyWith({
    String? blockId,
    String? rowId,
    double? phLevel,
    double? ecLevel,
    double? waterTemp,
    int? vocIndex,
    double? weatherTemp,
    double? humidity,
    double? uvIndex,
    double? moisture,
    double? waterSupplied,
    String? timestamp,
  }) {
    return BlockSensorData(
      blockId: blockId ?? this.blockId,
      rowId: rowId ?? this.rowId,
      phLevel: phLevel ?? this.phLevel,
      ecLevel: ecLevel ?? this.ecLevel,
      waterTemp: waterTemp ?? this.waterTemp,
      vocIndex: vocIndex ?? this.vocIndex,
      weatherTemp: weatherTemp ?? this.weatherTemp,
      humidity: humidity ?? this.humidity,
      uvIndex: uvIndex ?? this.uvIndex,
      moisture: moisture ?? this.moisture,
      waterSupplied: waterSupplied ?? this.waterSupplied,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Helper methods for status evaluation
  String getPhStatus() {
    if (phLevel < 5.5) return 'Too Acidic';
    if (phLevel > 7.5) return 'Too Alkaline';
    return 'Optimal';
  }

  String getMoistureStatus() {
    if (moisture < 30) return 'Too Dry';
    if (moisture > 80) return 'Too Wet';
    return 'Optimal';
  }

  String getHumidityStatus() {
    if (humidity < 40) return 'Too Dry';
    if (humidity > 80) return 'Too Humid';
    return 'Optimal';
  }

  String getTemperatureStatus() {
    if (weatherTemp < 15) return 'Too Cold';
    if (weatherTemp > 35) return 'Too Hot';
    return 'Optimal';
  }

  String getUvStatus() {
    if (uvIndex < 2) return 'Low';
    if (uvIndex < 5) return 'Moderate';
    if (uvIndex < 8) return 'High';
    return 'Very High';
  }

  @override
  String toString() {
    return 'BlockSensorData(blockId: $blockId, phLevel: $phLevel, ecLevel: $ecLevel, '
        'waterTemp: $waterTemp, vocIndex: $vocIndex, weatherTemp: $weatherTemp, '
        'humidity: $humidity, uvIndex: $uvIndex, timestamp: $timestamp)';
  }
}

class SensorDataHistory {
  final List<BlockSensorData> data;
  final String blockId;

  SensorDataHistory({
    required this.data,
    required this.blockId,
  });

  List<double> get phHistory => data.map((d) => d.phLevel).toList();
  List<double> get ecHistory => data.map((d) => d.ecLevel).toList();
  List<double> get waterTempHistory => data.map((d) => d.waterTemp).toList();
  List<double> get humidityHistory => data.map((d) => d.humidity).toList();
  List<double> get uvHistory => data.map((d) => d.uvIndex).toList();
  List<double> get weatherTempHistory => data.map((d) => d.weatherTemp).toList();
  List<double> get moistureHistory => data.map((d) => d.moisture).toList();
  List<double> get waterSuppliedHistory => data.map((d) => d.waterSupplied).toList();
}
