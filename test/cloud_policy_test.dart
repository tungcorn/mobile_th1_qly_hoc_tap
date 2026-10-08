import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_doc_manager/cloud/cloudDocument.dart';

void main() {
  CloudUpload upload({
    String title = 'Bài giảng Cloud',
    String subject = 'Cloud',
    String note = '',
    String fileName = 'bai_giang.pdf',
    int size = 8,
  }) => CloudUpload(
    title: title,
    subject: subject,
    note: note,
    fileName: fileName,
    bytes: Uint8List(size),
  );

  test('Accept a valid nonempty file at the exact size limit', () {
    expect(
      () => CloudFilePolicy.validate(upload(size: CloudFilePolicy.maxBytes)),
      returnsNormally,
    );
  });
  test('Reject an oversized file', () {
    expect(
      () =>
          CloudFilePolicy.validate(upload(size: CloudFilePolicy.maxBytes + 1)),
      throwsArgumentError,
    );
  });
  test('Reject an empty file', () {
    expect(
      () => CloudFilePolicy.validate(upload(size: 0)),
      throwsArgumentError,
    );
  });
  test('Reject unsupported extensions and accept mixed case PDF', () {
    expect(
      () => CloudFilePolicy.validate(upload(fileName: 'malware.exe')),
      throwsArgumentError,
    );
    expect(CloudFilePolicy.contentTypeFor('BaiGiang.PDF'), 'application/pdf');
  });
  test('Reject file names containing paths', () {
    for (final fileName in ['../file.pdf', 'dir/file.pdf', r'dir\file.pdf']) {
      expect(
        () => CloudFilePolicy.validate(upload(fileName: fileName)),
        throwsArgumentError,
      );
    }
  });
  test('Reject empty and oversized metadata at the upload boundary', () {
    for (final candidate in [
      upload(title: ' '),
      upload(title: 'a' * 251),
      upload(subject: ''),
      upload(subject: 'a' * 121),
      upload(note: 'a' * 4001),
    ]) {
      expect(() => CloudFilePolicy.validate(candidate), throwsArgumentError);
    }
  });
  test('Accept metadata at its exact limits', () {
    expect(
      () => CloudFilePolicy.validate(
        upload(title: 'a' * 250, subject: 'a' * 120, note: 'a' * 4000),
      ),
      returnsNormally,
    );
  });
}
