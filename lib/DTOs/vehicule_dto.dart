abstract final class VehiculeConnectors {
  static const String mennekes = 'Mennekes';
  static const String ccsCombo = 'CCS Combo';
  static const List<String> values = [mennekes, ccsCombo];

  static String normalize(Object? value) {
    final connector = value?.toString().trim() ?? '';
    final normalized = connector.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized == 'ccs combo' || normalized == 'ccs') return ccsCombo;
    if (normalized == 'mennekes' || normalized == 'type 2') return mennekes;
    return mennekes;
  }
}

class VehiculeDto {
  const VehiculeDto({
    required this.id,
    required this.brand,
    required this.model,
    required this.batteryCapacity,
    required this.rangeKm,
    required this.connector,
    required this.registrationNumber,
    required this.isPrimary,
  });

  factory VehiculeDto.fromJson(Map<String, dynamic> json) => VehiculeDto(
    id: json['_id']?.toString() ?? '',
    brand: json['brand']?.toString() ?? '',
    model: json['model']?.toString() ?? '',
    batteryCapacity: (json['batteryCapacity'] as num?)?.toDouble() ?? 0,
    rangeKm: (json['rangeKm'] as num?)?.toDouble() ?? 0,
    connector: VehiculeConnectors.normalize(json['connector']),
    registrationNumber: json['registrationNumber']?.toString() ?? '',
    isPrimary: json['isPrimary'] == true,
  );

  final String id;
  final String brand;
  final String model;
  final double batteryCapacity;
  final double rangeKm;
  final String connector;
  final String registrationNumber;
  final bool isPrimary;

  String get displayName => '$brand $model'.trim();

  Map<String, dynamic> toRequestJson() => {
    'brand': brand.trim(),
    'model': model.trim(),
    'batteryCapacity': batteryCapacity,
    'rangeKm': rangeKm,
    'connector': VehiculeConnectors.normalize(connector),
    'registrationNumber': registrationNumber.trim(),
    'isPrimary': isPrimary,
  };

  VehiculeDto copyWith({
    String? id,
    String? brand,
    String? model,
    double? batteryCapacity,
    double? rangeKm,
    String? connector,
    String? registrationNumber,
    bool? isPrimary,
  }) => VehiculeDto(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    batteryCapacity: batteryCapacity ?? this.batteryCapacity,
    rangeKm: rangeKm ?? this.rangeKm,
    connector: connector ?? this.connector,
    registrationNumber: registrationNumber ?? this.registrationNumber,
    isPrimary: isPrimary ?? this.isPrimary,
  );
}
