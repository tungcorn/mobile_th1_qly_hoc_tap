import 'package:flutter/material.dart';
import '../struct/documentModels.dart';

/// [SearchFilterBar]: Thanh tìm kiếm kết hợp dải lọc tinh gọn, chuẩn Material Design 3.
/// Gom toàn bộ bộ lọc Môn học và Loại tài liệu vào một hàng duy nhất, loại bỏ tình trạng rối mắt.
class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final DocumentType? selectedType;
  final ValueChanged<DocumentType?> onTypeSelected;
  final List<SubjectItem> subjects;
  final String? selectedSubjectId;
  final ValueChanged<String?> onSubjectSelected;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedType,
    required this.onTypeSelected,
    this.subjects = const [],
    this.selectedSubjectId,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Xác định tên môn đang chọn
    String selectedSubjectLabel = 'Tất cả môn';
    Color? selectedSubjectColor;
    if (selectedSubjectId != null && selectedSubjectId != 'all') {
      final found = subjects.where((s) => s.id == selectedSubjectId);
      if (found.isNotEmpty) {
        selectedSubjectLabel = found.first.code.isNotEmpty ? found.first.code : found.first.name;
        selectedSubjectColor = found.first.color;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ô tìm kiếm tối giản (Clean Search Bar)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.8),
                width: 1,
              ),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: 'Tìm kiếm bài giảng, bài tập, ghi chú...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 17),
                        onPressed: onClearSearch,
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ),

        // 2. Dải lọc một hàng thống nhất (Unified Filter Strip)
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Chip Chọn Môn học (Dropdown PopupMenu)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: PopupMenuButton<String?>(
                  tooltip: 'Lọc theo Môn học',
                  onSelected: onSubjectSelected,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem<String?>(
                        value: null,
                        child: Text('Tất cả môn học', style: TextStyle(fontSize: 13)),
                      ),
                      const PopupMenuDivider(height: 1),
                      ...subjects.map(
                        (sub) => PopupMenuItem<String?>(
                          value: sub.id,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: sub.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sub.code.isNotEmpty ? '${sub.code} - ${sub.name}' : sub.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedSubjectId != null
                          ? theme.colorScheme.primaryContainer.withOpacity(0.6)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedSubjectId != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedSubjectColor != null) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: selectedSubjectColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ] else ...[
                          Icon(
                            Icons.school_outlined,
                            size: 13,
                            color: selectedSubjectId != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          selectedSubjectLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedSubjectId != null ? FontWeight.w600 : FontWeight.w500,
                            color: selectedSubjectId != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: selectedSubjectId != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Chip "Tất cả"
              _buildTypeChip(
                context: context,
                label: 'Tất cả',
                isSelected: selectedType == null,
                onTap: () => onTypeSelected(null),
              ),

              // Chips từng loại tài liệu
              ...DocumentType.values.map((type) {
                final isSelected = selectedType == type;
                return _buildTypeChip(
                  context: context,
                  label: type.displayName,
                  icon: type.icon,
                  iconColor: type.color,
                  isSelected: isSelected,
                  onTap: () => onTypeSelected(isSelected ? null : type),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required BuildContext context,
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: isSelected ? theme.colorScheme.onPrimary : iconColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
