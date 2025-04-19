class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập cân nặng';
    }
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0) {
      return 'Cân nặng không hợp lệ';
    }
    return null;
  }

  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập chiều cao';
    }
    final height = double.tryParse(value);
    if (height == null || height <= 0) {
      return 'Chiều cao không hợp lệ';
    }
    return null;
  }

  static String? validateHeartRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập nhịp tim';
    }
    final heartRate = int.tryParse(value);
    if (heartRate == null || heartRate <= 0) {
      return 'Nhịp tim không hợp lệ';
    }
    return null;
  }

  static String? validateSystolic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập huyết áp tâm thu';
    }
    final systolic = int.tryParse(value);
    if (systolic == null || systolic <= 0) {
      return 'Huyết áp tâm thu không hợp lệ';
    }
    return null;
  }

  static String? validateDiastolic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập huyết áp tâm trương';
    }
    final diastolic = int.tryParse(value);
    if (diastolic == null || diastolic <= 0) {
      return 'Huyết áp tâm trương không hợp lệ';
    }
    return null;
  }
}