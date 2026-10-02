import 'package:flutter/material.dart';
import '../struct/documentModels.dart';

/// [TypeBadge]: Huy hiệu hiển thị loại tài liệu dạng pill tonal mềm mại chuẩn Material 3
class TypeBadge extends StatelessWidget {
  final DocumentType type;
  final bool isSmall;

  const TypeBadge({
    super.key,
    required this.type,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: type.containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type.icon,
            size: isSmall ? 13 : 15,
            color: type.onContainerColor,
          ),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: type.onContainerColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
