# KỊCH BẢN QUAY VIDEO STUDYDOC VÀ FIREBASE

Thời lượng mục tiêu: **10 phút 30 giây**, có thể điều chỉnh trong khoảng 8 đến 12 phút. Đây là kịch bản thao tác cần làm, không phải bản ghi xác nhận demo đã thành công.

## Chuẩn bị trước khi quay

1. Hoàn tất [hướng dẫn Firebase](HUONG_DAN_FIREBASE_VA_DEMO.md): project của nhóm, Google provider, Firestore/Storage, Blaze có người chấp thuận, Rules và CORS đúng.
2. Chạy app Chrome bằng cấu hình thật, không bật `USE_FIREBASE_EMULATOR`. Diễn tập Emulator có thể quay riêng và phải gắn nhãn “Diễn tập local, không Google/cloud thật”. **Bài nộp cần đoạn Google thật và Console thật.**
3. Chuẩn bị hai tài khoản Google được chủ tài khoản cho phép, gọi là A và B trong lời dẫn. A dùng hai hồ sơ/trình duyệt riêng; B dùng phiên khác. Không dùng email test Emulator làm bằng chứng này.
4. Chuẩn bị `demo_samples/tai_lieu_demo.txt`, đọc trước nội dung, ghi lại byte size thực tế. Không bịa số byte trong lời dẫn. Tệp nhỏ có thể upload quá nhanh để thấy các bước phần trăm, vẫn giải thích đó là tiến độ từ truyền byte.
5. Mở slide `SLIDE_FIREBASE_CLOUD_DMS.pptx`, Console Auth, Firestore và Storage. Tạo slide bằng `npm run slides` nếu chưa có. Đóng tab không liên quan, tắt thông báo và ẩn email cá nhân, số điện thoại, thông tin thẻ/hóa đơn.
6. Tên nhóm/thành viên do nhóm tự điền đúng thực tế. Không đọc placeholder thành tên thật. Người dùng tự thao tác login, MFA và billing; không quay mật khẩu, mã xác minh hoặc token.

## 00:00 đến 00:40. Giới thiệu và trạng thái

**Hình ảnh:** trang tiêu đề slide, sau đó màn hình app.

**Lời dẫn:** “Nhóm trình bày StudyDoc, ứng dụng Flutter quản lý tài liệu học tập. Bản gốc dùng SQLite trên thiết bị. Phần bổ sung dùng Firebase Authentication, Firestore và Storage để tạo thư viện tệp riêng theo tài khoản. Đây là Public Cloud BaaS. Chúng em giữ dữ liệu local riêng, không gọi đó là Hybrid Cloud hay đồng bộ SQLite.”

Đọc tên nhóm và thành viên thật. Nếu chưa có cloud thật, phải nói ngay phần chưa hoàn tất và không đọc tiếp những câu kết quả như đã đạt.

## 00:40 đến 01:50. CRUD truyền thống

**Thao tác:** ở phần local, tạo một tài liệu mẫu, chọn môn học, lưu, tìm lại, sửa ghi chú, đánh dấu hoàn thành/yêu thích nếu phù hợp, rồi xóa tài liệu local mẫu.

**Lời dẫn:** “Giao diện Flutter gọi DocumentService và AppDatabase ngay trong app. Đây là tầng nghiệp vụ local, không có backend máy chủ độc lập. SQLite lưu môn học và metadata tài liệu. Trường fileUrl là chuỗi đường dẫn hoặc liên kết, không phải BLOB chứa toàn bộ tệp. Những thao tác đang thấy không tự ghi lên Firebase.”

Giữ cảnh tài liệu trước và sau sửa/xóa để người xem thấy thao tác có hiệu lực, không chỉ thấy mở hộp thoại.

## 01:50 đến 03:00. Hạn chế, lựa chọn và kiến trúc

**Hình ảnh:** slide hạn chế, sơ đồ Mermaid hoặc slide kiến trúc tương ứng.

**Lời dẫn:** “Hạn chế chính là dữ liệu local tách theo thiết bị, đường dẫn cục bộ không dùng chung và chưa có danh tính cloud. Tìm kiếm LIKE có thể kém hiệu quả khi dữ liệu lớn nhưng nhóm chưa có benchmark để kết luận độ trễ. S3, Azure Blob và GCS là các lựa chọn object storage; bài này chọn Firebase theo yêu cầu và khả năng tích hợp Auth, Rules với Flutter.”

