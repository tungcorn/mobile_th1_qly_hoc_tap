# KỊCH BẢN QUAY VIDEO TH2 (OBS)

Thời lượng mục tiêu: **11 phút**, điều chỉnh trong khoảng 10 đến 12 phút. Đây là kịch bản thao tác, không phải bản ghi xác nhận demo đã thành công. Chỉ nói "thành công" khi thấy kết quả trên màn hình.

Tài liệu đi kèm: [HUONG_DAN_CHAY_TH2.md](HUONG_DAN_CHAY_TH2.md), [BAO_CAO_TH2_QUAN_LY_TAI_LIEU_DA_NEN_TANG.md](BAO_CAO_TH2_QUAN_LY_TAI_LIEU_DA_NEN_TANG.md).

## Checklist trước khi quay

- [ ] Đã chạy `supabase/th2_migration.sql` trong Supabase SQL Editor (không báo lỗi).
- [ ] `flutter pub get` xong; `flutter run -d chrome --web-port=7357` chạy được, app mở ở `http://localhost:7357`.
- [ ] Nếu quay phần push: đã làm cấu hình Firebase và deploy `send-fcm` theo hướng dẫn. Nếu chưa, chỉ nói về thông báo Realtime, không nhắc push như đã chạy.
- [ ] Dữ liệu sạch: chưa nạp dữ liệu mẫu (sẽ nạp trong video). Tài khoản demo A, B, C có sẵn trong bộ chuyển.
- [ ] Mở sẵn các tab: báo cáo (mục 1 có sơ đồ), `supabase/th2_migration.sql`, Supabase Dashboard (SQL Editor + Table Editor), app, terminal tại thư mục dự án.
- [ ] Đã chạy thử `flutter test`, `flutter analyze` một lần để biết thời gian và kết quả; ghi kết quả vào báo cáo mục 6.
- [ ] Mạng ổn định (tile OpenStreetMap và Supabase cần Internet). Trình duyệt cho phép quyền vị trí ở `localhost`.
- [ ] OBS: ghi 1920x1080, 30 fps, bật micro, kiểm tra âm lượng; tắt thông báo hệ thống; đóng tab và ứng dụng không liên quan.
- [ ] Ẩn thông tin nhạy cảm: `anon key`, service role key, email cá nhân thật, mật khẩu. Không mở tệp chứa khóa bí mật trên màn hình.
- [ ] Điền tên nhóm và thành viên thật; không đọc placeholder.
- [ ] Zoom trình duyệt 100%, cỡ chữ terminal đủ lớn để đọc khi xem video.

---

## Cảnh 1. Giới thiệu và kiến trúc (00:00 đến 01:15)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 00:00 đến 00:25 | Trang tiêu đề hoặc báo cáo mục đầu; sau đó app ở màn hình đăng nhập | "Xin chào, nhóm em là [tên nhóm], gồm [thành viên]. Chúng em trình bày TH2: hệ thống quản lý tài liệu đa nền tảng StudyDoc, viết bằng Flutter, chạy trên Web và Android." |
| 00:25 đến 00:55 | Báo cáo, mục 1.1, sơ đồ kiến trúc mermaid; chỉ chuột lần lượt vào Firebase, Supabase | "Firebase lo hai việc: đăng nhập Google và Cloud Messaging. Supabase lo dữ liệu Postgres có Row Level Security, lưu tệp ở Storage, thông báo thời gian thực bằng Realtime, và Edge Function gửi push FCM." |
| 00:55 đến 01:15 | Mở `supabase/th2_migration.sql`, cuộn qua phần cột mới, bảng mới, chính sách RLS | "Toàn bộ cấu trúc dữ liệu TH2 nằm trong một tệp migration. Tệp có thêm cột tag, vị trí, công khai; bảng mượn tài liệu và lịch sử xem; cùng chính sách RLS. Tệp chạy lại nhiều lần không lỗi." |

## Cảnh 2. Chạy migration trên Supabase (01:15 đến 02:00)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 01:15 đến 01:40 | Supabase Dashboard, SQL Editor, New query; dán nội dung `th2_migration.sql`; bấm Run | "Em vào SQL Editor, dán toàn bộ tệp migration và bấm Run." |
| 01:40 đến 02:00 | Kết quả "Success"; mở Table Editor thấy `borrow_requests`, `document_views`; mở Storage thấy bucket `documents` | "Migration chạy xong. Đã có hai bảng mới và bucket documents để lưu tệp." |

