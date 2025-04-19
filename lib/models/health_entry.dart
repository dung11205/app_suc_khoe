class HealthEntry {
  final String id;
  final String userId;
  final DateTime date;
  final double weight;
  final double height;
  final int heartRate;
  final int systolic;
  final int diastolic;
  final String notes;

  HealthEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    required this.height,
    required this.heartRate,
    required this.systolic,
    required this.diastolic,
    this.notes = '',
  });

  factory HealthEntry.fromMap(Map<String, dynamic> data, String id) {
    return HealthEntry(
      id: id,
      userId: data['userId'] ?? '',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      weight: (data['weight'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      heartRate: data['heartRate'] ?? 0,
      systolic: data['systolic'] ?? 0,
      diastolic: data['diastolic'] ?? 0,
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'weight': weight,
      'height': height,
      'heartRate': heartRate,
      'systolic': systolic,
      'diastolic': diastolic,
      'notes': notes,
    };
  }
}