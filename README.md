# StudyDoc: quản lý tài liệu học tập và tích hợp Firebase

Ứng dụng Flutter giữ CRUD môn học/tài liệu trong SQLite và bổ sung thư viện tệp cloud riêng tư bằng Firebase Authentication, Firestore và Storage. Đây là **Public Cloud BaaS**, không phải Hybrid Cloud chỉ vì còn SQLite.

## Tài liệu nộp bài

- [Báo cáo phân tích 7 mục](PHAN_TICH_TICH_HOP_CLOUD_DMS.md).
- [Thiết lập Firebase, kiểm thử và demo](HUONG_DAN_FIREBASE_VA_DEMO.md).
- [Kịch bản quay video 8 đến 12 phút](KICH_BAN_QUAY_VIDEO.md).
- Slide: `SLIDE_FIREBASE_CLOUD_DMS.pptx`, sinh bằng `npm run slides` từ `scripts/create_firebase_slides.cjs`.

## Phạm vi chức năng

| Cục bộ | Cloud |
|---|---|
| SQLite: môn học, tài liệu, tìm kiếm metadata, yêu thích, hoàn thành, hạn nộp | Google Auth, upload tệp thật và tiến độ, metadata theo UID, tải xuống có xác thực, sửa tiêu đề/ghi chú, xóa |
| Hoạt động độc lập với thư viện cloud | PDF, DOCX, PPTX, XLSX, TXT, ZIP, PNG, JPG/JPEG; tối đa 10 MiB/tệp |

Không có sync tự động SQLite, migration tệp, offline cloud, OCR, chia sẻ/RBAC, backup/versioning. Điền sẵn metadata local nếu chọn không phải đồng bộ. SDK config không phải bí mật xác thực; quyền client được kiểm soát bằng [firestore.rules](firestore.rules) và [storage.rules](storage.rules).

Cloud hỗ trợ Chrome/Web và Android; Windows native chưa hỗ trợ cloud. Hiện chưa có Firebase project của người dùng, chưa xác nhận Google/cloud live. Tên nhóm và thông tin dự án phải do nhóm điền từ tài khoản thật.

## Chuẩn bị

Cần Flutter/Dart, Chrome, Node.js/npm; Emulator và kiểm thử Rules cần Java theo yêu cầu phiên bản Firebase CLI đang dùng. Chạy tại thư mục dự án:

```powershell
npm install
flutter pub get
dart run sqflite_common_ffi_web:setup
```

`package.json` cung cấp công cụ phát triển `firebase-tools`, `@firebase/rules-unit-testing`, `firebase`, `pptxgenjs`. Chúng không tạo thêm backend độc lập cho ứng dụng.

## Diễn tập local, không phải bằng chứng Google/cloud

Terminal 1:

```powershell
npx firebase-tools emulators:start --project demo-studydoc --only auth,firestore,storage
```

Terminal 2:

```powershell
flutter run -d chrome --web-port=7357 --dart-define=USE_FIREBASE_EMULATOR=true
```

Emulator UI: `http://127.0.0.1:4000`. Dùng tài khoản thử `alice@example.test` và `bob@example.test`, không dùng OAuth Google thật.

## Chạy Firebase thật

Chủ tài khoản nhóm tạo project, bật Google Auth, Firestore và Storage. Storage mới cần Blaze; người chịu trách nhiệm phải tự chấp thuận billing. Budget là cảnh báo, không giới hạn cứng chi phí.

Lưu cấu hình Web từ Console vào `firebase_web_config.json`, rồi chạy:

```powershell
./scripts/configure_firebase.ps1 -WebConfigPath ./firebase_web_config.json
flutter run -d chrome --web-port=7357 --dart-define-from-file=firebase_config.json
```

Trước khi chạy live phải triển khai Rules vào đúng project và cấu hình CORS theo [hướng dẫn chi tiết](HUONG_DAN_FIREBASE_VA_DEMO.md). Không dùng `demo-studydoc` làm project thật. Không gửi mật khẩu, token đăng nhập hoặc service account key.

## Kiểm tra và slide

```powershell
flutter test
flutter analyze
npm run test:rules
npm run slides
```

Kết quả lệnh cần được ghi lại khi chạy, không mặc định đã đạt. `npm run test:rules` dùng `emulators:exec`, không chứng minh Rules đã được deploy lên dự án thật. Dùng `demo_samples/tai_lieu_demo.txt` để demo, lưu bằng chứng Firestore/Storage trước khi xóa.
