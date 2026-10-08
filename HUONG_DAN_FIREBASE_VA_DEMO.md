# HƯỚNG DẪN FIREBASE VÀ DEMO STUDYDOC

## 1. Trước khi bắt đầu

Hướng dẫn này dành cho người sở hữu tài khoản nhóm. Hiện chưa có project Firebase của người dùng; các tên `REAL_PROJECT_ID` và `ACTUAL_BUCKET` dưới đây là chỗ thay bằng giá trị thật, không phải bằng chứng triển khai.

Phân biệt hai cách chạy: Emulator diễn tập local và Firebase thật để nộp bằng chứng Google/cloud. Không ghép ảnh Emulator với lời thuyết minh rằng đã lưu lên Google Cloud.

Cài Flutter/Dart, Chrome, Node.js/npm. Firebase Emulator cần Java tương thích với phiên bản CLI; kiểm tra thông báo CLI nếu thiếu Java. `gcloud` chỉ cần cho cấu hình CORS bucket thật. Chạy trong thư mục gốc:

```powershell
npm install
flutter pub get
dart run sqflite_common_ffi_web:setup
```

`npm install` đọc `package.json`, cài `firebase-tools`, `@firebase/rules-unit-testing`, `firebase`, `pptxgenjs` cho CLI/test/slide. Lệnh Dart tạo worker SQLite Web, không cấu hình Firebase.

## 2. Tạo tài khoản nhóm và project thật

