import 'package:flutter/material.dart';
import '../models/health_entry.dart';
import '../services/firestore_service.dart';

class HealthCard extends StatelessWidget {
  final HealthEntry entry;

  const HealthCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('Ngày: ${entry.date.toLocal().toIso8601String().split("T")[0]}'),
        subtitle: Text(
          'Cân nặng: ${entry.weight} kg\n'
          'Chiều cao: ${entry.height} cm\n'
          'Nhịp tim: ${entry.heartRate} bpm\n'
          'Huyết áp: ${entry.systolic}/${entry.diastolic} mmHg\n'
          'Ghi chú: ${entry.notes.isEmpty ? "Không có" : entry.notes}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            try {
              await firestoreService.deleteHealthEntry(entry.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xóa dữ liệu thành công')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi xóa dữ liệu: $e')),
              );
            }
          },
        ),
      ),
    );
  }
}