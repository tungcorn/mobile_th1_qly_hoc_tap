import 'package:flutter/material.dart';

import 'cloudUi.dart';

/// Chuẩn hóa tag: trim, bỏ '#' đầu, lowercase, tối đa 24 ký tự.
String normalizeTag(String raw) {
  var t = raw.trim().toLowerCase();
  while (t.startsWith('#')) {
    t = t.substring(1);
  }
  t = t.trim();
  if (t.length > 24) t = t.substring(0, 24);
  return t;
}

/// Ô nhập tag: Enter / dấu phẩy / dấu cách sau '#...' sẽ thêm tag.
class TagInput extends StatefulWidget {
  static const maxTags = 10;

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final List<String> suggestions;

  const TagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.suggestions = const [],
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _full => widget.tags.length >= TagInput.maxTags;

  void _add(String raw) {
    final tag = normalizeTag(raw);
    if (tag.isEmpty || _full || widget.tags.contains(tag)) return;
    widget.onChanged([...widget.tags, tag]);
  }

  void _remove(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  void _commit() {
    _add(_controller.text);
    _controller.clear();
    _focus.requestFocus();
  }

  void _onChanged(String value) {
    final startsHash = value.trimLeft().startsWith('#');
    final endsComma = value.endsWith(',');
    final endsSpace = value.endsWith(' ');
    if (endsComma || (startsHash && endsSpace)) {
      _add(value.replaceAll(',', ''));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = normalizeTag(_controller.text);
    final available = widget.suggestions
        .map(normalizeTag)
        .where((s) => s.isNotEmpty && !widget.tags.contains(s))
        .where((s) => text.isEmpty || s.contains(text))
        .toSet()
        .take(8)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          enabled: !_full,
          textInputAction: TextInputAction.done,
          maxLength: 25,
          onChanged: _onChanged,
          onSubmitted: (_) => _commit(),
          decoration: InputDecoration(
            labelText: 'Thêm tag',
            hintText: _full
                ? 'Tối đa ${TagInput.maxTags} tag'
                : 'Nhập tag rồi nhấn Enter',
            prefixIcon: const Icon(Icons.tag_rounded),
            counterText: '${widget.tags.length}/${TagInput.maxTags}',
            suffixIcon: IconButton(
              tooltip: 'Thêm tag',
              icon: const Icon(Icons.add_rounded),
              onPressed: _full ? null : _commit,
            ),
          ),
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: CloudUi.small),
          Wrap(
            spacing: CloudUi.small,
            runSpacing: CloudUi.tight,
            children: [
              for (final tag in widget.tags)
                InputChip(
                  label: Text('#$tag'),
                  onDeleted: () => _remove(tag),
                  deleteButtonTooltipMessage: 'Xóa tag $tag',
                ),
            ],
          ),
        ],
        if (available.isNotEmpty && !_full) ...[
          const SizedBox(height: CloudUi.medium),
          Text(
            'Gợi ý',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: CloudUi.tight),
          Wrap(
            spacing: CloudUi.small,
            runSpacing: CloudUi.tight,
            children: [
              for (final s in available)
                ActionChip(
                  label: Text('#$s'),
                  avatar: const Icon(Icons.add_rounded, size: 16),
                  onPressed: () => _add(s),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Danh sách chip `#tag` gọn, chỉ đọc hoặc chọn được.
class TagChips extends StatelessWidget {
  final List<String> tags;
  final ValueChanged<String>? onTap;
  final Set<String> selected;

  const TagChips({
    super.key,
    required this.tags,
    this.onTap,
    this.selected = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: CloudUi.small,
      runSpacing: CloudUi.tight,
      children: [
        for (final tag in tags)
          FilterChip(
            label: Text('#$tag'),
            selected: selected.contains(tag),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelStyle: TextStyle(
              fontSize: 12,
              color: selected.contains(tag)
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight:
                  selected.contains(tag) ? FontWeight.w600 : FontWeight.w500,
            ),
            selectedColor: scheme.primaryContainer,
            onSelected: onTap == null ? null : (_) => onTap!(tag),
          ),
      ],
    );
  }
}
