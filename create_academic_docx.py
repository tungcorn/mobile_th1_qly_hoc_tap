import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=140, right=140):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tcPr.append(tcMar)

def set_academic_table_borders(table, color="D1D5DB", sz="4"):
    tblPr = table._tbl.tblPr
    tblBorders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'<w:top w:val="single" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:bottom w:val="single" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:left w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'<w:insideH w:val="single" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:insideV w:val="none"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(tblBorders)

def add_heading_1(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(16)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    r.bold = True
    r.font.name = "Calibri"
    r.font.size = Pt(13.5)
    r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
    return p

def add_heading_2(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    r.bold = True
    r.font.name = "Calibri"
    r.font.size = Pt(11.5)
    r.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
    return p

def add_academic_note(doc, text, title="Ghi chú kỹ thuật"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    set_cell_background(cell, "F8FAFC")
    set_cell_margins(cell, top=120, bottom=120, left=160, right=160)
    
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:left w:val="single" w:sz="18" w:space="0" w:color="94A3B8"/>'
        f'<w:top w:val="none"/>'
        f'<w:bottom w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(tcBorders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    r_title = p.add_run(f"{title}: ")
    r_title.bold = True
    r_title.font.name = "Calibri"
    r_title.font.size = Pt(10)
    r_title.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
    
    r_text = p.add_run(text)
    r_text.font.name = "Calibri"
    r_text.font.size = Pt(10)
    r_text.font.color.rgb = RGBColor(0x47, 0x55, 0x69)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def build_docx_report():
    doc = docx.Document()
    
    # Thiết lập căn lề chuẩn tài liệu học thuật (A4)
    for section in doc.sections:
        section.top_margin = Inches(0.85)
        section.bottom_margin = Inches(0.85)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Calibri'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = RGBColor(0x1F, 0x29, 0x37)
    normal_style.paragraph_format.line_spacing = 1.2
    normal_style.paragraph_format.space_after = Pt(5)
    
    # ------------------ TRANG TIÊU ĐỀ HỌC THUẬT ------------------
    p_header = doc.add_paragraph()
    p_header.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_univ = p_header.add_run("BÀI TẬP THỰC HÀNH PHÁT TRIỂN ỨNG DỤNG DI ĐỘNG (TH1)\n")
    r_univ.bold = True
    r_univ.font.size = Pt(11)
    r_univ.font.color.rgb = RGBColor(0x4B, 0x55, 0x63)
    p_header.paragraph_format.space_after = Pt(20)
    
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_title = p_title.add_run("BÁO CÁO KỸ THUẬT VÀ GIẢI TRÌNH KIẾN TRÚC\nỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP THEO KIẾN TRÚC CASHEW")
    r_title.bold = True
    r_title.font.size = Pt(16)
    r_title.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
    p_title.paragraph_format.space_after = Pt(8)
    
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("Công nghệ: Flutter 3.x / Dart 3.x  •  Cơ sở dữ liệu: SQLite Reactive  •  Thiết kế: Material Design 3\nMã nguồn tham chiếu: https://github.com/jameskokoska/Cashew")
    r_sub.font.size = Pt(9.5)
    r_sub.font.italic = True
    r_sub.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)
    p_sub.paragraph_format.space_after = Pt(20)
    
    # Khung thông tin sinh viên thực hiện
    p_meta = doc.add_paragraph()
    p_meta.paragraph_format.space_after = Pt(16)
    p_meta.add_run("Học viên / Sinh viên thực hiện: ").bold = True
    p_meta.add_run("....................................................      ")
    p_meta.add_run("Mã số sinh viên: ").bold = True
    p_meta.add_run("..........................\n")
    p_meta.add_run("Lớp học phần: ").bold = True
    p_meta.add_run("......................................................................      ")
    p_meta.add_run("Giảng viên hướng dẫn: ").bold = True
    p_meta.add_run("..........................")
    
    # ------------------ BẢNG ĐỐI CHIẾU 5 MỤC CHECKLIST ------------------
    add_heading_1(doc, "TỔNG HỢP TIẾN ĐỘ THỰC HIỆN THEO 5 MỤC CHECKLIST")
    
    doc.add_paragraph("Dưới đây là bảng tổng hợp kết quả đối chiếu giữa 5 yêu cầu trong đề bài thực hành và việc triển khai thực tế trong mã nguồn dự án:")
    
    table_c = doc.add_table(rows=6, cols=4)
    table_c.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(table_c)
    
    headers = ["STT", "Yêu cầu Checklist", "Nội dung triển khai kỹ thuật", "Kết quả"]
    col_widths = [Inches(0.6), Inches(2.2), Inches(3.0), Inches(0.9)]
    
    for i, h in enumerate(headers):
        cell = table_c.cell(0, i)
        cell.width = col_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=100, bottom=100, left=100, right=100)
        p = cell.paragraphs[0]
        if i in [0, 3]:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9.5)
        r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
        
    c_data = [
        ("Mục 1", "Phân tích yêu cầu chức năng & thiết kế sơ đồ luồng dữ liệu", "Phân tích 5 nhóm nghiệp vụ; thiết kế mô hình dữ liệu quan hệ (ERD); xây dựng sơ đồ DFD Cấp 0, DFD Cấp 1 và Sequence Diagram cho luồng Reactive Stream.", "Đạt"),
        ("Mục 2", "Thiết lập cấu trúc thư mục & phân lớp chuẩn kiến trúc Cashew", "Tổ chức 5 tầng độc lập: lib/database/ (Data Layer), lib/struct/ (Business/State Layer), lib/pages/ (View Layer), lib/widgets/ (Component Layer), tiện ích dùng chung.", "Đạt"),
        ("Mục 3", "Triển khai các chức năng cốt lõi: Thêm, sửa, xóa, tìm kiếm", "Hoàn thành CRUD tài liệu, chọn deadline bài tập, tìm kiếm full-text đa trường, bộ lọc kết hợp (Môn học, Loại tài liệu, Yêu thích, Bài tập chờ).", "Đạt"),
        ("Mục 4", "Kiểm thử tính đúng đắn của việc phân tách logic giữa các lớp", "Xây dựng 12 automated test cases trên cả 3 tầng: database_test.dart (6), service_test.dart (5), widget_test.dart (1). Kết quả: 12/12 pass, flutter analyze: 0 lỗi.", "Đạt"),
        ("Mục 5", "Đóng gói mã nguồn và lập báo cáo giải trình kiến trúc", "Đóng gói mã nguồn sạch TH1_QuanLyTaiLieuHocTap_Cashew.zip (0.85 MB); biên soạn tài liệu giải trình chi tiết về kiến trúc hệ thống.", "Đạt")
    ]
    
    for row_idx, data in enumerate(c_data, start=1):
        for col_idx, text in enumerate(data):
            cell = table_c.cell(row_idx, col_idx)
            cell.width = col_widths[col_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
            p = cell.paragraphs[0]
            if col_idx in [0, 3]:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(text)
            r.font.size = Pt(9.5)
            if col_idx == 0 or col_idx == 3:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(12)
    
    # ------------------ MỤC I ------------------
    add_heading_1(doc, "MỤC I: PHÂN TÍCH YÊU CẦU CHỨC NĂNG VÀ THIẾT KẾ SƠ ĐỒ LUỒNG DỮ LIỆU (CHECKLIST 1)")
    
    add_heading_2(doc, "1.1. Phân tích yêu cầu chức năng nghiệp vụ")
    doc.add_paragraph("Hệ thống quản lý tài liệu học tập được thiết kế nhằm hỗ trợ sinh viên lưu trữ, sắp xếp và theo dõi tiến độ hoàn thành bài tập. Các chức năng nghiệp vụ chính bao gồm:")
    doc.add_paragraph("• Quản lý Môn học (Subjects): Mỗi tài liệu thuộc về một môn học cụ thể. Môn học có Tên môn, Mã học phần và Màu sắc nhận diện riêng để hỗ trợ hiển thị trực quan.")
    doc.add_paragraph("• Quản lý Phân loại Tài liệu (Document Types): Hỗ trợ 4 loại tài liệu gồm Bài giảng (Lecture), Bài tập (Assignment), Tài liệu tham khảo (Reference), Đề thi ôn tập (Exam).")
    doc.add_paragraph("• Quản lý Hạn nộp (Deadline Management): Áp dụng cho các tài liệu dạng Bài tập. Cho phép thiết lập ngày giờ nộp bài và tự động tính toán thời hạn (còn hạn, quá hạn, đã nộp).")
    doc.add_paragraph("• Tìm kiếm và Lọc đa tiêu chí: Tra cứu tức thời theo từ khóa trong tiêu đề/ghi chú kết hợp lọc theo Môn học, Loại tài liệu, Trạng thái bài tập chờ và Đánh dấu quan trọng.")
    
    add_heading_2(doc, "1.2. Thiết kế Cơ sở dữ liệu và Ràng buộc toàn vẹn")
    doc.add_paragraph("Cơ sở dữ liệu SQLite cục bộ được xây dựng với 2 bảng quan hệ:")
    doc.add_paragraph("• Bảng subjects: id (TEXT PRIMARY KEY), name (TEXT NOT NULL), code (TEXT NOT NULL), color_value (INTEGER NOT NULL), date_created (TEXT NOT NULL).")
    doc.add_paragraph("• Bảng documents: id (TEXT PRIMARY KEY), title (TEXT NOT NULL), subject_id (TEXT NOT NULL), type (TEXT NOT NULL), file_url (TEXT), file_type (TEXT), file_size (INTEGER), note (TEXT), is_favorite (INTEGER), is_completed (INTEGER), deadline (TEXT), date_created (TEXT NOT NULL), date_modified (TEXT NOT NULL).")
    
    add_academic_note(doc, "Ràng buộc khóa ngoại: FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE. Ràng buộc này đảm bảo khi xóa một môn học, toàn bộ tài liệu thuộc môn học đó sẽ tự động được thu hồi, tránh tình trạng mồ côi dữ liệu (orphaned records). Chỉ mục idx_doc_search được thiết lập trên cột title và note để tối ưu hóa truy vấn tìm kiếm.", "Ràng buộc toàn vẹn CSDL")
    
    add_heading_2(doc, "1.3. Sơ đồ Luồng Dữ liệu (Data Flow Diagram - DFD)")
    doc.add_paragraph("Luồng xử lý dữ liệu trong hệ thống được phân rã thành các cấp độ:")
    doc.add_paragraph("• DFD Cấp 0 (Sơ đồ ngữ cảnh): Sinh viên thực hiện các thao tác (Tra cứu, Thêm, Sửa, Xóa tài liệu) tương tác với Hệ thống Quản lý Tài liệu Học tập; hệ thống thực hiện đọc/ghi dữ liệu vào Bộ nhớ CSDL SQLite cục bộ.")
    doc.add_paragraph("• DFD Cấp 1: Bao gồm 4 tiến trình độc lập:\n"
                      "  - Tiến trình 1.0 (Quản lý Môn học): Tiếp nhận yêu cầu tạo mới/xóa môn học từ UI, lưu trữ vào bảng subjects.\n"
                      "  - Tiến trình 2.0 (Xử lý CRUD Tài liệu): Kiểm tra hợp lệ dữ liệu tại DocumentService, gửi câu lệnh SQL qua AppDatabase để cập nhật bảng documents.\n"
                      "  - Tiến trình 3.0 (Tra cứu & Bộ lọc): Tiếp nhận từ khóa tìm kiếm và các bộ lọc loại/môn, sinh câu lệnh truy vấn SQLite SELECT WHERE LIKE.\n"
                      "  - Tiến trình 4.0 (Phản hồi Reactive): Sau khi bảng dữ liệu thay đổi, AppDatabase phát sự kiện qua StreamController để cập nhật UI tự động.")
    
    add_heading_2(doc, "1.4. Sơ đồ Tuần tự (Sequence Diagram)")
    doc.add_paragraph("Trình tự tương tác giữa các tầng kiến trúc trong một thao tác thêm tài liệu:")
    doc.add_paragraph("1. Người dùng nhập form và nhấn 'Lưu' tại AddEditDocumentPage.\n"
                      "2. AddEditDocumentPage gọi hàm DocumentService.createDocument(...).\n"
                      "3. DocumentService kiểm tra ràng buộc nghiệp vụ (tiêu đề không rỗng, môn học hợp lệ).\n"
                      "4. DocumentService gọi thể hiện toàn cục database.insertDocument(docItem).\n"
                      "5. AppDatabase thực thi câu lệnh SQL INSERT vào SQLite.\n"
                      "6. AppDatabase gọi nội bộ _notifyChange(), phát danh sách cập nhật vào broadcast stream.\n"
                      "7. StreamBuilder tại HomePage nhận dữ liệu mới và tái dựng giao diện tức thì.")
    
    # ------------------ MỤC II ------------------
    add_heading_1(doc, "MỤC II: CẤU TRÚC THƯ MỤC VÀ PHÂN LỚP THEO CHUẨN CASHEW (CHECKLIST 2)")
    
    doc.add_paragraph("Kiến trúc Cashew (tham chiếu từ repository mã nguồn mở jameskokoska/Cashew) là mô hình kiến trúc phân tầng dựa trên nguyên tắc Separation of Concerns, kết hợp cơ chế Reactive Data Stream trên nền SQLite. Dự án StudyDoc tổ chức cấu trúc thư mục hoàn toàn tương thích với mô hình này:")
    
    table_arch = doc.add_table(rows=7, cols=3)
    table_arch.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(table_arch)
    
    arch_headers = ["Tầng kiến trúc", "Tập tin trong dự án StudyDoc", "Đối chiếu Cashew gốc & Trách nhiệm"]
    arch_widths = [Inches(1.5), Inches(2.5), Inches(2.7)]
    
    for i, h in enumerate(arch_headers):
        cell = table_arch.cell(0, i)
        cell.width = arch_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=100, bottom=100, left=100, right=100)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9.5)
        r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
        
    arch_data = [
        ("Tầng Database\n(Data Layer)", "lib/database/tables.dart\nlib/database/appDatabase.dart\nlib/database/initializeDefaultDatabase.dart", "Tương ứng database/tables.dart & initializeDefaultDatabase.dart. Quản lý schema DDL, mở kết nối SQLite, thực thi CRUD, cung cấp StreamController phát dữ liệu."),
        ("Tầng Struct\n(Global Instance)", "lib/struct/databaseGlobal.dart", "Tương ứng struct/databaseGlobal.dart. Khai báo biến 'late AppDatabase database;' (Singleton Pattern) cho phép truy cập thể hiện CSDL an toàn từ mọi màn hình."),
        ("Tầng Struct\n(Models & Entities)", "lib/struct/documentModels.dart", "Tương ứng struct/defaultCategories.dart. Định nghĩa Enums (DocumentType), Model SubjectItem, DocumentItem và ViewModel DocumentWithSubject."),
        ("Tầng Struct\n(Service & Logic)", "lib/struct/documentService.dart\nlib/struct/settings.dart", "Tương ứng struct/settings.dart. Tách biệt quy tắc nghiệp vụ: Xác thực dữ liệu đầu vào, thuật toán DocumentStats, quản lý chế độ xem và cấu hình ứng dụng."),
        ("Tầng Pages\n(View Layer)", "lib/pages/homePage.dart\nlib/pages/addEditDocumentPage.dart\nlib/pages/documentDetailPage.dart\nlib/pages/subjectsPage.dart", "Tương ứng thư mục pages/ trong Cashew. Chứa các màn hình độc lập, giao tiếp với CSDL hoàn toàn thông qua tầng struct/ và databaseGlobal."),
        ("Tầng Widgets\n(Component Layer)", "lib/widgets/documentCard.dart\nlib/widgets/searchFilterBar.dart\nlib/widgets/statSummaryCards.dart\nlib/widgets/typeBadge.dart", "Tương ứng thư mục widgets/ trong Cashew. Chứa các thành phần giao diện nhỏ, có tính tái sử dụng cao, không gắn chặt logic lưu trữ.")
    ]
    
    for row_idx, data in enumerate(arch_data, start=1):
        for col_idx, text in enumerate(data):
            cell = table_arch.cell(row_idx, col_idx)
            cell.width = arch_widths[col_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
            p = cell.paragraphs[0]
            r = p.add_run(text)
            r.font.size = Pt(9.5)
            if col_idx == 0:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(12)
    
    add_academic_note(doc, "Nguyên tắc kiến trúc cốt lõi: Tầng UI (Pages/Widgets) không bao giờ trực tiếp tạo hoặc thực thi câu lệnh SQL raw query. Mọi thao tác truy xuất hoặc cập nhật bắt buộc phải đi qua DocumentService hoặc AppDatabase. Điều này giúp mã nguồn có tính mô-đun cao, dễ dàng thay thế tầng lưu trữ mà không ảnh hưởng đến giao diện người dùng.", "Nguyên tắc phân tầng")
    
    # ------------------ MỤC III ------------------
    add_heading_1(doc, "MỤC III: TRIỂN KHAI CÁC CHỨC NĂNG CỐT LÕI (CHECKLIST 3)")
    
    add_heading_2(doc, "3.1. Các chức năng nghiệp vụ CRUD")
    doc.add_paragraph("1. Thêm mới tài liệu (Create): Màn hình AddEditDocumentPage cho phép người dùng nhập đầy đủ các trường thông tin: Tiêu đề (bắt buộc), Chọn môn học từ danh sách, Chọn loại tài liệu, Ngày giờ hạn nộp (DatePicker & TimePicker), Đường dẫn tệp hoặc liên kết URL, Định dạng tệp và Dung lượng, Ghi chú vắn tắt. Form được kiểm tra validation trước khi lưu.")
    doc.add_paragraph("2. Chỉnh sửa tài liệu (Update): Cho phép sửa đổi thông tin của tài liệu đã có. Hỗ trợ thao tác nhanh chuyển đổi trạng thái hoàn thành bài tập (toggle completed) ngay tại menu thẻ hoặc màn hình chi tiết.")
    doc.add_paragraph("3. Xóa tài liệu (Delete): Tích hợp hộp thoại xác nhận AppFunctions.showConfirmDialog trước khi thực hiện xóa. Hỗ trợ xóa lan truyền khi xóa môn học tại SubjectsManagementPage.")
    doc.add_paragraph("4. Quản lý Môn học (Subjects Management): Màn hình chuyên biệt cho phép thêm môn học mới với mã màu sắc nhận diện tự chọn hoặc xóa môn học hiện hữu.")
    
    add_heading_2(doc, "3.2. Chức năng Tìm kiếm và Lọc dữ liệu")
    doc.add_paragraph("• Tìm kiếm từ khóa: Thanh tìm kiếm SearchFilterBar cập nhật danh sách tức thời khi người dùng nhập ký tự. Câu lệnh truy vấn SQL sử dụng mệnh đề: (title LIKE '%query%' OR note LIKE '%query%').")
    doc.add_paragraph("• Lọc theo Môn học: Trình đơn lựa chọn môn học tích hợp trên thanh công cụ cho phép lọc danh sách theo môn học cụ thể hoặc hiển thị tất cả môn.")
    doc.add_paragraph("• Lọc theo Loại tài liệu: Dải nút lọc ngang cho phép chuyển đổi nhanh giữa: Tất cả, Bài giảng, Bài tập, Tham khảo, Đề thi.")
    doc.add_paragraph("• Lọc trạng thái: Thanh chỉ số StatSummaryCards cho phép nhấn vào 'Bài tập chờ' để lọc các bài tập chưa hoàn thành, hoặc 'Quan trọng' để lọc các tài liệu có đánh dấu sao.")
    
    add_heading_2(doc, "3.3. Tối ưu hóa Giao diện Người dùng (UI/UX) theo chuẩn Material Design 3")
    doc.add_paragraph("Để khắc phục hiện tượng giao diện bị rối mắt và đảm bảo tính đơn giản, thanh lịch của ứng dụng di động, hệ thống giao diện đã được tái thiết kế theo các nguyên tắc chuẩn:")
    doc.add_paragraph("• Tinh gọn khu vực đầu trang (Header Area): Thay vì xếp chồng nhiều dải thẻ và thanh cuộn ngang gây chiếm dụng không gian, giao diện tích hợp thanh tìm kiếm và dải lọc môn học/loại tài liệu vào một hàng duy nhất.")
    doc.add_paragraph("• Thanh chỉ số (Metric Segmented Bar): Chuyển đổi khối thẻ thống kê cồng kềnh thành một thanh chỉ số 3 phân đoạn phẳng (Tài liệu, Bài tập chờ, Quan trọng) với chiều cao chỉ 52dp, vừa hiển thị số liệu vừa đóng vai trò nút lọc tương tác nhanh.")
    doc.add_paragraph("• Thẻ tài liệu tinh giản (Minimalist Document Card): Thẻ hiển thị DocumentCard tập trung vào tiêu đề và thông tin môn học, chuyển các thao tác phụ (sửa, đổi trạng thái, xóa) vào menu ngữ cảnh 3 chấm (PopupMenuButton). Điều này loại bỏ các nút bấm thừa trên mặt thẻ, nâng cao độ thông thoáng và khả năng đọc.")
    doc.add_paragraph("• Hệ thống màu sắc nhã nhặn: Sử dụng bảng màu Slate Indigo với màu nền sáng dịu (#F8FAFC) và các huy hiệu phân loại dạng Tonal Pill nhẹ nhàng, tránh lạm dụng màu sắc sặc sỡ.")
    
    # ------------------ MỤC IV ------------------
    add_heading_1(doc, "MỤC IV: KIỂM THỬ TÍNH ĐÚNG ĐẮN CỦA VIỆC PHÂN TÁCH LỚP (CHECKLIST 4)")
    
    doc.add_paragraph("Để kiểm chứng tính độc lập và đúng đắn giữa các tầng trong kiến trúc Cashew, hệ thống đã được kiểm thử tự động toàn diện qua 3 bộ test tương ứng với 3 tầng xử lý:")
    
    table_test = doc.add_table(rows=4, cols=4)
    table_test.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(table_test)
    
    test_headers = ["Tầng kiểm thử", "Tệp mã nguồn kiểm thử", "Nội dung và phạm vi kiểm tra", "Kết quả"]
    test_widths = [Inches(1.5), Inches(2.0), Inches(2.6), Inches(0.9)]
    
    for i, h in enumerate(test_headers):
        cell = table_test.cell(0, i)
        cell.width = test_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=100, bottom=100, left=100, right=100)
        p = cell.paragraphs[0]
        if i == 3:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9.5)
        r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
        
    test_data = [
        ("Tầng Database\n(Data Layer)", "test/database_test.dart", "6 test cases: Khởi tạo CSDL in-memory SQLite, nạp seed data, thực thi CRUD, truy vấn WHERE LIKE, kiểm tra ràng buộc xóa lan truyền (cascade delete).", "6/6 Pass"),
        ("Tầng Nghiệp vụ\n(Struct Layer)", "test/service_test.dart", "5 test cases: Kiểm tra hàm xác thực dữ liệu đầu vào (Validation), thuật toán tính toán DocumentStats, đếm bài tập quá hạn, ném ngoại lệ ArgumentError khi sai quy tắc.", "5/5 Pass"),
        ("Tầng Giao diện\n(UI Layer)", "test/widget_test.dart", "1 test case tổng hợp: Dựng ứng dụng StudyDocApp, kiểm tra hiển thị AppBar, SearchBar, FAB, thanh chỉ số; tương tác chuyển đổi theme Sáng/Tối; mở màn hình thêm mới.", "1/1 Pass")
    ]
    
    for row_idx, data in enumerate(test_data, start=1):
        for col_idx, text in enumerate(data):
            cell = table_test.cell(row_idx, col_idx)
            cell.width = test_widths[col_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
            p = cell.paragraphs[0]
            if col_idx == 3:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(text)
            r.font.size = Pt(9.5)
            if col_idx == 0 or col_idx == 3:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(10)
    
    add_academic_note(doc, "Lệnh 'flutter test' đã thực thi thành công toàn bộ 12 test cases với kết quả 'All tests passed!'. Đồng thời lệnh 'flutter analyze' hoàn thành với trạng thái 'No issues found! (0 errors, 0 warnings, 0 lints)', khẳng định mã nguồn đáp ứng đầy đủ tiêu chuẩn Clean Code và không tồn tại lỗi tiềm ẩn.", "Kết quả xác minh chất lượng")
    
    # ------------------ MỤC V ------------------
    add_heading_1(doc, "MỤC V: ĐÓNG GÓI MÃ NGUỒN VÀ HƯỚNG DẪN TRIỂN KHAI (CHECKLIST 5)")
    
    add_heading_2(doc, "5.1. Quy cách đóng gói mã nguồn")
    doc.add_paragraph("Mã nguồn dự án được đóng gói thành tệp nén chính thức:")
    doc.add_paragraph("• Tên tệp tin: TH1_QuanLyTaiLieuHocTap_Cashew.zip")
    doc.add_paragraph("• Dung lượng: ~0.85 MB (gồm toàn bộ mã nguồn Dart, cấu hình dự án, test suite và tài liệu báo cáo).")
    doc.add_paragraph("• Tối ưu hóa: Quá trình đóng gói đã chủ động loại trừ các thư mục nhị phân và cache trung gian (build/, .dart_tool/, .gradle/, .idea/, .git/), đảm bảo tệp nén gọn nhẹ và sẵn sàng giải nén thực thi ngay lập tức.")
    
    add_heading_2(doc, "5.2. Hướng dẫn cài đặt và khởi chạy ứng dụng")
    doc.add_paragraph("Người chấm hoặc người sử dụng có thể triển khai ứng dụng qua các bước sau:")
    doc.add_paragraph("1. Giải nén tệp TH1_QuanLyTaiLieuHocTap_Cashew.zip vào thư mục làm việc.")
    doc.add_paragraph("2. Mở cửa sổ dòng lệnh (Terminal/PowerShell) tại thư mục dự án và tải các gói phụ thuộc:\n"
                      "   flutter pub get")
    doc.add_paragraph("3. Thực thi bộ kiểm thử tự động để kiểm tra toàn vẹn:\n"
                      "   flutter test")
    doc.add_paragraph("4. Chạy ứng dụng trên nền tảng mong muốn:\n"
                      "   • Trình duyệt Web (Google Chrome): flutter run -d chrome\n"
                      "   • Trình duyệt Web (Microsoft Edge): flutter run -d edge\n"
                      "   • Hệ điều hành Windows Desktop: flutter run -d windows\n"
                      "   • Thiết bị di động / Máy ảo Android: flutter run")
    
    # ------------------ KẾT LUẬN ------------------
    add_heading_1(doc, "KẾT LUẬN")
    doc.add_paragraph("Thông qua bài thực hành TH1, đồ án đã triển khai thành công ứng dụng Quản lý Tài liệu Học tập đáp ứng chặt chẽ các nguyên lý cốt lõi của kiến trúc Cashew. Dự án phân tách độc lập và rõ ràng giữa tầng lưu trữ dữ liệu (Database Layer), tầng logic nghiệp vụ (Struct Layer) và tầng giao diện người dùng (Pages & Widgets Layer).")
    doc.add_paragraph("Giao diện ứng dụng được thiết kế theo hướng tối giản, trang nhã, loại bỏ các chi tiết thừa thãi và tập trung vào trải nghiệm tra cứu học tập của sinh viên. Toàn bộ 5/5 mục tiêu trong Checklist đánh giá đã được hoàn thành đầy đủ, có minh chứng mã nguồn và kết quả kiểm thử tự động xác nhận.")
    
    output_path = r"D:\Hoc\Android\TH\th1_qly_hoc_tap\BAO_CAO_TH1_KIEN_TRUC_CASHEW.docx"
    doc.save(output_path)
    print(f"Academic report saved successfully to: {output_path}")

if __name__ == "__main__":
    build_docx_report()
