/// Error Utility
/// 
/// Handles error message formatting and parsing
class ErrorUtils {
  /// Format throttling error message
  /// 
  /// Extracts retry time from error message and formats it
  static String formatThrottlingError(String errorMessage) {
    // Try to extract seconds from error message
    // Format: "Request was throttled. Expected available in 81257 seconds."
    final regex = RegExp(r'(\d+)\s*seconds?', caseSensitive: false);
    final match = regex.firstMatch(errorMessage);
    
    if (match != null) {
      final seconds = int.tryParse(match.group(1) ?? '0') ?? 0;
      final formattedTime = _formatSeconds(seconds);
      return 'Request was throttled. Please try again in $formattedTime.';
    }
    
    return errorMessage;
  }

  /// Format seconds into human-readable time
  static String _formatSeconds(int seconds) {
    if (seconds < 60) {
      return '$seconds second${seconds != 1 ? 's' : ''}';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '$minutes minute${minutes != 1 ? 's' : ''}';
      }
      return '$minutes minute${minutes != 1 ? 's' : ''} and $remainingSeconds second${remainingSeconds != 1 ? 's' : ''}';
    } else {
      final hours = seconds ~/ 3600;
      final remainingMinutes = (seconds % 3600) ~/ 60;
      if (remainingMinutes == 0) {
        return '$hours hour${hours != 1 ? 's' : ''}';
      }
      return '$hours hour${hours != 1 ? 's' : ''} and $remainingMinutes minute${remainingMinutes != 1 ? 's' : ''}';
    }
  }

  /// Check if error is a throttling/rate limit error
  static bool isThrottlingError(String errorMessage) {
    return errorMessage.toLowerCase().contains('throttled') ||
           errorMessage.toLowerCase().contains('rate limit') ||
           errorMessage.toLowerCase().contains('too many requests');
  }

  /// Extract retry time in seconds from error message
  static int? extractRetrySeconds(String errorMessage) {
    final regex = RegExp(r'(\d+)\s*seconds?', caseSensitive: false);
    final match = regex.firstMatch(errorMessage);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