“Luồng local vẫn đi vào SQLite. Luồng cloud dùng Google Auth lấy UID, tải byte vào Storage và ghi metadata Firestore. Không có sync engine giữa hai kho. Điền sẵn metadata nếu dùng chỉ giúp nhập biểu mẫu, người dùng vẫn chọn tệp thật.”

## 03:00 đến 03:45. Dự án và tài khoản nhóm

**Thao tác:** mở Console thật, cho thấy project ID và vùng dịch vụ; mở quyền thành viên của project để chứng minh tài khoản nhóm sở hữu hoặc được phép quản lý. Che email cá nhân khi cần, nhưng giữ ngữ cảnh đủ chứng minh đây là project thật.

**Lời dẫn:** “Đây là dự án do tài khoản nhóm quản lý. Firestore và Storage được chọn vùng Singapore asia-southeast1. Storage mới yêu cầu Blaze, người phụ trách đã tự chấp thuận billing nếu bước này thực sự hoàn tất. Budget chỉ gửi cảnh báo, không tự ngắt chi phí. Chúng em không hiển thị dữ liệu thanh toán trong video.”

Không dựng cảnh billing giả; chỉ đọc câu xác nhận khi người chịu trách nhiệm đã làm thật.

## 03:45 đến 04:30. Đăng nhập Google thật

**Thao tác:** trong app live, nhấn đăng nhập Google, chọn A bằng popup Web. Người dùng tự xử lý bước xác thực ngoài đoạn quay nếu có thông tin nhạy cảm. Sau đó cho thấy trạng thái đăng nhập và đối chiếu UID trong Firebase Authentication.

**Lời dẫn:** “Web dùng Google popup, Android dùng google_sign_in lấy ID token rồi xác thực Firebase. Phiên quay này là Web trên Firebase thật, không dùng tài khoản alice hoặc bob của Emulator.”

Không nói Google thành công chỉ vì app hiện nút đăng nhập. Phải có phiên người dùng sau xác thực.

## 04:30 đến 05:50. Upload tệp thật và đối chiếu dữ liệu

**Thao tác:** chọn `demo_samples/tai_lieu_demo.txt`, nhập tiêu đề “Tài liệu demo cloud”, môn học và ghi chú; upload, chờ thành công. Mở Firestore document mới, rồi Storage object tương ứng.

**Lời dẫn:** “Ứng dụng tải tệp thật, không chỉ lưu một URL. Giới hạn mỗi tệp là 10 MiB, hỗ trợ PDF, DOCX, PPTX, XLSX, TXT, ZIP, PNG và JPG. Tiến độ lấy từ số byte đã truyền. MIME và đuôi tệp không phải công cụ phát hiện virus.”

“UID trong Auth khớp ownerId và nhánh users của Firestore. ID tài liệu khớp đoạn documents của storagePath. Storage có object file ở cùng đường dẫn, kích thước khớp trường size và tệp gốc.”

Phóng rõ `ownerId`, document ID, `storagePath`, `size`; đọc giá trị đã quan sát, không dùng UID hay dung lượng mẫu. Lưu ảnh hai Console trước khi chuyển cảnh.

## 05:50 đến 06:40. Cùng tài khoản ở trình duyệt thứ hai

**Thao tác:** mở hồ sơ/trình duyệt thứ hai, vào cùng app, Google A đăng nhập, refresh; cho thấy tài liệu đã upload.

**Lời dẫn:** “Cùng Google A truy cập cùng thư viện trên một phiên trình duyệt khác. Đây là dữ liệu đọc từ Firebase theo UID, không phải SQLite đã tự đồng bộ. Phần cloud hiện không cam kết hoạt động ngoại tuyến.”

Nếu kết quả không xuất hiện, dừng để kiểm tra, không chèn ảnh giả vào cảnh kết quả.

## 06:40 đến 07:30. Tài khoản khác và bảo mật

**Thao tác:** mở phiên riêng cho Google B, đăng nhập, cho thấy B không thấy tài liệu A. Nếu B đã có dữ liệu riêng, chỉ giải thích tài liệu A không hiện, không bắt buộc danh sách B phải rỗng. Quay lại A.

