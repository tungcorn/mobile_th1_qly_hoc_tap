# HƯỚNG DẪN CHẠY TH2

Hướng dẫn chạy StudyDoc Manager với các chức năng TH2: tag, vị trí/bản đồ, mượn/chia sẻ, thông báo, gợi ý. Chi tiết thiết kế xem [BAO_CAO_TH2_QUAN_LY_TAI_LIEU_DA_NEN_TANG.md](BAO_CAO_TH2_QUAN_LY_TAI_LIEU_DA_NEN_TANG.md).

## Yêu cầu

| Công cụ | Ghi chú |
|---|---|
| Flutter SDK | Có `flutter` trong PATH; kiểm tra bằng `flutter doctor` |
| Chrome | Để chạy Web |
| Thiết bị/giả lập Android | Để chạy Android |
| Tài khoản Supabase | Project đã được cấu hình trong `lib/cloud/supabaseBootstrap.dart` |
| Supabase CLI | Chỉ cần nếu deploy Edge Function (bước 3) |

## Bước 1. Chạy migration Supabase (bắt buộc)

1. Mở Supabase Dashboard, chọn project của nhóm.
2. Vào **SQL Editor**, bấm **New query**.
3. Dán toàn bộ nội dung [`supabase/th2_migration.sql`](supabase/th2_migration.sql), bấm **Run**.

Script idempotent: chạy lại nhiều lần không lỗi. Script thêm cột (`tags`, `location_name`, `latitude`, `longitude`, `is_public`, `view_count`, `expires_at`, `fcm_token`), bảng `borrow_requests` và `document_views`, RPC `record_document_view`, chính sách RLS và bucket Storage `documents`.

Kiểm tra: vào **Table Editor**, thấy bảng `borrow_requests` và `document_views`; vào **Storage**, thấy bucket `documents`.

## Bước 2. Cấu hình Firebase (tùy chọn, cho push FCM)

Bỏ qua bước này nếu chỉ cần demo mượn/chia sẻ: thông báo thời gian thực qua Supabase Realtime vẫn hoạt động, chuông thông báo vẫn nhận được khi app đang mở.

1. Trong Firebase Console, lưu cấu hình Web app vào `firebase_web_config.json`.
2. Sinh `firebase_config.json`:
   ```powershell
   ./scripts/configure_firebase.ps1 -WebConfigPath ./firebase_web_config.json
   ```
   Script từ chối `projectId` bắt đầu bằng `demo-` và không ghi đè tệp đã có.
3. Lấy **Web Push certificate (VAPID key)** tại Firebase Console, Project settings, Cloud Messaging. Truyền khi chạy bằng `--dart-define=FIREBASE_VAPID_KEY=<khóa>`.
4. Mở `web/firebase-messaging-sw.js`, thay các giá trị `YOUR_FIREBASE_API_KEY`, `YOUR_PROJECT_ID`, `YOUR_MESSAGING_SENDER_ID`, `YOUR_FIREBASE_APP_ID` bằng cấu hình thật của dự án. Service worker này cần để nhận push khi tab Web ở nền.

Không commit khóa bí mật hoặc service account vào git.

## Bước 3. Deploy Edge Function `send-fcm` (tùy chọn)

Chỉ cần nếu muốn push FCM khi app đóng. Cần hoàn tất bước 2 và đã có thiết bị lưu `fcm_token`.

```powershell
supabase functions deploy send-fcm
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(Get-Content -Raw serviceAccount.json)"
```

`serviceAccount.json` tạo tại Firebase Console, Project settings, Service accounts, Generate new private key. `SUPABASE_URL` và `SUPABASE_SERVICE_ROLE_KEY` do Supabase tự cấp. Nếu chưa deploy, app vẫn chạy bình thường (lời gọi hàm bị bỏ qua).

## Bước 4. Cài thư viện

```powershell
flutter pub get
```

## Bước 5. Chạy ứng dụng

### Web

```powershell
flutter run -d chrome --web-port=7357
```

Nếu đã cấu hình Firebase (bước 2):

```powershell
flutter run -d chrome --web-port=7357 --dart-define-from-file=firebase_config.json --dart-define=FIREBASE_VAPID_KEY=<khóa>
```

Mở `http://localhost:7357`.

### Android

Bật thiết bị hoặc giả lập, kiểm tra bằng `flutter devices`, rồi:

```powershell
flutter run -d <device-id>
```

