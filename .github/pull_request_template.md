## Mô tả thay đổi (Description)
<!-- Tóm tắt ngắn gọn mục tiêu của Pull Request này (Bug fix, tính năng mới, tái cấu trúc, tài liệu,...). -->

- **Mục tiêu**: 
- **Chi tiết thay đổi**:
  - 

---

## Loại thay đổi (Type of Change)
<!-- Đánh dấu [x] vào các ô phù hợp -->
- [ ] **Feature**: Tính năng mới cho hệ thống.
- [ ] **Bug fix**: Sửa lỗi phát sinh trong quá trình vận hành.
- [ ] **UI/UX**: Cải thiện giao diện, tính đáp ứng (responsive), hoạt họa.
- [ ] **Performance**: Tối ưu hóa hiệu năng, giảm tải truy vấn hoặc dung lượng tệp.
- [ ] **Refactor**: Tái cấu trúc mã nguồn, không làm đổi hành vi chức năng.
- [ ] **Documentation**: Cập nhật README, báo cáo kỹ thuật, tài liệu hướng dẫn.
- [ ] **Tests**: Bổ sung hoặc cập nhật unit test, widget test.
- [ ] **CI/CD / Config**: Cấu hình pipeline, build scripts, môi trường Firebase/Supabase.

---

## Đối chiếu mục tiêu đồ án (Checklist Mapping)
<!-- Đánh dấu [x] nếu PR này đóng góp vào các tiêu chí kiểm thử của bài tập/đồ án -->
- [ ] **Mục 1 - Kiến trúc & Dữ liệu**: Tích hợp Firebase Auth / FCM + Supabase PostgreSQL (RLS), Storage, Realtime.
- [ ] **Mục 2 - Giao diện Đa nền tảng**: Responsive UI thích ứng Mobile (<600px), Tablet (600-840px), Web/Desktop (≥840px).
- [ ] **Mục 3 - Tag & Bản đồ**: Chuẩn hóa Tag (GIN index), OpenStreetMap (`flutter_map`), GPS geolocation (`geolocator`).
- [ ] **Mục 4 - Mượn & Chia sẻ quyền**: Luồng mượn 5 trạng thái (`pending`, `approved`, `rejected`, `returned`, `cancelled`), quyền truy cập có thời hạn (`expires_at`), thông báo thời gian thực.
- [ ] **Mục 5 - Thuật toán Gợi ý**: Recommendation Engine (Cosine tag similarity, view count log popularity, time decay freshness, cold-start handling).
- [ ] **Mục 6 - Đóng gói & Kiểm thử**: Test suites, static analysis, đóng gói Web / APK.

---

## Kết quả kiểm thử & Tiêu chuẩn chất lượng (Verification & Quality Gates)
<!-- Đảm bảo các lệnh kiểm tra bên dưới chạy thành công trước khi gửi PR -->
- [ ] Chạy `flutter analyze`: **0 issues** (không có lỗi lint hoặc cảnh báo cú pháp).
- [ ] Chạy `flutter test`: **100% tests pass** (tất cả unit test và widget test đều thành công).
- [ ] Kiểm tra giao diện Responsive: Đã test trên ít nhất 2 kích thước màn hình (Mobile và Web).
- [ ] Kiểm tra phân quyền: Các bảng Supabase mới/sửa đổi đều đã áp dụng Row Level Security (RLS).
- [ ] Kiểm tra bảo mật: Không commit tệp cấu hình chứa secret key (API keys, service accounts nhạy cảm).

```powershell
# Ghi lại kết quả test thực tế:
flutter analyze
flutter test
```

---

## Minh chứng kiểm thử / Hình ảnh (Screenshots & Demos)
<!-- Đính kèm ảnh chụp màn hình, GIF hoặc video mô tả sự thay đổi (nếu có liên quan đến UI/UX hoặc luồng người dùng) -->

| Trước thay đổi (Before) | Sau thay đổi (After) |
| :---: | :---: |
| *(Ảnh hoặc N/A)* | *(Ảnh hoặc N/A)* |

---

## Hướng dẫn kiểm thử cho Reviewer (Steps to Reproduce / Review)
<!-- Các bước cụ thể để reviewer có thể tự kiểm tra PR trên máy local -->
1. Checkout nhánh: `git checkout <tên_nhánh>`
2. Cập nhật thư viện: `flutter pub get`
3. Chạy kiểm thử: `flutter test`
4. Khởi chạy ứng dụng: `flutter run -d chrome` (hoặc thiết bị Android)
5. Các bước thao tác thử nghiệm tính năng:
   - Bước 1: ...
   - Bước 2: ...

---

## Ghi chú thêm (Additional Notes)
<!-- Bất kỳ lưu ý nào khác về kiến trúc, quyết định kỹ thuật hoặc giới hạn công nghệ -->
