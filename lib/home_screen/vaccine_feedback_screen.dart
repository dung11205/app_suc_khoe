import 'package:flutter/material.dart';

class VaccineFeedbackScreen extends StatelessWidget {
  const VaccineFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phản ánh tiêm chủng')),
      body: const Center(child: Text('Trang Phản ánh tiêm chủng')),
    );
  }
}