1. Nhóm chọn tài khoản Google được phép sở hữu bài tập. Nếu cần tạo tài khoản mới, thành viên tự mở trang đăng ký Google, nhập thông tin thật và hoàn tất xác minh. Không chia sẻ mật khẩu trong kho mã hoặc video.
2. Người sở hữu tự đăng nhập [Firebase Console](https://console.firebase.google.com/), xử lý MFA nếu có, chọn tạo project và ghi lại project ID thực tế. Không cần bật Analytics để thực hiện CRUD của bài.
3. Trong Project settings, kiểm tra tài khoản sở hữu và quyền thành viên. Nếu mời thành viên, cấp quyền phù hợp, không chia sẻ một mật khẩu để mọi người dùng chung. Chưa biết tên nhóm thì để nhóm điền, không tạo tên giả.
4. Authentication: bắt đầu thiết lập, chọn Sign-in method, bật **Google**, chọn support email hợp lệ rồi lưu. Trong Settings/Authorized domains, thêm `localhost` nếu chưa có. Thêm hostname Hosting của nhóm khi dùng Hosting; không nhập URL có port vào mục hostname này.
5. Firestore: tạo database Native, ID **`(default)`**, chế độ production, chọn Singapore **`asia-southeast1`**. Kiểm tra vùng trước khi xác nhận vì vùng database không tùy ý đổi sau đó.
6. Storage: người chịu trách nhiệm đọc điều kiện phí và **tự chấp thuận** liên kết billing/nâng Blaze. Nếu chưa đồng ý, dừng nhánh cloud thật và diễn tập Emulator, không tuyên bố đủ bằng chứng nộp. Tạo bucket với vùng Singapore `asia-southeast1` nếu phù hợp yêu cầu, ghi lại tên bucket chính xác.
7. Thiết lập Budget alerts và theo dõi Usage/Billing. Cảnh báo không phải hard cap, có thể đến sau khi chi phí đã phát sinh.

Theo [FAQ chính thức](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024), bucket mặc định mới cần Blaze từ 30/10/2024; yêu cầu Blaze để duy trì truy cập Storage bắt đầu từ sớm nhất 02/02/2026. Không dựa vào hướng dẫn cũ “Storage luôn miễn phí trên Spark”. Chi phí phụ thuộc vùng và tải, kể cả khi một số dịch vụ có hạn mức miễn phí.

## 3. Đăng ký Web app và cấu hình Dart defines

Trong Project settings, đăng ký app **Web**. Sao chép các giá trị của đối tượng JS `firebaseConfig` từ Console vào file local `firebase_web_config.json` dưới dạng **JSON hợp lệ**, không chép dòng `const firebaseConfig =` hoặc dấu chấm phẩy. Ví dụ hình dạng, phải thay tất cả giá trị:

```json
{
  "apiKey": "GIA_TRI_THAT_TU_CONSOLE",
  "authDomain": "GIA_TRI_THAT_TU_CONSOLE",
  "projectId": "GIA_TRI_THAT_TU_CONSOLE",
  "storageBucket": "TEN_BUCKET_THAT",
  "messagingSenderId": "GIA_TRI_THAT_TU_CONSOLE",
  "appId": "APP_ID_WEB_THAT"
}
```

Không suy tên bucket từ project ID: bucket mới có thể dùng hậu tố `firebasestorage.app`, bucket cũ có thể là `appspot.com`. Dùng giá trị Console, không thêm `gs://` vào trường SDK `storageBucket`.

```powershell
./scripts/configure_firebase.ps1 -WebConfigPath ./firebase_web_config.json
```

Script tạo `firebase_config.json` local được bỏ qua bởi Git và in project ID để kiểm tra. Cách khác: dựa vào [firebase_config.example.json](firebase_config.example.json), tự tạo `firebase_config.json` với đúng sáu trường:

| JSON từ Console | Trường Dart define |
|---|---|
| `apiKey` | `FIREBASE_API_KEY` |
| `appId` | `FIREBASE_APP_ID` |
| `messagingSenderId` | `FIREBASE_MESSAGING_SENDER_ID` |
| `projectId` | `FIREBASE_PROJECT_ID` |
| `storageBucket` | `FIREBASE_STORAGE_BUCKET` |
| `authDomain` | `FIREBASE_AUTH_DOMAIN` |

`GOOGLE_SERVER_CLIENT_ID` có thể để rỗng với Web; Android cần cấu hình riêng bên dưới. App đọc `String.fromEnvironment` từ cấu hình được truyền bằng `--dart-define-from-file`, không import `firebase_options.dart`. Thay cấu hình cần khởi động/build lại; chỉ hot reload không đủ.

SDK config nhận diện app và project, không phải auth secret. Không đặt service account JSON, private key, mật khẩu hoặc CLI token trong file này. Rules mới quyết định quyền truy cập client; giấu API key không thay thế Rules.

## 4. Triển khai Rules vào đúng dự án

Lệnh sau mở luồng đăng nhập do con người hoàn tất:

```powershell
npx firebase-tools login
```

Trước khi deploy, đối chiếu project ID script in ra, Console và tài khoản CLI. Chỉ tiếp tục khi đó là dự án nhóm sở hữu hoặc được phép quản lý. Lệnh deploy thay đổi tài nguyên dùng chung của dự án:

```powershell
npx firebase-tools deploy --only firestore:rules,storage --project REAL_PROJECT_ID
```

Thay `REAL_PROJECT_ID` bằng ID đã kiểm tra. Không deploy vào dự án của người khác, không đổi Rules thành `allow read, write: if true` để chữa lỗi. Sau deploy, kiểm tra bản Rules trong Console khớp [firestore.rules](firestore.rules) và [storage.rules](storage.rules).

## 5. CORS cho download Web

`getData` trên Web cần bucket cho phép origin phù hợp. Sửa [storage.cors.json](storage.cors.json) trước khi chạy: giữ origin chính xác `http://localhost:7357`, có thể giữ `http://127.0.0.1:7357` nếu dùng, thêm **origin HTTPS Hosting của chính nhóm** khi đã có. Không dùng wildcard `*` hoặc hostname dự đoán. CORS không cấp quyền đọc tệp và không thay thế Auth/Rules.

Người có quyền bucket đăng nhập `gcloud` bằng tài khoản phù hợp, kiểm tra lại tên bucket và chạy:

```powershell
gcloud storage buckets update gs://ACTUAL_BUCKET --cors-file=storage.cors.json
```

Thay `ACTUAL_BUCKET` bằng tên thật. Đừng chỉnh bucket không thuộc phạm vi của nhóm. Sau thay đổi, thử lại download ở đúng origin; upload thành công chưa chứng minh download không vướng CORS.

## 6. Chạy thật trên Chrome và Hosting tùy chọn

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=firebase_config.json
```

Mở thư viện cloud, kiểm tra đang dùng project thật, không phải Emulator. Nhấn đăng nhập Google, người dùng tự chọn tài khoản và hoàn tất xác thực. Windows native không hỗ trợ cloud trong phạm vi app này; dùng Chrome thay cho `flutter run -d windows`.

Hosting là tùy chọn và có tác động ra bên ngoài. Sau khi chủ dự án đồng ý, đã bổ sung authorized domain và CORS đúng domain, người dùng tự chạy:

```powershell
flutter build web --dart-define-from-file=firebase_config.json
npx firebase-tools deploy --only hosting --project REAL_PROJECT_ID
```

Không gọi đây là bước đã thực hiện nếu chưa có URL thật và bằng chứng truy cập.

## 7. Android là nhánh cấu hình riêng

1. Trong cùng Firebase project, đăng ký app Android với applicationId hiện có **`com.studydoc.study_doc_manager`**.
2. Lấy SHA-1 và SHA-256 của chứng chỉ ký đang dùng, đăng ký trong Console; bản release cần fingerprint của chứng chỉ release tương ứng. Có thể chạy `./gradlew.bat signingReport` từ thư mục `android` cho bản debug.
3. Tải `google-services.json` của app Android về đúng `android/app/google-services.json`, không dùng file của project khác. Cài FlutterFire CLI theo [hướng dẫn Flutter](https://firebase.google.com/docs/flutter/setup?hl=vi), chạy cấu hình cho Android của đúng project để sinh Android options và cấu hình nền tảng.
4. Nếu CLI sinh `firebase_options.dart`, dùng nó để đối chiếu giá trị Android, **không thêm import vào app hiện tại**. App vẫn dùng Dart defines. Tạo `firebase_config.android.json` với Android `appId` và API key, cùng project ID, sender ID, bucket và authDomain của dự án.
5. Điền `GOOGLE_SERVER_CLIENT_ID` bằng OAuth client ID loại **Web** của dự án, không phải Android client ID hoặc client secret. Không trộn Web appId vào Android options.

```powershell
flutter run -d ANDROID_DEVICE_ID --dart-define-from-file=firebase_config.android.json
```

Thay `ANDROID_DEVICE_ID` bằng ID từ `flutter devices`. Đây là đăng nhập `google_sign_in` lấy ID token rồi xác thực Firebase, không phải popup Web. Cần kiểm thử riêng Android; Web chạy được không tự chứng minh Android đã cấu hình đúng.

## 8. Diễn tập Emulator, không OAuth thật

Terminal 1:

```powershell
npx firebase-tools emulators:start --project demo-studydoc --only auth,firestore,storage
```

Terminal 2:

```powershell
flutter run -d chrome --web-port=7357 --dart-define=USE_FIREBASE_EMULATOR=true
```

UI ở `http://127.0.0.1:4000`, Auth cổng 9099, Firestore 8080, Storage 9199. Chọn tài khoản test `alice@example.test` hoặc `bob@example.test`; ứng dụng quản lý luồng test, không yêu cầu đăng nhập Google thật hay bật Email/Password ở production. Các tài khoản này không phải thành viên nhóm.

Nếu chạy app trên Android emulator và Firebase emulators trên máy tính, truyền thêm `--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2`. Chrome trên máy tính dùng mặc định `127.0.0.1`. Chế độ Emulator dùng project `demo-studydoc`, không dùng cấu hình dự án thật để giả bằng chứng cloud.

## 9. Kiểm thử và checklist demo thật

```powershell
flutter test
flutter analyze
npm run test:rules
npm run slides
```

`npm run test:rules` sử dụng `emulators:exec`. Nếu đang có emulators dùng các cổng tương ứng, dừng phiên diễn tập trước để tránh xung đột. Lưu output và exit code thực tế; không tự ghi “PASS”. `npm run slides` sinh `SLIDE_FIREBASE_CLOUD_DMS.pptx` bằng `scripts/create_firebase_slides.cjs`.

Checklist live, dùng [kịch bản video](KICH_BAN_QUAY_VIDEO.md):

1. Tạo/sửa/xóa một tài liệu local để chứng minh CRUD truyền thống vẫn riêng biệt.
2. Google A đăng nhập cloud thật, chọn `demo_samples/tai_lieu_demo.txt`, nhập tiêu đề, môn học, ghi chú; quan sát tiến độ upload. Tệp phải không rỗng, tối đa 10 MiB.
3. Đối chiếu UID Auth với `ownerId`, document ID, `storagePath` và `size` trong Firestore; mở Storage đúng `users/{uid}/documents/{id}/file`, đối chiếu kích thước byte thực tế. Đây mới là bằng chứng byte đã được lưu, không chỉ có metadata.
4. Mở trình duyệt/hồ sơ thứ hai cùng Google A, refresh và kiểm tra tài liệu xuất hiện. Không gọi đó là đồng bộ SQLite.
5. Dùng Google B trong phiên riêng; xác nhận không thấy tài liệu A. Đây là kiểm tra giao diện; bài test Rules cần kiểm tra thêm truy cập trực tiếp sai UID để chứng minh quyền phía dịch vụ.
6. Quay lại A, sửa tiêu đề/ghi chú; download và mở TXT để đối chiếu nội dung. Không dùng liên kết download công khai.
7. Lưu ảnh/video bằng chứng trước, rồi xác nhận xóa tài liệu thử. Kiểm tra cả Firestore và Storage đã hết tài liệu/tệp tương ứng. Không xóa project hoặc dữ liệu của người khác.

Thử thêm đầu vào không hợp lệ: tiêu đề rỗng, tệp rỗng, đuôi không hỗ trợ hoặc tệp quá 10 MiB. Không upload dữ liệu cá nhân thật. Không yêu cầu trang Library hiện tài liệu local vì hai kho không sync.

## 10. Xử lý lỗi thường gặp

| Dấu hiệu | Kiểm tra và xử lý |
|---|---|
| `unauthorized-domain` | Thêm hostname `localhost` hoặc Hosting thật trong Auth Authorized domains; kiểm tra app/project đúng |
| `operation-not-allowed` | Bật Google provider và chọn support email trong cùng project |
| Popup bị chặn hoặc bị đóng | Cho phép popup, thử lại từ thao tác nhấn nút; người dùng tự đăng nhập |
| `permission-denied` hoặc Storage `unauthorized` | Kiểm tra phiên Auth, UID/path, schema và Rules đã deploy đúng project; không mở quyền toàn bộ |
| Storage không tạo được/không truy cập được | Kiểm tra Blaze, billing đang hoạt động, tên bucket và quyền quản trị; người chịu trách nhiệm tự xử lý billing |
| Download báo CORS | Dùng đúng origin/cổng, sửa CORS bucket thật và thử lại; CORS không chữa lỗi Rules |
| Cloud chưa cấu hình | Điền đủ sáu Dart defines, dùng config đúng nền tảng rồi khởi động lại |
| Android lỗi Google/ID token | Kiểm tra SHA-1/SHA-256, package, `google-services.json`, Web client ID và Android options |
| SQLite Web không mở được | Chạy worker setup, kiểm tra worker được phục vụ từ app, tải lại trình duyệt |
| Không kết nối Emulator | Kiểm tra tiến trình/cổng; Android emulator dùng `10.0.2.2`, không phải loopback của thiết bị |
| Metadata lỗi sau upload | Đọc thông báo; kiểm tra tệp mồ côi đúng path trong Console, chỉ dọn tệp thử do nhóm tạo |
| Xóa mới mất tệp nhưng còn metadata | Hai dịch vụ không có giao dịch chung; kiểm tra quyền/kết nối rồi thử xóa lại |

Nếu chưa thể thực hiện Google/cloud thật, ghi rõ phần còn thiếu trong bài nộp. Không thay bằng ảnh mẫu hoặc project ID bịa.

## Tài liệu chính thức

- [Flutter setup](https://firebase.google.com/docs/flutter/setup?hl=vi), [Google/federated auth](https://firebase.google.com/docs/auth/flutter/federated-auth).
- [Storage upload](https://firebase.google.com/docs/storage/flutter/upload-files), [Storage download và CORS](https://firebase.google.com/docs/storage/flutter/download-files).
- [Firestore quickstart](https://firebase.google.com/docs/firestore/quickstart), [Security Rules](https://firebase.google.com/docs/rules).
- [Storage FAQ/Blaze](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024), [Pricing](https://firebase.google.com/pricing).