Thêm `--dart-define-from-file=firebase_config.json` nếu đã cấu hình Firebase.

## Bước 6. Tài khoản demo A / B / C

Trong menu của trang tài liệu có bộ chuyển **tài khoản demo A / B / C**, dùng để đổi nhanh giữa ba người dùng mà không phải đăng nhập lại.

| Tài khoản | Vai trò trong demo |
|---|---|
| A | Chủ tài liệu: tạo tài liệu công khai, duyệt/từ chối yêu cầu mượn |
| B | Người mượn: gửi yêu cầu mượn, nhận thông báo, trả tài liệu |
| C | Người thứ ba: thử chia sẻ qua email, kiểm tra gợi ý |

Nạp dữ liệu mẫu: vào menu, chọn **Tạo dữ liệu mẫu TH2** (tạo tài liệu có tag, vị trí và lượt xem để thử Khám phá, Bản đồ và gợi ý).

Luồng thử nhanh:
1. Dùng A: tạo hoặc dùng tài liệu mẫu, bật công khai.
2. Chuyển sang B: vào **Khám phá**, mượn tài liệu của A.
3. Chuyển lại A: chuông thông báo hiện yêu cầu mới; vào **Mượn trả**, duyệt.
4. Chuyển sang B: tài liệu xuất hiện ở mục **Được chia sẻ**; nhấn trả khi xong.

Bốn tab điều hướng: **Tài liệu**, **Khám phá**, **Mượn trả**, **Bản đồ**.

## Bước 7. Kiểm thử và đóng gói

```powershell
flutter test
flutter analyze
flutter build web
flutter build apk --release
```

APK nằm ở `build/app/outputs/flutter-apk/app-release.apk`. Ghi kết quả thực tế vào mục 6 của báo cáo.

## Xử lý sự cố

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Lỗi nhắc `supabase/th2_migration.sql`, hoặc có `schema cache`, `does not exist`, mã `PGRST204`/`42703`/`42P01` | Chưa chạy migration, hoặc PostgREST chưa nạp lại schema | Chạy lại bước 1 (script có `NOTIFY pgrst, 'reload schema'`). Đợi vài giây rồi tải lại app |
| "bạn không có quyền thực hiện thao tác này" (mã `42501`) | RLS từ chối: sai tài khoản, hoặc quyền mượn đã hết hạn | Kiểm tra đang dùng đúng tài khoản A/B/C; kiểm tra `due_date` không nằm trong quá khứ |
| Tệp tải lên không có link công khai / "Không thể tải tệp lên Supabase Storage" | Bucket `documents` chưa tồn tại hoặc mất mạng | Chạy migration; tệp ≤ 2 MB vẫn được lưu dạng `data:` URL, tệp lớn hơn thì báo lỗi |
| Nút "Vị trí hiện tại" báo lỗi quyền hoặc không lấy được vị trí trên Web | Trình duyệt chỉ cấp vị trí cho `localhost` hoặc `https` | Chạy qua `http://localhost:7357` (không dùng IP LAN qua http); cho phép quyền vị trí trong thanh địa chỉ |
| Quyền vị trí bị chặn | Người dùng từng bấm "Chặn" | Mở cài đặt trang (biểu tượng ổ khóa) hoặc cài đặt thiết bị để cấp lại |
| Bản đồ trắng hoặc ô xám | Không tải được tile OpenStreetMap | Cần Internet; thử tải lại. Marker vẫn hiển thị, chỉ nền bản đồ thiếu |
| Không nhận thông báo | Chưa gọi `listenForUser` (chưa đăng nhập) hoặc hai app dùng hai project khác nhau | Đăng nhập lại; chắc chắn A và B cùng một project Supabase. Thông báo Realtime chỉ tới khi app đang mở |
| Không có push FCM khi đóng app | Chưa làm bước 2/3, hoặc trình duyệt từ chối quyền thông báo | Hoàn tất bước 2 và 3; cho phép thông báo; kiểm tra `users.fcm_token` có giá trị |
| `flutter run` báo Firebase chưa sẵn sàng | Thiếu `--dart-define-from-file` | Thông báo đẩy bị bỏ qua nhưng phần còn lại vẫn chạy; thêm cấu hình nếu cần push |
| Cổng 7357 đang bị dùng | Phiên `flutter run` cũ còn mở | Đóng phiên cũ hoặc đổi `--web-port` |
