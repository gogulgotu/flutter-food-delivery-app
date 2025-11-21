import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';

/// Image Utility
/// 
/// Handles image URL construction and loading from Django REST API
class ImageUtils {
  /// Get the media base URL
  /// 
  /// Django typically serves media files from /media/ endpoint
  /// This constructs the full URL for media files
  static String getMediaBaseUrl() {
    return AppConfig.mediaBaseUrl;
  }

  /// Construct full image URL from API response
  /// 
  /// Uses the original URL from API without modification
  /// [imageUrl] - Image URL from API (can be relative or absolute)
  /// Returns the original URL as-is if it's absolute, otherwise constructs full URL
  static String getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // If already an absolute URL (starts with http:// or https://), return as is without any modification
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // If starts with //, it's a protocol-relative URL, add https:
    if (imageUrl.startsWith('//')) {
      return 'https:$imageUrl';
    }

    // If starts with /, it's a relative URL from root
    if (imageUrl.startsWith('/')) {
      final baseUrl = getMediaBaseUrl();
      // Remove trailing slash from baseUrl if present, and ensure single slash
      final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      return '$cleanBaseUrl$imageUrl';
    }

    // If starts with media/, construct full path
    if (imageUrl.startsWith('media/')) {
      final baseUrl = getMediaBaseUrl();
      final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      return '$cleanBaseUrl/$imageUrl';
    }

    // Default: assume it's a media file path
    final baseUrl = getMediaBaseUrl();
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$cleanBaseUrl/media/$imageUrl';
  }

  /// Build a network image widget with proper error handling and caching
  /// 
  /// [imageUrl] - Image URL from API
  /// [width] - Optional width
  /// [height] - Optional height
  /// [fit] - BoxFit for image
  /// [placeholder] - Widget to show while loading
  /// [errorWidget] - Widget to show on error
  static Widget buildNetworkImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
            ),
          );
    }

    final fullUrl = getImageUrl(imageUrl);
    
    if (kDebugMode) {
      debugPrint('🖼️ ImageUtils.buildNetworkImage called');
      debugPrint('   Original URL: $imageUrl');
      debugPrint('   Full URL: $fullUrl');
      debugPrint('   Is Web: $kIsWeb');
    }
    
    // For web, use Image.network directly as it handles CORS better
    if (kIsWeb) {
      return _buildWebImage(
        fullUrl: fullUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }

    // For mobile, use CachedNetworkImage first, with fallback to Image.network
    return CachedNetworkImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) => placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
      errorWidget: (context, url, error) {
        // Log errors for debugging
        if (kDebugMode) {
          debugPrint('CachedNetworkImage error: $error');
          debugPrint('URL: ${url ?? fullUrl}');
        }
        
        // Try fallback to Image.network
        return _buildFallbackImage(
          fullUrl: fullUrl,
          width: width,
          height: height,
          fit: fit,
          errorWidget: errorWidget,
        );
      },
      // Cache configuration
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
      // HTTP headers
      httpHeaders: const {
        'Accept': 'image/*',
      },
      useOldImageOnUrlChange: true,
    );
  }

  /// Build image for web platform (handles CORS better)
  static Widget _buildWebImage({
    required String fullUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (kDebugMode) {
      debugPrint('Loading image for web: $fullUrl');
    }
    
    // Clean URL - remove any newlines or whitespace that might cause issues
    final cleanUrl = fullUrl.replaceAll(RegExp(r'[\n\r\t\s]+'), '').trim();
    
    // For web, use Image.network directly
    return Image.network(
      cleanUrl,
      width: width,
      height: height,
      fit: fit,
      // Use frameBuilder for better control
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          if (kDebugMode) {
            debugPrint('✅ Image loaded synchronously: $cleanUrl');
          }
          return child;
        }
        if (frame != null) {
          // Image is loaded
          return child;
        }
        // Still loading
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          if (kDebugMode) {
            debugPrint('✅ Image loaded successfully: $cleanUrl');
          }
          return child;
        }
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ Image.network error for web: $error');
          debugPrint('❌ URL: $cleanUrl');
          debugPrint('❌ Error type: ${error.runtimeType}');
          final errorStr = error.toString().toLowerCase();
          if (errorStr.contains('cors') || 
              errorStr.contains('cross-origin') ||
              errorStr.contains('access-control') ||
              errorStr.contains('statuscode: 0')) {
            debugPrint('⚠️ CORS ERROR DETECTED - Configure CORS on Google Cloud Storage bucket');
            debugPrint('   See WEB_IMAGE_FIX.md for instructions');
          }
        }
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 32,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 4),
                    Text(
                      'CORS Error',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            );
      },
    );
  }

  /// Build fallback image using Image.network with better error handling
  static Widget _buildFallbackImage({
    required String fullUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    // Use the original URL without modification
    return Image.network(
      fullUrl,
      width: width,
      height: height,
      fit: fit,
      // Add headers that might help with CORS
      headers: const {
        'Accept': 'image/*',
      },
      // Set cache to false to avoid caching corrupted images
      cacheWidth: width != null ? width.toInt() : null,
      cacheHeight: height != null ? height.toInt() : null,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Silently fall back to error widget - errors are already handled
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            );
      },
    );
  }

  /// Check if URL is valid
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('/') ||
        url.startsWith('media/');
  }

  /// Debug: Print image URL information
  /// 
  /// Useful for debugging image loading issues
  static void debugImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('ImageUtils: Image URL is null or empty');
      return;
    }

    final fullUrl = getImageUrl(imageUrl);
    debugPrint('ImageUtils Debug:');
    debugPrint('  Original URL: $imageUrl');
    debugPrint('  Full URL: $fullUrl');
    debugPrint('  Media Base URL: ${getMediaBaseUrl()}');
    debugPrint('  Is Valid: ${isValidImageUrl(imageUrl)}');
  }
}