Nếu lệnh lỗi, dừng quay, sửa lỗi rồi quay lại cảnh này; không quay đoạn giả thành công.

## Cảnh 3. Khởi chạy ứng dụng Web (02:00 đến 02:30)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 02:00 đến 02:15 | Terminal: `flutter pub get` (đã chạy sẵn), rồi `flutter run -d chrome --web-port=7357` | "Em chạy ứng dụng Web bằng lệnh flutter run với cổng 7357." |
| 02:15 đến 02:30 | Chrome mở app; đăng nhập (hoặc vào tài khoản demo A); thấy thanh điều hướng "Tài liệu, Khám phá, Mượn trả, Bản đồ" | "Ứng dụng có bốn mục: Tài liệu, Khám phá, Mượn trả và Bản đồ. Em đang dùng tài khoản demo A." |

Người dùng tự thao tác đăng nhập Google nếu dùng; không quay mật khẩu hoặc mã xác minh.

## Cảnh 4. Responsive (02:30 đến 03:30)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 02:30 đến 03:00 | Kéo thu nhỏ dần cửa sổ Chrome từ rộng xuống hẹp; chỉ vào thanh bên trái chuyển thành thanh dưới đáy | "Khi cửa sổ rộng, ứng dụng dùng thanh điều hướng bên trái, NavigationRail. Khi thu hẹp dưới ngưỡng 600 pixel, nó chuyển sang thanh điều hướng dưới đáy, NavigationBar, như trên điện thoại." |
| 03:00 đến 03:30 | F12, bật Device Toolbar (Ctrl+Shift+M), chọn kích thước điện thoại (vd 390 px); chuyển qua các tab; sau đó chọn cỡ tablet và desktop | "Em kiểm tra bằng Chrome DevTools. Có các ngưỡng 600, 840 và 1200 pixel: điện thoại, tablet và desktop. Nội dung đổi số cột và giới hạn chiều rộng theo từng ngưỡng." |

Khi quay, đối chiếu với bảng mục 2 của báo cáo; nếu bố cục thực tế khác bảng, sửa lời dẫn theo màn hình thật.

## Cảnh 5. Tạo dữ liệu mẫu (03:30 đến 04:00)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 03:30 đến 04:00 | Mở menu, chọn "Tạo dữ liệu mẫu TH2"; chờ xong; danh sách tài liệu xuất hiện với tag và vị trí | "Để demo nhanh, em dùng chức năng Tạo dữ liệu mẫu TH2. Hệ thống tạo các tài liệu có tag, vị trí và lượt xem để thử các chức năng tiếp theo." |

## Cảnh 6. Tag: thêm và lọc (04:00 đến 05:00)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 04:00 đến 04:30 | Mở một tài liệu để sửa (hoặc tạo mới); trong ô "Thêm tag" gõ `Flutter` rồi Enter, gõ `#Dart ` (có dấu cách), gõ `firebase,`; chỉ vào chip `#flutter`, `#dart`, `#firebase` và bộ đếm 3/10 | "Tag nhập bằng Enter, dấu phẩy, hoặc gõ dấu thăng rồi dấu cách. Hệ thống chuẩn hóa: bỏ dấu thăng đầu, chuyển chữ thường, tối đa 24 ký tự, tối đa 10 tag và không trùng. Dưới ô nhập có gợi ý tag đã dùng." |
| 04:30 đến 05:00 | Lưu; ở danh sách chạm vào chip tag để lọc; chọn hai tag liên tiếp | "Chạm vào tag để lọc. Khi chọn hai tag, chỉ tài liệu chứa cả hai tag mới hiện. Cột tag có chỉ mục GIN nên lọc vẫn nhanh khi dữ liệu lớn." |

