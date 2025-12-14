import 'package:flutter/services.dart';

/// TextInputFormatter để tự động thêm dấu chấm khi nhập số tiền
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Loại bỏ tất cả ký tự không phải số
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Parse thành số
    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }

    // Format với dấu chấm
    String formatted = _formatNumber(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(int number) {
    final String numberString = number.toString();
    final int length = numberString.length;
    
    if (length <= 3) {
      return numberString;
    }

    // Thêm dấu chấm từ phải sang trái
    String result = '';
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        result += '.';
      }
      result += numberString[i];
    }
    
    return result;
  }
}
