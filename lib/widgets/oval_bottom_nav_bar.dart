import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Oval Bottom Navigation Bar
/// 
/// A custom bottom navigation bar with an oval-shaped design
class OvalBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<OvalNavBarItem> items;

  const OvalBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    // Adaptive sizing based on screen size
    final height = isDesktop ? 100.0 : isTablet ? 95.0 : 90.0;
    final horizontalMargin = isDesktop ? 16.0 : isTablet ? 12.0 : 8.0;
    final iconSize = isDesktop ? 26.0 : isTablet ? 25.0 : 24.0;
    final fontSize = isDesktop ? 12.0 : isTablet ? 11.5 : 11.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : isTablet ? 20 : 16,
            vertical: isDesktop ? 14 : isTablet ? 13 : 12,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Oval background
              Positioned.fill(
                child: CustomPaint(
                  painter: OvalNavBarPainter(),
                ),
              ),
              // Navigation items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = currentIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.all(isDesktop ? 10 : isTablet ? 9 : 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryGreen.withOpacity(0.15)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textMuted,
                              size: iconSize,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 6 : 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textMuted,
                            ),
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Navigation Bar Item
class OvalNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const OvalNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Custom Painter for Oval Shape
class OvalNavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.bgWhite
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create a smooth oval shape
    // Start from top-left with rounded corner
    path.moveTo(30, 0);
    
    // Top edge (rounded)
    path.lineTo(size.width - 30, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 15);
    
    // Right edge
    path.lineTo(size.width, size.height * 0.6);
    
    // Bottom right curve (oval part)
    path.quadraticBezierTo(
      size.width * 1.1,
      size.height * 0.8,
      size.width * 0.7,
      size.height,
    );
    
    // Bottom center (lowest point)
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.1,
      size.width * 0.3,
      size.height,
    );
    
    // Bottom left curve (oval part)
    path.quadraticBezierTo(
      size.width * -0.1,
      size.height * 0.8,
      0,
      size.height * 0.6,
    );
    
    // Left edge
    path.lineTo(0, 15);
    
    // Top-left rounded corner
    path.quadraticBezierTo(0, 0, 30, 0);
    
    path.close();

    // Draw shadow first (offset slightly)
    final shadowPath = Path()
      ..addPath(path, const Offset(0, 3));
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw main shape
    canvas.drawPath(path, paint);
    
    // Add subtle border
    final borderPaint = Paint()
      ..color = AppTheme.borderLight.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

