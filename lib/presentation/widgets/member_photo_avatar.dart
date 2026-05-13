import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MemberPhotoAvatar extends StatelessWidget {
  final String? base64Photo;
  final String name;
  final double radius;
  final double borderWidth;
  final Color? borderColor;

  const MemberPhotoAvatar({
    super.key,
    required this.base64Photo,
    required this.name,
    this.radius = 28.0,
    this.borderWidth = 1.5,
    this.borderColor,
  });

  String _getInitials() {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _openFullScreenPhoto(BuildContext context) {
    if (base64Photo == null || base64Photo!.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.9),
        pageBuilder: (context, _, __) {
          return FullScreenPhotoViewer(
            base64Photo: base64Photo!,
            name: name,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finalBorderColor = borderColor ?? AppColors.border;
    final hasPhoto = base64Photo != null && base64Photo!.isNotEmpty;

    Widget avatarChild;
    if (hasPhoto) {
      try {
        final decodedBytes = base64Decode(base64Photo!);
        avatarChild = Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (context, error, stackTrace) => _buildInitialsPlaceholder(),
        );
      } catch (_) {
        avatarChild = _buildInitialsPlaceholder();
      }
    } else {
      avatarChild = _buildInitialsPlaceholder();
    }

    return GestureDetector(
      onTap: hasPhoto ? () => _openFullScreenPhoto(context) : null,
      child: MouseRegion(
        cursor: hasPhoto ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: finalBorderColor,
              width: borderWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius * 2),
            child: avatarChild,
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsPlaceholder() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        gradient: AppColors.cyberGlow,
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class FullScreenPhotoViewer extends StatelessWidget {
  final String base64Photo;
  final String name;

  const FullScreenPhotoViewer({
    super.key,
    required this.base64Photo,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final decodedBytes = base64Decode(base64Photo);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background click to pop
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // Panning/Zooming center interactive image
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  decodedBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Float Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),

          // Pinch instruction tooltip
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Pinch to Zoom / Drag to Pan',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
