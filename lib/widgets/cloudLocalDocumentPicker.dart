import 'package:flutter/material.dart';

import '../struct/databaseGlobal.dart';
import '../struct/documentModels.dart';
import 'cloudUi.dart';

class CloudLocalDocumentPicker extends StatefulWidget {
  const CloudLocalDocumentPicker({super.key});

  @override
  State<CloudLocalDocumentPicker> createState() => _CloudLocalDocumentPickerState();
}

class _CloudLocalDocumentPickerState extends State<CloudLocalDocumentPicker> {
  List<SubjectItem> _subjects = [];
  List<DocumentWithSubject> _documents = [];
  String _subjectId = 'all';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final subjects = await database.getAllSubjects();
      final documents = await database.getFilteredDocuments(subjectId: _subjectId);
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _documents = documents;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = cloudErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CloudUi.standard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Chọn tài liệu cục bộ', style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                  tooltip: 'Đóng danh sách cục bộ',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: CloudUi.small),
            const Text('Chỉ sao chép tiêu đề, môn học và ghi chú. Sau khi chọn, bạn phải chọn lại tệp thật từ thiết bị; đây không phải đồng bộ SQLite.'),
            const SizedBox(height: CloudUi.standard),
            if (_subjects.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _subjectId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Lọc theo môn học cục bộ'),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Tất cả môn học')),
                  for (final subject in _subjects)
                    DropdownMenuItem(value: subject.id, child: Text(subject.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: _loading ? null : (value) {
                  setState(() => _subjectId = value!);
                  _load();
                },
              ),
            const SizedBox(height: CloudUi.standard),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              Flexible(
                child: SingleChildScrollView(
                  child: CloudMessage(
                    title: 'Không đọc được tài liệu cục bộ',
                    message: _error!,
                    isError: true,
                    action: OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
                  ),
                ),
              )
            else if (_documents.isEmpty)
              const Flexible(child: SingleChildScrollView(child: Text('Chưa có tài liệu cục bộ trong môn này. Bạn vẫn có thể nhập thông tin và chọn tệp trực tiếp.')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _documents.length,
                  separatorBuilder: (_, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final document = _documents[index];
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(document.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(document.subjectName, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).pop(document),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
