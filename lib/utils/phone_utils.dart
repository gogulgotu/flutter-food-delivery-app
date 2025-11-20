/// Phone Utilities
/// 
/// Helper functions for phone number validation
class PhoneUtils {
  /// Validate Indian phone number
  /// 
  /// Indian mobile numbers should:
  /// - Start with +91
  /// - Have 10 digits after country code
  /// - First digit should be 6-9
  static bool isValidIndianPhoneNumber(String phoneNumber) {
    // Remove any spaces or dashes
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it starts with +91
    if (!cleaned.startsWith('+91')) {
      return false;
    }
    
    // Extract the number part (after +91)
    final numberPart = cleaned.substring(3);
    
    // Should have exactly 10 digits
    if (numberPart.length != 10) {
      return false;
    }
    
    // Should start with 6, 7, 8, or 9
    if (!RegExp(r'^[6-9]').hasMatch(numberPart)) {
      return false;
    }
    
    // Should contain only digits
    if (!RegExp(r'^\d+$').hasMatch(numberPart)) {
      return false;
    }
    
    return true;
  }

  /// Format phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.startsWith('+91') && cleaned.length == 13) {
      final numberPart = cleaned.substring(3);
      return '+91 ${numberPart.substring(0, 5)} ${numberPart.substring(5)}';
    }
    return phoneNumber;
  }
}