## Cảnh 7. Vị trí: chọn trên bản đồ và tab Bản đồ (05:00 đến 06:00)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 05:00 đến 05:35 | Sửa tài liệu, nhấn chọn vị trí; trang "Chọn vị trí": chạm bản đồ đặt ghim; bấm "Vị trí hiện tại" (cho phép quyền); nhập "Tên nơi cất giữ" hoặc chọn chip "Thư viện trường"; bấm "Xác nhận vị trí" | "Bản đồ dùng OpenStreetMap qua flutter_map. Em chạm để đặt ghim hoặc dùng vị trí hiện tại qua geolocator. Em ghi thêm tên nơi cất giữ vật lý, ví dụ Thư viện trường, để biết bản giấy đang ở đâu." |
| 05:35 đến 06:00 | Chuyển sang tab "Bản đồ"; thấy các ghim; chạm một ghim để mở tài liệu | "Tab Bản đồ hiển thị mọi tài liệu có vị trí và tự căn khung theo các ghim. Chạm vào ghim để mở tài liệu." |

Nếu trình duyệt từ chối vị trí, nói rõ: vị trí hiện tại trên Web cần localhost hoặc https, và vẫn chọn được bằng cách chạm bản đồ.

## Cảnh 8. Chia sẻ qua email (06:00 đến 06:40)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 06:00 đến 06:40 | Ở tài liệu của A, mở chia sẻ, nhập email tài khoản demo C, chọn quyền "viewer", chia sẻ; hiện trong danh sách người được chia sẻ; thu hồi (tùy chọn) | "Chủ tài liệu chia sẻ trực tiếp bằng email, với quyền xem hoặc quyền sửa. Quyền được lưu trong bảng document_permissions và do RLS thực thi. Không có trong bảng thì người khác không đọc được tài liệu riêng tư." |

## Cảnh 9. Luồng mượn, thông báo và trả (06:40 đến 08:40)

Chuẩn bị: tài liệu của A đã bật công khai. Mở A và B ở hai cửa sổ hoặc dùng bộ chuyển tài khoản demo. Nếu dùng hai cửa sổ, đặt cạnh nhau để thấy chuông cập nhật ngay.

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 06:40 đến 07:10 | Chuyển sang B; vào "Khám phá", tìm tài liệu của A, bấm mượn; nhập lời nhắn và hạn trả; gửi | "Giờ em đóng vai người mượn, tài khoản B. Trong Khám phá em chọn tài liệu công khai của A, nhập lời nhắn và hạn trả, rồi gửi yêu cầu. Yêu cầu có trạng thái Đang chờ duyệt." |
| 07:10 đến 07:35 | Chuyển sang A; chuông thông báo hiện số mới; mở danh sách thông báo; vào "Mượn trả", thấy yêu cầu của B | "Bên chủ tài liệu, chuông thông báo nhận ngay thông báo mới qua Supabase Realtime, không cần tải lại trang. Yêu cầu hiện trong mục Mượn trả." |
| 07:35 đến 07:55 | A bấm "Duyệt"; trạng thái chuyển "Đã duyệt" | "Em duyệt yêu cầu. Hệ thống cấp cho B quyền xem có thời hạn, bằng đúng hạn trả đã chọn." |
| 07:55 đến 08:20 | Chuyển sang B; chuông có thông báo; mở mục "Được chia sẻ", thấy tài liệu của A; mở xem | "B nhận thông báo đã được duyệt và thấy tài liệu trong mục Được chia sẻ. Khi hết hạn, quyền tự mất hiệu lực ở tầng cơ sở dữ liệu, vì RLS chỉ tính quyền còn hạn." |
| 08:20 đến 08:40 | B bấm "Trả"; trạng thái "Đã trả"; làm mới "Được chia sẻ", tài liệu biến mất | "B trả tài liệu. Trạng thái chuyển sang Đã trả và quyền mượn bị thu hồi, nên tài liệu không còn trong Được chia sẻ." |

Có thể quay thêm nhánh Từ chối hoặc Hủy nếu còn thời gian. Nếu đã cấu hình FCM, nói thêm một câu: push FCM gửi qua Edge Function send-fcm là kênh bổ sung khi app không mở. Nếu chưa cấu hình, không nhắc như đã chạy.