**Lời dẫn:** “Rules yêu cầu request.auth.uid trùng UID trong path. B không có quyền đọc dữ liệu của A. Giao diện không thấy tài liệu là một bằng chứng chức năng, còn test Rules kiểm tra trực tiếp truy cập sai UID. Cấu hình SDK không phải mật khẩu; giấu API key không thay thế quyền phía dịch vụ.”

Chỉ hiện output `npm run test:rules` nếu đã chạy, kèm kết quả thật. Không tuyên bố test passed khi chưa có log.

## 07:30 đến 08:40. Sửa, download và xóa có xác nhận

**Thao tác:** A sửa tiêu đề và ghi chú, đối chiếu Firestore. Download tệp, mở TXT bằng ứng dụng đọc và so nội dung với bản gốc. Lưu ảnh/video upload, path, size, hai tài khoản và download trước khi xóa. Sau đó xác nhận xóa đúng tài liệu thử, kiểm tra Firestore và Storage đều không còn đối tượng tương ứng.

**Lời dẫn:** “Sửa chỉ đổi tiêu đề và ghi chú. Download lấy byte bằng getData có xác thực rồi lưu bằng FileSaver, không phát hành getDownloadURL công khai. Xóa chạy Storage trước và Firestore sau, hai dịch vụ không có giao dịch nguyên tử chung. Chúng em kiểm tra cả hai nơi sau thao tác.”

Không xóa project hoặc tài liệu của người khác. Nếu một bước lỗi, ghi nhận lỗi và xử lý theo hướng dẫn, không gọi đó là xóa hoàn tất.

## 08:40 đến 09:35. Chi phí, hiệu năng và giới hạn

**Hình ảnh:** ma trận trước/sau và bảng giả định tải trong báo cáo/slide.

**Lời dẫn:** “Ví dụ 10 người, mỗi người 20 tệp trung bình 2 MiB cho 400 MiB tệp. Nếu mỗi tệp tải ba lần thì có 1.200 MiB download. Mở danh sách 20 tài liệu một lần mỗi ngày trong 30 ngày cho 6.000 lượt đọc theo giả định tải lại đầy đủ. Đây là phép tính tải, không phải hóa đơn hay cam kết miễn phí. Listener và reconnect có thể làm tăng đọc; giá phụ thuộc vùng và thời điểm.”

“CRUD local không có vòng mạng. Cloud giúp truy cập từ xa nhưng phụ thuộc mạng và chưa có số liệu để nói nhanh hơn. SQLite không tự được mã hóa. OCR, sharing/RBAC, backup/versioning, offline cloud và sync SQLite chưa được triển khai.”

## 09:35 đến 10:30. Kết luận đối chiếu 7 mục

**Hình ảnh:** checklist 7 mục và danh sách tài liệu nộp.

**Lời dẫn:** “Bài gồm bảy phần: phân tích thành phần; xác định hạn chế; chọn mô hình và dịch vụ; kiến trúc cùng luồng dữ liệu; đánh giá bảo mật, chi phí và hiệu năng; tài khoản nhóm và demo; slide cùng video. Những cảnh vừa quay là bằng chứng live chỉ cho các thao tác đã quan sát. Các chức năng còn trong lộ trình không được tính là đã có.”

Cho thấy nơi tìm báo cáo, hướng dẫn, mã nguồn, slide và video. Kết thúc bằng trạng thái thật: bước nào thành công, bước nào chưa đủ bằng chứng. Không khẳng định cloud live đã kiểm chứng nếu chỉ diễn tập Emulator.

## Kiểm tra trước khi nộp

- Video có cả CRUD local và Google/cloud thật, project thuộc quyền nhóm.
- UID, document ID, Storage path và byte size khớp trong các cảnh bằng chứng.
- Có phiên thứ hai cùng Google, Google khác, sửa, download mở được và xóa sau khi lưu bằng chứng.
- Không lộ mật khẩu, MFA, token, private key hoặc billing cá nhân.
- Slide, báo cáo và lời dẫn đều gọi đúng Public Cloud Firebase; không nhận sync/OCR/backup là đã có.
- Nhật ký test/analyze/Rules ghi kết quả thật, tách kiểm thử Emulator khỏi bằng chứng live.