## Cảnh 10. Gợi ý trong Khám phá (08:40 đến 09:30)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 08:40 đến 09:05 | Dùng tài khoản chưa có lịch sử (vd C): mở "Khám phá", thấy gợi ý với lý do "Phổ biến" | "Khi người dùng chưa có sở thích, hệ thống ở trạng thái cold start. Điểm chỉ dựa vào độ phổ biến, chiếm 0,7, và độ mới, chiếm 0,3. Lý do hiển thị là Phổ biến." |
| 09:05 đến 09:30 | Đặt tag yêu thích (vd `flutter`, `firebase`); danh sách gợi ý đổi; chỉ vào lý do "Trùng tag: #flutter" và điểm | "Sau khi chọn tag yêu thích, điểm là 0,7 nhân độ trùng tag, cộng 0,2 nhân độ phổ biến theo thang log, cộng 0,1 nhân độ mới giảm theo hàm mũ với bán rã khoảng 30 ngày. Tag yêu thích được 2 điểm, tài liệu đã xem 1,5 và tài liệu sở hữu 1. Mỗi gợi ý ghi rõ lý do." |

Nếu muốn, mở báo cáo mục 5.5 để chỉ bảng ví dụ tính tay.

## Cảnh 11. Kiểm thử trong terminal (09:30 đến 10:15)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 09:30 đến 09:55 | Terminal: `flutter test`; chờ kết thúc, dừng ở dòng tổng kết | "Em chạy flutter test. Bộ test gồm unit test thuật toán gợi ý, database, service, chính sách tải tệp và widget." |
| 09:55 đến 10:15 | Terminal: `flutter analyze`; dừng ở kết quả | "flutter analyze là phân tích tĩnh. Kết quả như đang hiển thị." |

Đọc đúng số test đạt và số cảnh báo hiển thị trên màn hình. Nếu có test hoặc cảnh báo lỗi, nói thẳng và ghi vào báo cáo; không cắt cảnh.

## Cảnh 12. Đóng gói (10:15 đến 10:40)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 10:15 đến 10:40 | Terminal: `flutter build web` (cắt nhanh phần chờ nếu dựng lâu), rồi `flutter build apk --release`; mở thư mục `build/web` và `build/app/outputs/flutter-apk/app-release.apk`, cho thấy dung lượng | "Em đóng gói bản Web bằng flutter build web và bản Android bằng flutter build apk release. Đầu ra là thư mục build web và tệp app-release.apk với dung lượng như trên màn hình. APK hiện ký bằng khóa debug nên chỉ dùng để demo." |

Nếu build quá lâu, quay riêng và ghép; không giả lập kết quả.

## Cảnh 13. Kết luận (10:40 đến 11:00)

| Thời gian | Hiển thị trên màn hình | Lời dẫn |
|---|---|---|
| 10:40 đến 11:00 | Báo cáo, mục "Kết luận và hướng phát triển" (phần hạn chế) | "Nhóm đã hoàn thành các chức năng: tag, vị trí và bản đồ, mượn và chia sẻ có thời hạn, thông báo thời gian thực, gợi ý và giao diện responsive. Hạn chế lớn là danh tính qua header chưa được xác minh bằng JWT. Hướng sản xuất là dùng Supabase Third-Party Auth với Firebase. Cảm ơn thầy cô đã theo dõi." |

---

## Tổng hợp thời gian

| Cảnh | Nội dung | Bắt đầu |
|---|---|---|
| 1 | Giới thiệu và kiến trúc | 00:00 |
| 2 | Chạy migration | 01:15 |
| 3 | Khởi chạy Web | 02:00 |
| 4 | Responsive | 02:30 |
| 5 | Dữ liệu mẫu | 03:30 |
| 6 | Tag | 04:00 |
| 7 | Vị trí và bản đồ | 05:00 |
| 8 | Chia sẻ qua email | 06:00 |
| 9 | Mượn, thông báo, trả | 06:40 |
| 10 | Gợi ý | 08:40 |
| 11 | Kiểm thử | 09:30 |
| 12 | Đóng gói | 10:15 |
| 13 | Kết luận | 10:40 |

## Sau khi quay

- [ ] Xem lại video: giọng đọc rõ, không lộ khóa hoặc email cá nhân.
- [ ] Điền kết quả thật của `flutter test`, `flutter analyze` và dung lượng build vào mục 6 của báo cáo.
- [ ] Nếu bố cục hoặc nhãn nút thực tế khác kịch bản, sửa lời dẫn cho khớp bản quay.
