import os
import sys
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

def set_academic_table_borders(table, color="CBD5E1", sz="4"):
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
    p.paragraph_format.space_before = Pt(18)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    r.bold = True
    r.font.name = "Calibri"
    r.font.size = Pt(14)
    r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A) # Slate 900
    return p

def add_heading_2(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    r.bold = True
    r.font.name = "Calibri"
    r.font.size = Pt(12)
    r.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B) # Slate 800
    return p

def add_heading_3(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    r.bold = True
    r.font.name = "Calibri"
    r.font.size = Pt(11)
    r.font.color.rgb = RGBColor(0x33, 0x41, 0x55) # Slate 700
    return p

def add_callout(doc, text, title="Ghi chú kỹ thuật", border_color="2563EB", fill_hex="F8FAFC"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    set_cell_background(cell, fill_hex)
    set_cell_margins(cell, top=110, bottom=110, left=150, right=150)
    
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:left w:val="single" w:sz="24" w:space="0" w:color="{border_color}"/>'
        f'<w:top w:val="none"/>'
        f'<w:bottom w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(tcBorders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    r_title = p.add_run(f"[{title}] ")
    r_title.bold = True
    r_title.font.name = "Calibri"
    r_title.font.size = Pt(10)
    
    if border_color == "DC2626":
        r_title.font.color.rgb = RGBColor(0xDC, 0x26, 0x26)
    elif border_color == "059669":
        r_title.font.color.rgb = RGBColor(0x05, 0x96, 0x69)
    elif border_color == "D97706":
        r_title.font.color.rgb = RGBColor(0xD9, 0x77, 0x06)
    else:
        r_title.font.color.rgb = RGBColor(0x1D, 0x4E, 0xD8)
        
    r_text = p.add_run(text)
    r_text.font.name = "Calibri"
    r_text.font.size = Pt(10)
    r_text.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_code_block(doc, code_str, language="SQL"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    set_cell_background(cell, "F1F5F9") # slate 100
    set_cell_margins(cell, top=90, bottom=90, left=130, right=130)
    
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:left w:val="single" w:sz="16" w:space="0" w:color="3B82F6"/>'
        f'<w:top w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        f'<w:bottom w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        f'<w:right w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(tcBorders)
    
    lines = code_str.strip().split("\n")
    p_header = cell.paragraphs[0]
    p_header.paragraph_format.space_before = Pt(2)
    p_header.paragraph_format.space_after = Pt(2)
    r_lang = p_header.add_run(f"// --- {language} Snippet ---")
    r_lang.bold = True
    r_lang.font.name = "Consolas"
    r_lang.font.size = Pt(8.5)
    r_lang.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)
    
    for line in lines:
        p_code = cell.add_paragraph()
        p_code.paragraph_format.space_before = Pt(0)
        p_code.paragraph_format.space_after = Pt(0)
        p_code.paragraph_format.line_spacing = 1.05
        r = p_code.add_run(line)
        r.font.name = "Consolas"
        r.font.size = Pt(8.5)
        r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
        
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def setup_header_footer(doc):
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        
        header = section.header
        p_h = header.paragraphs[0]
        p_h.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        p_h.paragraph_format.space_after = Pt(4)
        r_h = p_h.add_run("Báo cáo Nghiệm thu TH2: Hệ thống Quản lý Tài liệu Đa nền tảng (StudyDoc Manager)")
        r_h.font.name = "Calibri"
        r_h.font.size = Pt(8.5)
        r_h.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)
        
        footer = section.footer
        p_f = footer.paragraphs[0]
        p_f.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_f.paragraph_format.space_before = Pt(4)
        
        r_f1 = p_f.add_run("Trang ")
        r_f1.font.name = "Calibri"
        r_f1.font.size = Pt(9)
        r_f1.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)
        
        fld1 = parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="begin"/>')
        instr1 = parse_xml(f'<w:instrText {nsdecls("w")} xml:space="preserve"> PAGE </w:instrText>')
        fld2 = parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="separate"/>')
        fld3 = parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="end"/>')
        r_f1._r.append(fld1)
        r_f1._r.append(instr1)
        r_f1._r.append(fld2)
        r_f1._r.append(fld3)
        
        r_f2 = p_f.add_run(" / ")
        r_f2.font.name = "Calibri"
        r_f2.font.size = Pt(9)
        r_f2.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)
        
        fld4 = parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="begin"/>')
        instr2 = parse_xml(f'<w:instrText {nsdecls("w")} xml:space="preserve"> NUMPAGES </w:instrText>')
        fld5 = parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="separate"/>')
        fld6 = parse_xml(f'<w:fldChar {nsdecls("w")} w:fldCharType="end"/>')
        r_f2._r.append(fld4)
        r_f2._r.append(instr2)
        r_f2._r.append(fld5)
        r_f2._r.append(fld6)

def build_full_docx_report():
    doc = docx.Document()
    setup_header_footer(doc)
    
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Calibri'
    normal_style.font.size = Pt(11)
    normal_style.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
    normal_style.paragraph_format.line_spacing = 1.2
    normal_style.paragraph_format.space_after = Pt(5)
    
    # =========================================================================
    # TRANG TIÊU ĐỀ & METADATA BÁO CÁO
    # =========================================================================
    p_header = doc.add_paragraph()
    p_header.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_univ = p_header.add_run("BÀI TẬP THỰC HÀNH PHÁT TRIỂN ỨNG DỤNG DI ĐỘNG NÂNG CAO (TH2)\n")
    r_univ.bold = True
    r_univ.font.size = Pt(11)
    r_univ.font.color.rgb = RGBColor(0x47, 0x55, 0x69)
    p_header.paragraph_format.space_after = Pt(14)
    
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_title = p_title.add_run("BÁO CÁO KỸ THUẬT & NGHIỆM THU THEO CHECKLIST 6 MỤC\nPHÁT TRIỂN HỆ THỐNG QUẢN LÝ TÀI LIỆU ĐA NỀN TẢNG\n(STUDYDOC MANAGER)")
    r_title.bold = True
    r_title.font.size = Pt(15.5)
    r_title.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
    p_title.paragraph_format.space_after = Pt(8)
    
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("Kiến trúc lai Hybrid Cloud (Firebase + Supabase) • Giao diện Responsive thích ứng Mobile/Web\nPhân loại Tag GIN Index & Bản đồ OpenStreetMap • Luồng Mượn/Duyệt & Quyền RLS có thời hạn\nThuật toán Gợi ý Cosine-Tag Recommendation • Kiểm thử toàn diện 29/29 Pass & Tự động hóa CI/CD")
    r_sub.font.size = Pt(9.5)
    r_sub.font.italic = True
    r_sub.font.color.rgb = RGBColor(0x47, 0x55, 0x69)
    p_sub.paragraph_format.space_after = Pt(18)
    
    # Metadata info box
    meta_tbl = doc.add_table(rows=2, cols=2)
    meta_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(meta_tbl, color="94A3B8")
    meta_data = [
        [("Tên dự án & Package:", "StudyDoc Manager (`study_doc_manager`)"), ("Học phần:", "Lập trình Di động Nâng cao (TH2)")],
        [("Nền tảng mục tiêu:", "Flutter (Android Native APK, Web HTML5/CanvasKit)"), ("Thời gian hoàn thành:", "Tháng 10/2026 (Phiên bản v2.0.0)")]
    ]
    for row_idx, row_content in enumerate(meta_data):
        for col_idx, (k, v) in enumerate(row_content):
            cell = meta_tbl.cell(row_idx, col_idx)
            set_cell_background(cell, "F8FAFC")
            set_cell_margins(cell, top=70, bottom=70, left=100, right=100)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            r_k = p.add_run(k + " ")
            r_k.bold = True
            r_k.font.size = Pt(9.5)
            r_k.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
            r_v = p.add_run(v)
            r_v.font.size = Pt(9.5)
            r_v.font.color.rgb = RGBColor(0x47, 0x55, 0x69)
            
    doc.add_paragraph().paragraph_format.space_after = Pt(12)
    
    # =========================================================================
    # BẢNG TỔNG HỢP TIẾN ĐỘ 6 MỤC CHECKLIST
    # =========================================================================
    add_heading_1(doc, "BẢNG TỔNG HỢP KẾT QUẢ ĐỐI CHIẾU THEO 6 MỤC CHECKLIST")
    doc.add_paragraph(
        "Dưới đây là bảng tổng hợp tiến độ và minh chứng kỹ thuật cụ thể đã triển khai trong mã nguồn dự án "
        "StudyDoc Manager, đối chiếu đầy đủ và đạt 100% tất cả 6 tiêu chí của đề bài Thực hành 2 (TH2):"
    )
    
    table_c = doc.add_table(rows=7, cols=4)
    table_c.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(table_c, color="CBD5E1")
    
    headers = ["Mục Checklist", "Yêu cầu đề bài (Mục tiêu)", "Nội dung & Giải pháp kỹ thuật đã triển khai", "Đánh giá"]
    col_widths = [Inches(1.0), Inches(1.8), Inches(3.4), Inches(0.8)]
    
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
        ("Mục 1", 
         "Thiết kế kiến trúc hệ thống và mô hình dữ liệu kết hợp giữa Firebase và Supabase.", 
         "Kiến trúc Hybrid Cloud: Firebase đảm nhiệm Danh tính (Google Sign-In PKCE) & Push Notification (FCM HTTP v1); Supabase đảm nhiệm CSDL PostgreSQL 15 chuẩn hóa (5 bảng: users, documents, document_permissions, borrow_requests, document_views), Storage bucket 'documents', Realtime broadcast (notify:{userId}) và Edge Function 'send-fcm'. Thiết lập 100% Row Level Security (RLS) với hàm SECURITY DEFINER chống đệ quy 42P17.", 
         "ĐẠT 100%"),
        ("Mục 2", 
         "Xây dựng giao diện người dùng đa nền tảng bằng Flutter, đảm bảo tính đáp ứng (responsive) cho Mobile và Web.", 
         "Một codebase Flutter duy nhất chạy mượt mà trên Android và Web. Bố cục thích ứng linh hoạt theo 4 ngưỡng Breakpoint: Mobile (<600px) dùng NavigationBar đáy; Tablet dọc (600-840px) dùng NavigationRail; Tablet ngang/Laptop (840-1200px) dùng NavigationRail + Dual-pane Layout (bản đồ và form song song); Desktop (>=1200px) căn giữa giới hạn 960px. Tích hợp chuông thông báo Realtime badge động.", 
         "ĐẠT 100%"),
        ("Mục 3", 
         "Triển khai tính năng phân loại tài liệu bằng Tag và tích hợp bản đồ/vị trí để quản lý vị trí vật lý của tài liệu.", 
         "Quản lý Tag: Lưu mảng text[] trên PostgreSQL kèm chỉ mục GIN (idx_documents_tags), truy vấn chứa tags @> ARRAY[...]. Chuẩn hóa tag tự động (bỏ #, chữ thường, tối đa 10 tag). Quản lý vị trí: Tọa độ lat/lng và location_name, tích hợp OpenStreetMap tile qua flutter_map, lấy GPS thiết bị qua geolocator, tab Bản đồ tổng quan đa ghim tự động fit khung nhìn.", 
         "ĐẠT 100%"),
        ("Mục 4", 
         "Xây dựng luồng nghiệp vụ cho phép người dùng yêu cầu mượn và chia sẻ quyền truy cập tài liệu cho người khác.", 
         "Phân định rõ Chia sẻ trực tiếp vs Mượn tài liệu. Xây dựng máy trạng thái FSM 5 bước: pending -> approved -> rejected / returned / cancelled. Khi duyệt: upsert quyền viewer có thời hạn (expires_at = due_date), bảo lưu quyền vĩnh viễn. RLS tự động vô hiệu hóa quyền quá hạn ở tầng SQL. Thông báo tức thời qua Realtime broadcast song song Edge Function FCM push.", 
         "ĐẠT 100%"),
        ("Mục 5", 
         "Phát triển thuật toán Recommendation đơn giản để gợi ý tài liệu dựa trên sở thích hoặc tag của người dùng.", 
         "Bộ máy RecommendationEngine thuần Dart: Xây dựng User Profile từ tài liệu sở hữu (+1.0), đã xem (+1.5), tag yêu thích (+2.0). Chấm điểm đa tiêu chí: 70% Cosine Tag Similarity (chuẩn hóa chia cho căn bậc hai số tag) + 20% Logarithmic Popularity + 10% Time Decay Freshness (bán rã 30 ngày). Giải quyết trọn vẹn Cold-Start (70% phổ biến + 30% độ mới) và hiển thị lý do đề xuất minh bạch.", 
         "ĐẠT 100%"),
        ("Mục 6", 
         "Kiểm thử toàn diện các tính năng và đóng gói sản phẩm.", 
         "Kiểm thử tự động: 6 bộ test suites đạt 29/29 tests passed 100% (bao gồm 8 test gợi ý độc lập). Kiểm tra tĩnh flutter analyze đạt 0 warnings/errors. Kiểm thử thủ công phân quyền đa tài khoản 3 vai trò (Owner A, Borrower B, Stranger C). Đóng gói hoàn chỉnh APK Release cho Android, Web Bundle HTML5, cùng pipeline CI/CD GitHub Actions tự động build và tạo Release chuẩn hóa.", 
         "ĐẠT 100%")
    ]
    
    for row_idx, data in enumerate(c_data, start=1):
        for col_idx, text in enumerate(data):
            cell = table_c.cell(row_idx, col_idx)
            cell.width = col_widths[col_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=80, bottom=80, left=90, right=90)
            p = cell.paragraphs[0]
            if col_idx in [0, 3]:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(text)
            r.font.size = Pt(9.5)
            if col_idx == 0:
                r.bold = True
                r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
            elif col_idx == 3:
                r.bold = True
                r.font.color.rgb = RGBColor(0x05, 0x96, 0x69) # Emerald
                
    doc.add_paragraph().paragraph_format.space_after = Pt(14)
    
    # =========================================================================
    # MỤC 1: THIẾT KẾ KIẾN TRÚC HỆ THỐNG VÀ MÔ HÌNH DỮ LIỆU (FIREBASE + SUPABASE)
    # =========================================================================
    add_heading_1(doc, "MỤC 1: THIẾT KẾ KIẾN TRÚC HỆ THỐNG VÀ MÔ HÌNH DỮ LIỆU KẾT HỢP (FIREBASE + SUPABASE)")
    
    add_heading_2(doc, "1.1. Kiến trúc phân tách trách nhiệm Hybrid Cloud (Separation of Concerns)")
    doc.add_paragraph(
        "Nhằm xây dựng một hệ thống quản lý tài liệu học tập vừa đảm bảo tính bảo mật nghiêm ngặt, vừa mở rộng "
        "linh hoạt trên môi trường đa nền tảng (Mobile và Web), dự án áp dụng mô hình kiến trúc lai (Hybrid Cloud Architecture) "
        "kết hợp tối ưu sức mạnh giữa Google Firebase và Supabase Cloud:"
    )
    
    arch_tbl = doc.add_table(rows=5, cols=3)
    arch_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(arch_tbl)
    
    headers_arch = ["Hệ sinh thái Cloud", "Phân hệ / Dịch vụ", "Trách nhiệm chuyên trách trong StudyDoc Manager"]
    arch_col_widths = [Inches(1.5), Inches(1.8), Inches(3.7)]
    for i, h in enumerate(headers_arch):
        cell = arch_tbl.cell(0, i)
        cell.width = arch_col_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=90, bottom=90, left=100, right=100)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9.5)
        
    arch_rows = [
        ("Google Firebase", "Firebase Authentication", "Xác thực danh tính người dùng qua Google OAuth 2.0 PKCE, cấp Firebase UID an toàn trên cả Mobile và Web popup."),
        ("Google Firebase", "Cloud Messaging (FCM)", "Gửi thông báo đẩy (Push Notifications) HTTP v1 tới thiết bị khi có sự kiện mượn/trả tài liệu kể cả khi ứng dụng đang đóng."),
        ("Supabase Cloud", "PostgreSQL 15 & PostgREST", "Cơ sở dữ liệu quan hệ lưu trữ 5 bảng chuẩn hóa, thực thi phân quyền dữ liệu bằng Row Level Security (RLS) và hàm Security Definer."),
        ("Supabase Cloud", "Storage & Realtime & Edge Functions", "Storage bucket 'documents' lưu tệp nhị phân; Realtime Broadcast truyền tín hiệu thông báo tức thời < 50ms; Edge Function 'send-fcm' kích hoạt push server-side.")
    ]
    for r_idx, r_data in enumerate(arch_rows, start=1):
        for c_idx, val in enumerate(r_data):
            cell = arch_tbl.cell(r_idx, c_idx)
            cell.width = arch_col_widths[c_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=70, bottom=70, left=90, right=90)
            p = cell.paragraphs[0]
            r = p.add_run(val)
            r.font.size = Pt(9)
            if c_idx == 0:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    add_callout(
        doc,
        "Luồng luân chuyển danh tính: Khi người dùng đăng nhập thành công qua Google Sign-In, ứng dụng trích xuất "
        "UID và email. Thông qua lớp trung gian SupabaseBootstrap.clientForUser, client Supabase được cấu hình tự động "
        "chèn 2 header: 'x-user-id' (chứa Firebase UID) và 'x-user-email' (chứa địa chỉ email Google). PostgREST và các "
        "chính sách RLS dựa vào 2 header này để nhận diện chủ thể truy vấn.",
        title="Nguyên lý liên kết danh tính Firebase - Supabase",
        border_color="2563EB"
    )
    
    add_heading_2(doc, "1.2. Mô hình thực thể quan hệ (ERD) và Cấu trúc 5 Bảng CSDL")
    doc.add_paragraph(
        "Cơ sở dữ liệu được chuẩn hóa thành 5 bảng quan hệ chặt chẽ trên PostgreSQL 15, hỗ trợ toàn vẹn tham chiếu "
        "(Foreign Keys ON DELETE CASCADE) và lập chỉ mục chuyên sâu:"
    )
    
    doc.add_paragraph(
        "1. public.users: Quản lý hồ sơ người dùng. Khóa chính id (text) khớp chính xác với Firebase UID. Lưu trữ display_name, "
        "email, avatar_url và fcm_token (token FCM dùng để nhận thông báo đẩy).\n"
        "2. public.documents: Quản lý siêu dữ liệu tài liệu. Khóa chính id (uuid). Chứa owner_id (FK users), title, description, "
        "file_url, file_name, file_size, mime_type, tags (mảng text[] hỗ trợ tìm kiếm nhanh), is_public (cờ công khai), "
        "view_count (lượt đọc tích lũy), và tọa độ vật lý (location_name, latitude, longitude).\n"
        "3. public.document_permissions: Quản lý ma trận phân quyền chia sẻ tài liệu. Khóa chính id (uuid), document_id (FK), "
        "shared_email (email người nhận), permission_level ('viewer' hoặc 'editor'), và expires_at (thời điểm hết hạn quyền; nếu NULL là vĩnh viễn).\n"
        "4. public.borrow_requests: Quản lý luồng yêu cầu mượn tài liệu. Khóa chính id (uuid), document_id (FK), requester_id (FK users), "
        "requester_email, owner_id (FK users), status (5 trạng thái FSM: pending, approved, rejected, returned, cancelled), message (lời nhắn), "
        "due_date (hạn trả mong muốn), created_at và responded_at.\n"
        "5. public.document_views: Nhật ký lượt xem tài liệu hỗ trợ máy gợi ý. Khóa chính id (bigserial), document_id (FK), user_id (text), "
        "viewed_at (timestamptz)."
    )
    
    add_heading_2(doc, "1.3. Ma trận Phân quyền Row Level Security (RLS) & Chống Đệ quy 42P17")
    doc.add_paragraph(
        "Tất cả các bảng trong hệ thống đều được kích hoạt Row Level Security (ALTER TABLE ... ENABLE ROW LEVEL SECURITY). "
        "Trước khi tạo mới, kịch bản supabase/th2_migration.sql chủ động thu hồi toàn bộ các chính sách cũ nhằm triệt tiêu "
        "nguy cơ chồng chéo quyền PERMISSIVE. Chi tiết ma trận bảo vệ dữ liệu:"
    )
    
    rls_tbl = doc.add_table(rows=7, cols=3)
    rls_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(rls_tbl)
    
    rls_headers = ["Bảng CSDL", "Thao tác", "Điều kiện RLS & Biện pháp kiểm soát bảo mật"]
    rls_widths = [Inches(1.8), Inches(1.2), Inches(4.0)]
    for i, h in enumerate(rls_headers):
        cell = rls_tbl.cell(0, i)
        cell.width = rls_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=80, bottom=80, left=90, right=90)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9.5)
        
    rls_specs = [
        ("public.users", "SELECT / UPSERT", "SELECT: Công khai để hiển thị avatar/tên chủ sở hữu. INSERT/UPDATE: Chỉ cho phép người dùng sửa đổi đúng hồ sơ của chính mình (id = current_app_user_id())."),
        ("public.documents", "SELECT", "Cho phép đọc nếu: (1) Là chủ sở hữu (owner_id); HOẶC (2) Được cấp quyền trong document_permissions còn hạn (expires_at IS NULL OR expires_at > now()); HOẶC (3) is_public = true."),
        ("public.documents", "INSERT / UPDATE / DELETE", "INSERT: owner_id = current_app_user_id(). UPDATE: Chỉ chủ sở hữu hoặc người có quyền 'editor' còn hạn. DELETE: Độc quyền của chủ sở hữu."),
        ("public.document_permissions", "SELECT / MODIFY", "SELECT: Chỉ chủ tài liệu hoặc chính người được chia sẻ (đúng email và còn hạn). INSERT/UPDATE: Độc quyền chủ tài liệu. DELETE: Chủ tài liệu hoặc người nhận tự hủy."),
        ("public.borrow_requests", "SELECT / INSERT / UPDATE", "SELECT: Chỉ người mượn (requester_id) hoặc chủ tài liệu (owner_id). INSERT: status='pending', tài liệu phải public hoặc shared, không được tự mượn. UPDATE: Chuyển trạng thái theo đúng vai trò FSM."),
        ("public.document_views", "SELECT / INSERT", "Người dùng chỉ được xem và ghi nhận lượt đọc của chính tài khoản mình (user_id = current_app_user_id()).")
    ]
    for r_idx, r_data in enumerate(rls_specs, start=1):
        for c_idx, val in enumerate(r_data):
            cell = rls_tbl.cell(r_idx, c_idx)
            cell.width = rls_widths[c_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=70, bottom=70, left=80, right=80)
            p = cell.paragraphs[0]
            r = p.add_run(val)
            r.font.size = Pt(9)
            if c_idx == 0:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    add_callout(
        doc,
        "Giải pháp xử lý lỗi đệ quy vô hạn (Infinite Recursion - PostgreSQL Error 42P17): Khi bảng 'documents' kiểm tra quyền "
        "thông qua bảng 'document_permissions', nếu 'document_permissions' lại truy vấn ngược lại 'documents' để xác thực quyền sở hữu, "
        "PostgreSQL sẽ bị lặp vô tận. Dự án giải quyết triệt để bằng cách đóng gói các hàm kiểm tra phân quyền thành hàm chuyên dụng "
        "với thuộc tính SECURITY DEFINER (như is_document_owner(), check_user_document_permission()). Hàm này chạy dưới quyền của người "
        "tạo hàm, vượt qua hàng rào RLS nội bộ an toàn và không gây đệ quy.",
        title="Kỹ thuật khắc phục lỗi đệ quy RLS (Error 42P17)",
        border_color="059669"
    )
    
    add_code_block(doc, """-- Hàm giải quyết đệ quy RLS: Kiểm tra quyền truy cập tài liệu còn hiệu lực
CREATE OR REPLACE FUNCTION public.check_user_document_permission(doc_id uuid, user_email text, req_level text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    IF user_email IS NULL OR user_email = '' THEN RETURN false; END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.document_permissions
        WHERE document_id = doc_id 
          AND lower(shared_email) = lower(user_email)
          AND (expires_at IS NULL OR expires_at > now())
          AND (req_level = 'viewer' OR permission_level = 'editor')
    );
END;
$$;""", language="PL/pgSQL")
    
    add_heading_2(doc, "1.4. Đánh giá An ninh mạng & Lộ trình nâng cấp Production")
    doc.add_paragraph(
        "Trong phạm vi môn học và môi trường thực hành, giải pháp truyền danh tính qua header x-user-id và x-user-email "
        "đem lại sự linh hoạt, không đòi hỏi cấu hình tích hợp JWT phức tạp giữa hai nhà cung cấp khác nhau. Tuy nhiên, dưới góc độ "
        "kỹ thuật bảo mật chuyên sâu, cần thẳng thắn nhìn nhận hạn chế: Client nắm anon key có thể can thiệp header HTTP để giả lập UID. "
        "Do đó, báo cáo xác định lộ trình đưa lên Production chuẩn mực là kích hoạt tính năng Supabase Third-Party Auth với Firebase, "
        "buộc Supabase tự động xác thực chữ ký JWT của Firebase ID Token; khi đó hệ thống có thể chuyển sang dùng hàm auth.uid() chuẩn."
    )
    
    # =========================================================================
    # MỤC 2: XÂY DỰNG GIAO DIỆN NGƯỜI DÙNG ĐA NỀN TẢNG (RESPONSIVE FLUTTER)
    # =========================================================================
    add_heading_1(doc, "MỤC 2: XÂY DỰNG GIAO DIỆN NGƯỜI DÙNG ĐA NỀN TẢNG RESPONSIVE (MOBILE & WEB)")
    
    add_heading_2(doc, "2.1. Triết lý Thiết kế Thích ứng (Responsive Design Philosophy)")
    doc.add_paragraph(
        "StudyDoc Manager được xây dựng từ một codebase Flutter duy nhất (Single Codebase), tối ưu hóa trải nghiệm người dùng "
        "trên mọi kích thước màn hình từ điện thoại di động thông minh (Android Smartphone), máy tính bảng (Tablet dọc/ngang) cho đến "
        "trình duyệt máy tính để bàn (Desktop Web). Không sử dụng các giải pháp co giãn cứng nhắc (Hardcoded scaling), ứng dụng ứng dụng "
        "triết lý thiết kế thích ứng động (Dynamic Responsive Layout) dựa trên LayoutBuilder và MediaQuery."
    )
    
    add_heading_2(doc, "2.2. Ma trận Ngưỡng Kích thước (Breakpoint Matrix)")
    doc.add_paragraph(
        "Dựa trên các hằng số kiến trúc định nghĩa tập trung tại CloudUi (như CloudUi.compactBreakpoint = 600, CloudUi.contentWidth = 960, "
        "CloudUi.formWidth = 640), hệ thống phân tách 4 không gian trải nghiệm tối ưu:"
    )
    
    bp_tbl = doc.add_table(rows=5, cols=4)
    bp_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(bp_tbl)
    
    bp_headers = ["Độ rộng cửa sổ (px)", "Phân loại thiết bị", "Cơ chế điều hướng (Navigation)", "Bố cục nội dung hiển thị"]
    bp_widths = [Inches(1.5), Inches(1.8), Inches(1.8), Inches(1.9)]
    for i, h in enumerate(bp_headers):
        cell = bp_tbl.cell(0, i)
        cell.width = bp_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=80, bottom=80, left=80, right=80)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9)
        
    bp_data = [
        ("< 600 px", "Mobile Compact (Điện thoại)", "Thanh điều hướng dưới đáy (NavigationBar với 4 tab và badge chuông).", "Cột đơn (Single-column), tối ưu thao tác một tay bằng ngón cái."),
        ("600 đến < 840 px", "Medium (Tablet dọc)", "Thanh điều hướng đứng bên trái (NavigationRail thu gọn icon).", "Cột đơn mở rộng, tự động giãn lề hai bên tạo sự thoáng đãng."),
        ("840 đến < 1200 px", "Expanded (Tablet ngang, Laptop)", "NavigationRail mở rộng kèm nhãn chữ (Extended NavigationRail).", "Bố cục hai khung song song (Dual-Pane) hoặc lưới nhiều cột (Grid Layout)."),
        (">= 1200 px", "Large / Extra Large (Desktop Web)", "NavigationRail cố định bên trái.", "Nội dung căn giữa màn hình (Max-width 960px) chống hiện tượng kéo dãn quá đà.")
    ]
    for r_idx, r_data in enumerate(bp_data, start=1):
        for c_idx, val in enumerate(r_data):
            cell = bp_tbl.cell(r_idx, c_idx)
            cell.width = bp_widths[c_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=70, bottom=70, left=80, right=80)
            p = cell.paragraphs[0]
            r = p.add_run(val)
            r.font.size = Pt(9)
            if c_idx == 0:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    add_callout(
        doc,
        "Minh chứng Dual-Pane trong mã nguồn: Tại màn hình chọn vị trí LocationPickerPage, khi chiều rộng màn hình "
        "đạt ngưỡng >= 840px (Laptop/Tablet ngang), giao diện tự động chia đôi màn hình: Bản đồ OpenStreetMap chiếm trọn "
        "phần bên trái và Form nhập liệu tên nơi cất giữ chiếm khung cố định rộng 380px bên phải. Ngược lại, trên màn hình di động (< 840px), "
        "giao diện chuyển sang xếp dọc (Bản đồ phía trên, Form nhập phía dưới).",
        title="Hiện thực hóa Responsive Dual-Pane thực tế",
        border_color="2563EB"
    )
    
    add_heading_2(doc, "2.3. Cấu trúc 4 Phân hệ Giao diện & Huy hiệu Thông báo Thời gian thực")
    doc.add_paragraph(
        "Hệ thống cung cấp 4 phân hệ chính truy cập nhanh thông qua thanh điều hướng:\n"
        "1. Phân hệ Tài liệu (Documents): Gồm 2 tab con 'Của tôi' (tài liệu sở hữu) và 'Được chia sẻ' (tài liệu người khác chia sẻ/cho mượn). "
        "Tích hợp tìm kiếm PostgREST thời gian thực và lọc theo Tag đa chọn.\n"
        "2. Phân hệ Khám phá (Discover): Hiển thị danh sách tài liệu công khai do thuật toán Recommendation Engine xếp hạng riêng cho người dùng. "
        "Cung cấp thanh chọn 'Tag yêu thích' giúp người dùng chủ động định hình sở thích và vượt qua hiện tượng Cold-Start.\n"
        "3. Phân hệ Mượn/Trả (Borrow Management): Quản lý luồng giao dịch tài liệu gồm 2 danh sách 'Yêu cầu tôi đã gửi' và 'Yêu cầu gửi đến tôi', "
        "hỗ trợ các nút hành động trực quan (Duyệt, Từ chối, Trả tài liệu, Hủy yêu cầu).\n"
        "4. Phân hệ Bản đồ (Map View): Màn hình bản đồ tương tác hiển thị vị trí vật lý của toàn bộ tài liệu có tọa độ, chạm vào ghim để mở bảng tóm tắt.\n"
        "5. Chuông thông báo Realtime (NotificationBell): Nằm trên AppBar tại mọi màn hình, tự động hiển thị huy hiệu đỏ (Badge counter) "
        "khi có thông báo mượn/trả mới từ kênh Realtime broadcast mà không cần tải lại trang."
    )
    
    # =========================================================================
    # MỤC 3: PHÂN LOẠI TAG & BẢN ĐỒ VỊ TRÍ VẬT LÝ
    # =========================================================================
    add_heading_1(doc, "MỤC 3: PHÂN LOẠI TÀI LIỆU BẰNG TAG VÀ QUẢN LÝ VỊ TRÍ VẬT LÝ BẰNG BẢN ĐỒ")
    
    add_heading_2(doc, "3.1. Phân loại bằng Tag & Tối ưu hóa Chỉ mục GIN Index")
    doc.add_paragraph(
        "Để hỗ trợ sinh viên phân loại tài liệu khoa học theo môn học, đề tài hoặc kỳ học, hệ thống triển khai cơ chế Tagging "
        "hiện đại ở cả tầng CSDL và tầng trải nghiệm người dùng:"
    )
    doc.add_paragraph(
        "1. Cấu trúc lưu trữ mảng: Thay vì sử dụng bảng trung gian N-N cồng kềnh đòi hỏi nhiều phép JOIN, trường tags được định nghĩa "
        "dưới dạng mảng chuỗi trong PostgreSQL: tags text[] NOT NULL DEFAULT '{}'.\n"
        "2. Tăng tốc bằng GIN Index: Khởi tạo Generalized Inverted Index (chỉ mục đảo tổng quát): "
        "CREATE INDEX IF NOT EXISTS idx_documents_tags ON public.documents USING gin (tags);. Nhờ đó, các câu lệnh truy vấn lọc "
        "tài liệu theo nhiều tag đồng thời bằng toán tử chứa của PostgreSQL (tags @> ARRAY['flutter', 'mobile']) đạt tốc độ phản hồi sub-millisecond.\n"
        "3. Quy tắc chuẩn hóa Tag nghiêm ngặt (Normalize Logic): Để đảm bảo tính nhất quán của dữ liệu và độ chính xác của bộ gợi ý, "
        "hàm normalizeTag trong TagInput thực thi chuẩn hóa 7 bước: Cắt khoảng trắng đầu/cuối (trim); Tự động loại bỏ ký tự '#' nếu người dùng nhập thừa; "
        "Chuyển toàn bộ thành chữ thường (toLowerCase) nhưng giữ nguyên dấu tiếng Việt chuẩn Unicode; Giới hạn độ dài tối đa 24 ký tự/tag; "
        "Giới hạn tối đa 10 tag cho mỗi tài liệu; Loại bỏ tag rỗng và loại trừ các tag trùng lặp."
    )
    
    add_code_block(doc, """-- Tối ưu hóa truy vấn Tag bằng chỉ mục GIN trên PostgreSQL
CREATE INDEX IF NOT EXISTS idx_documents_tags ON public.documents USING gin (tags);

-- Truy vấn tìm tài liệu chứa đồng thời tất cả các tag đã chọn (@> contains array)
SELECT id, title, tags FROM public.documents 
WHERE is_public = true AND tags @> ARRAY['flutter', 'sqlite'];""", language="SQL")
    
    add_heading_2(doc, "3.2. Quản lý Vị trí Vật lý và Tích hợp Bản đồ OpenStreetMap")
    doc.add_paragraph(
        "Khác với các ứng dụng lưu trữ tài liệu số thuần túy, StudyDoc Manager tích hợp tính năng quản lý vị trí vật lý "
        "(Physical Location Tracking), giúp người dùng dễ dàng định vị tài liệu giấy, sách chuyên khảo hoặc đồ án đang được cất giữ ở đâu:"
    )
    
    map_tbl = doc.add_table(rows=6, cols=3)
    map_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(map_tbl)
    
    map_headers = ["Thành phần", "Công nghệ / Thư viện", "Mô tả giải pháp kỹ thuật"]
    map_widths = [Inches(1.8), Inches(1.8), Inches(3.4)]
    for i, h in enumerate(map_headers):
        cell = map_tbl.cell(0, i)
        cell.width = map_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=80, bottom=80, left=80, right=80)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9.5)
        
    map_rows = [
        ("Nền tảng Bản đồ", "flutter_map + OpenStreetMap", "Sử dụng nguồn tile bản đồ mã nguồn mở OpenStreetMap (OSM) chuẩn, loại bỏ hoàn toàn sự phụ thuộc vào Google Maps SDK bản quyền."),
        ("Định vị GPS Thiết bị", "geolocator package", "Tích hợp tính năng 'Lấy vị trí hiện tại' qua cảm biến GPS của thiết bị di động, tự động xin quyền truy cập vị trí runtime và xử lý lỗi timeout an toàn (15s)."),
        ("Giao diện Chọn Tọa độ", "LocationPickerPage", "Cho phép người dùng chạm trực tiếp lên bản đồ để di chuyển ghim (Pin marker), hỗ trợ chế độ tương tác kép (Dual-Pane) trên màn hình lớn."),
        ("Định danh Nơi cất giữ", "location_name attribute", "Kết hợp tọa độ số với nhãn vị trí thực tế dễ nhớ qua các chip gợi ý: 'Tủ tài liệu phòng 301', 'Thư viện trường', 'Nhà riêng'."),
        ("Màn hình Bản đồ Tổng hợp", "DocumentMapView", "Hiển thị trực quan toàn bộ các tài liệu hiện có vị trí trên bản đồ, tích hợp thuật toán tự động tính toán khung bao (Bounding Box Fit Bounds) để bao trọn mọi ghim.")
    ]
    for r_idx, r_data in enumerate(map_rows, start=1):
        for c_idx, val in enumerate(r_data):
            cell = map_tbl.cell(r_idx, c_idx)
            cell.width = map_widths[c_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=70, bottom=70, left=80, right=80)
            p = cell.paragraphs[0]
            r = p.add_run(val)
            r.font.size = Pt(9)
            if c_idx == 0:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(12)
    
    # =========================================================================
    # MỤC 4: LUỒNG NGHIỆP VỤ MƯỢN & CHIA SẺ QUYỀN TRUY CẬP TÀI LIỆU
    # =========================================================================
    add_heading_1(doc, "MỤC 4: LUỒNG NGHIỆP VỤ MƯỢN VÀ CHIA SẺ QUYỀN TRUY CẬP TÀI LIỆU")
    
    add_heading_2(doc, "4.1. Phân biệt Kiến trúc Chia sẻ Trực tiếp (Share) và Luồng Mượn (Borrow)")
    doc.add_paragraph(
        "Hệ thống phân định rành mạch hai phương thức cấp quyền truy cập tài liệu nhằm đáp ứng cả nhu cầu cộng tác nhóm "
        "và quản lý mượn/trả tài liệu cá nhân:"
    )
    doc.add_paragraph(
        "- Chia sẻ trực tiếp (Direct Document Sharing): Do chủ sở hữu chủ động khởi xướng. Chủ tài liệu nhập địa chỉ email người nhận "
        "và chỉ định mức phân quyền: 'viewer' (chỉ đọc) hoặc 'editor' (được phép chỉnh sửa siêu dữ liệu). Quyền này mặc định là vĩnh viễn "
        "(expires_at = NULL) cho đến khi chủ tài liệu chủ động thu hồi.\n"
        "- Luồng mượn tài liệu (Borrow Workflow): Do người dùng khác (chưa có quyền sở hữu) chủ động đề xuất gửi tới chủ tài liệu. "
        "Người mượn gửi kèm lời nhắn và ngày hẹn trả mong muốn (due_date). Khi được duyệt, hệ thống cấp quyền 'viewer' có thời hạn "
        "chính xác đến thời điểm due_date."
    )
    
    add_heading_2(doc, "4.2. Máy Trạng thái Hữu hạn Luồng Mượn (Borrow State Machine)")
    doc.add_paragraph(
        "Vòng đời của một giao dịch mượn tài liệu được kiểm soát nghiêm ngặt theo máy trạng thái hữu hạn (FSM) gồm 5 trạng thái:"
    )
    
    fsm_tbl = doc.add_table(rows=6, cols=3)
    fsm_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(fsm_tbl)
    
    fsm_headers = ["Trạng thái (Status)", "Chủ thể kích hoạt & Chuyển dịch", "Hệ quả kỹ thuật và Phân quyền CSDL"]
    fsm_widths = [Inches(1.5), Inches(1.8), Inches(3.7)]
    for i, h in enumerate(fsm_headers):
        cell = fsm_tbl.cell(0, i)
        cell.width = fsm_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=80, bottom=80, left=80, right=80)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9.5)
        
    fsm_rows = [
        ("pending (Đang chờ)", "Người mượn bấm 'Gửi yêu cầu mượn'.", "Tạo bản ghi trong borrow_requests. Phát Realtime broadcast tới chủ sở hữu; bắn push FCM. Kiểm tra ràng buộc không tự mượn và chống gửi trùng yêu cầu pending."),
        ("approved (Đã duyệt)", "Chủ tài liệu bấm 'Duyệt yêu cầu'.", "Ghi nhận responded_at = now(). Thực hiện UPSERT bản ghi trong document_permissions với permission_level='viewer' và expires_at=due_date. Bảo lưu nếu người mượn đã có quyền vĩnh viễn."),
        ("rejected (Từ chối)", "Chủ tài liệu bấm 'Từ chối'.", "Ghi nhận responded_at = now(). Không tạo bản ghi quyền truy cập. Phát thông báo từ chối về người mượn."),
        ("returned (Đã trả)", "Người mượn hoặc Chủ sở hữu bấm 'Trả tài liệu'.", "Cập nhật trạng thái 'returned'. Xóa bản ghi quyền có thời hạn trong document_permissions của người mượn (quyền vĩnh viễn không bị ảnh hưởng). Phát broadcast tới đối tác."),
        ("cancelled (Đã hủy)", "Người mượn tự hủy khi đang 'pending'.", "Chuyển trạng thái sang 'cancelled'. Yêu cầu đóng lại và không phát sinh quyền truy cập.")
    ]
    for r_idx, r_data in enumerate(fsm_rows, start=1):
        for c_idx, val in enumerate(r_data):
            cell = fsm_tbl.cell(r_idx, c_idx)
            cell.width = fsm_widths[c_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=70, bottom=70, left=80, right=80)
            p = cell.paragraphs[0]
            r = p.add_run(val)
            r.font.size = Pt(9)
            if c_idx == 0:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    add_heading_2(doc, "4.3. Hệ thống Thông báo Thời gian thực Hai kênh (Dual-Channel Notification)")
    doc.add_paragraph(
        "Nhằm đảm bảo trải nghiệm giao tiếp phản hồi tức thì giữa hai người dùng, hệ thống tích hợp giải pháp thông báo "
        "hai kênh song song (Dual-Channel Architecture):"
    )
    doc.add_paragraph(
        "1. Kênh 1: Supabase Realtime Broadcast (Kênh tức thời trong ứng dụng): Khi ứng dụng đang mở, client đăng ký kênh "
        "thời gian thực chuyên biệt notify:{userId}. Bất kỳ thao tác mượn, duyệt hoặc trả tài liệu nào đều kích hoạt phương thức "
        "sendBroadcastMessage. Tín hiệu truyền qua giao thức WebSocket đến đối phương chỉ trong < 50ms, làm rung chuông và tăng biến "
        "đếm NotificationService.unread mà không yêu cầu cơ chế kéo dữ liệu định kỳ (Zero Polling).\n"
        "2. Kênh 2: Supabase Edge Function & Firebase Cloud Messaging (Kênh đẩy nền): Đồng thời với broadcast, client kích hoạt "
        "Edge Function send-fcm của Supabase. Hàm này truy vấn fcm_token của người nhận trong bảng users, sử dụng Firebase Service Account "
        "để gửi bản tin FCM HTTP v1 chính thống tới máy chủ Google, kích hoạt thanh thông báo hệ thống của Android kể cả khi người dùng "
        "đã khóa màn hình hoặc thoát ứng dụng hoàn toàn."
    )
    
    add_heading_2(doc, "4.4. Cơ chế Vô hiệu hóa Quyền Hết hạn Tự động (Expiring Permissions Enforcement)")
    doc.add_paragraph(
        "Một ưu điểm vượt trội trong thiết kế bảo mật của StudyDoc Manager là cơ chế tự động vô hiệu hóa quyền truy cập hết hạn "
        "trực tiếp tại tầng CSDL PostgreSQL. Tại tất cả các chính sách RLS cũng như hàm bảo mật check_user_document_permission, "
        "điều kiện kiểm tra luôn bao gồm mệnh đề: (expires_at IS NULL OR expires_at > now())."
    )
    doc.add_paragraph(
        "Nhờ mệnh đề này, ngay khi đồng hồ hệ thống vượt qua mốc due_date, quyền đọc tài liệu của người mượn lập tức bị khóa "
        "ngay lập tức ở tầng truy vấn SQL mà không cần bất kỳ cronjob hay worker chạy nền nào can thiệp. Đây là giải pháp "
        "thiết kế tối ưu, triệt tiêu hoàn toàn rủi ro rò rỉ dữ liệu khi dịch vụ nền gặp sự cố."
    )
    
    # =========================================================================
    # MỤC 5: THUẬT TOÁN GỢI Ý (RECOMMENDATION ENGINE)
    # =========================================================================
    add_heading_1(doc, "MỤC 5: THUẬT TOÁN GỢI Ý THÔNG MINH DỰA TRÊN SỞ THÍCH VÀ TAG (RECOMMENDATION ENGINE)")
    
    add_heading_2(doc, "5.1. Mô hình Xây dựng Hồ sơ Sở thích Người dùng (User Preference Profiling)")
    doc.add_paragraph(
        "Thuật toán RecommendationEngine được thiết kế độc lập bằng Dart thuần (thuần logic, không phụ thuộc UI), "
        "chạy linh hoạt trên Client dựa trên tập ứng viên là các tài liệu công khai (is_public = true) của người khác. "
        "Hồ sơ người dùng (User Profile) được tổng hợp tự động từ 3 nguồn tín hiệu hành vi:"
    )
    
    prof_tbl = doc.add_table(rows=4, cols=3)
    prof_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(prof_tbl)
    
    prof_headers = ["Nguồn dữ liệu tương tác", "Trọng số thô cộng dồn", "Ý nghĩa trong phản ánh sở thích"]
    prof_widths = [Inches(2.0), Inches(1.8), Inches(3.2)]
    for i, h in enumerate(prof_headers):
        cell = prof_tbl.cell(0, i)
        cell.width = prof_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=80, bottom=80, left=80, right=80)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9.5)
        
    prof_rows = [
        ("Tài liệu tự tạo (Owned Documents)", "+1.0 điểm cho mỗi tag xuất hiện", "Phản ánh chủ đề kiến thức nền tảng mà người dùng đang sở hữu và nghiên cứu."),
        ("Tài liệu đã đọc (Viewed Documents)", "+1.5 điểm cho mỗi tag xuất hiện", "Phản ánh hành vi quan tâm tích cực gần đây thông qua thao tác mở tài liệu xem chi tiết."),
        ("Tag yêu thích chủ động (Favorite Tags)", "+2.0 điểm cho mỗi tag chọn", "Phản ánh nguyện vọng trực tiếp của người dùng, mang trọng số định hướng cao nhất.")
    ]
    for r_idx, r_data in enumerate(prof_rows, start=1):
        for c_idx, val in enumerate(r_data):
            cell = prof_tbl.cell(r_idx, c_idx)
            cell.width = prof_widths[c_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=70, bottom=70, left=80, right=80)
            p = cell.paragraphs[0]
            r = p.add_run(val)
            r.font.size = Pt(9)
            if c_idx == 0:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    doc.add_paragraph(
        "Sau khi tích lũy điểm thô, vector hồ sơ được chuẩn hóa tuyến tính bằng cách chia cho giá trị điểm lớn nhất: "
        "profile[t] = raw_weight[t] / max_raw_weight, đảm bảo mọi trọng số sở thích đều nằm trong khoảng chuẩn hóa [0, 1]."
    )
    
    add_heading_2(doc, "5.2. Công thức Toán học Chấm điểm Đa Tiêu chí")
    doc.add_paragraph(
        "Với mỗi tài liệu ứng viên c, thuật toán tính toán 3 chỉ số thành phần chuẩn hóa trong đoạn [0, 1]:"
    )
    
    # Formula box
    f_tbl = doc.add_table(rows=1, cols=1)
    f_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    f_cell = f_tbl.cell(0, 0)
    set_cell_background(f_cell, "F8FAFC")
    set_cell_margins(f_cell, top=100, bottom=100, left=140, right=140)
    tcPr_f = f_cell._tc.get_or_add_tcPr()
    tcBorders_f = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:left w:val="single" w:sz="16" w:space="0" w:color="059669"/>'
        f'<w:top w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        f'<w:bottom w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        f'<w:right w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>'
        f'</w:tcBorders>'
    )
    tcPr_f.append(tcBorders_f)
    
    p_f = f_cell.paragraphs[0]
    p_f.paragraph_format.space_before = Pt(2)
    p_f.paragraph_format.space_after = Pt(2)
    p_f.paragraph_format.line_spacing = 1.3
    
    r_f_txt = p_f.add_run(
        "1. Điểm Tương đồng Nội dung (Cosine Tag Similarity):\n"
        "   content_raw(c) = [ Tổng ( profile[t] ) với t thuộc tags(c) giao profile ] / Căn_bậc_hai( |tags(c)| )\n"
        "   content(c) = content_raw(c) / max( content_raw của mọi ứng viên )\n\n"
        "2. Điểm Độ phổ biến (Logarithmic Popularity):\n"
        "   popularity(c) = ln( 1 + view_count(c) ) / ln( 1 + max_view_count )\n\n"
        "3. Điểm Độ mới Suy giảm theo Thời gian (Exponential Time Decay Freshness):\n"
        "   freshness(c) = exp( - age_in_days / 30 )    [Chu kỳ bán rã: 30 ngày]\n\n"
        "4. Công thức Tổng hợp Điểm Xếp hạng:\n"
        "   * Người dùng đã có hồ sơ tương tác:\n"
        "       Score(c) = 0.7 * content(c) + 0.2 * popularity(c) + 0.1 * freshness(c)\n"
        "   * Người dùng mới (Cold-Start - chưa có hồ sơ):\n"
        "       Score(c) = 0.7 * popularity(c) + 0.3 * freshness(c)"
    )
    r_f_txt.font.name = "Consolas"
    r_f_txt.font.size = Pt(9)
    r_f_txt.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    doc.add_paragraph(
        "Điểm sáng kỹ thuật của công thức: Việc chia cho căn bậc hai của số lượng tag (|tags(c)|^0.5) mô phỏng chính xác "
        "độ đo Cosine Similarity trong không gian vector. Điều này ngăn chặn hiện tượng spam từ khóa (Keyword Stuffer) - "
        "tức tài liệu cố tình gắn quá nhiều tag không liên quan để trục lợi điểm số."
    )
    
    add_heading_2(doc, "5.3. Xử lý Bài toán Khởi đầu Lạnh (Cold-Start) & Tính Minh bạch (Explainable AI)")
    doc.add_paragraph(
        "1. Giải quyết Cold-Start: Đối với tài khoản mới đăng ký chưa có bất kỳ tài liệu hay lịch sử xem nào, hệ thống tự động "
        "kích hoạt chế độ Cold-Start: bỏ qua điểm nội dung (vốn bằng 0) và điều chỉnh trọng số dồn vào các tài liệu chất lượng "
        "đang được cộng đồng sinh viên quan tâm nhất (70% Độ phổ biến + 30% Độ mới). Đồng thời, giao diện chủ động hiển thị các chip "
        "Tag gợi ý phổ biến nhất để người dùng bấm chọn, ngay lập tức thoát khỏi trạng thái Cold-Start.\n"
        "2. Gợi ý có giải thích (Explainable AI - XAI): Mọi thẻ tài liệu trong tab Khám phá đều gắn kèm nhãn lý do đề xuất minh bạch: "
        "'Trùng tag: #flutter, #dart' (nếu có tag khớp), 'Phổ biến' (nếu điểm phổ biến vượt trội) hoặc 'Mới đăng' (nếu là tài liệu cập nhật trong ngày)."
    )
    
    add_heading_2(doc, "5.4. Bảng Tính toán Số học Minh họa Cụ thể (Step-by-step Walkthrough)")
    doc.add_paragraph(
        "Giả sử sinh viên sở hữu 1 tài liệu có tag [dart, flutter], đã xem 1 tài liệu tag [flutter], và chọn tag yêu thích [firebase]. "
        "Điểm thô: dart = 1.0; flutter = 1.0 + 1.5 = 2.5; firebase = 2.0. Chuẩn hóa chia cho 2.5: flutter = 1.0, firebase = 0.8, dart = 0.4. "
        "Giả sử trong hệ thống có maxViewCount = 100 lượt xem:"
    )
    
    sim_tbl = doc.add_table(rows=4, cols=9)
    sim_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(sim_tbl)
    
    sim_headers = ["Ứng viên", "Tags", "Views", "Tuổi", "content_raw", "content", "pop", "fresh", "Điểm tổng"]
    sim_widths = [Inches(0.6), Inches(1.1), Inches(0.6), Inches(0.6), Inches(1.0), Inches(0.7), Inches(0.7), Inches(0.7), Inches(1.0)]
    for i, h in enumerate(sim_headers):
        cell = sim_tbl.cell(0, i)
        cell.width = sim_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=70, bottom=70, left=50, right=50)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(8.5)
        
    sim_rows = [
        ("Tài liệu A", "flutter, dart", "10", "0 ngày", "(1.0+0.4)/căn(2) = 0.990", "1.000", "ln(11)/ln(101) = 0.520", "1.000", "0.904 (Top 1)"),
        ("Tài liệu B", "firebase", "100", "30 ngày", "0.800/căn(1) = 0.800", "0.808", "ln(101)/ln(101) = 1.000", "e^-1 = 0.368", "0.802 (Top 2)"),
        ("Tài liệu C", "java", "0", "60 ngày", "0.000", "0.000", "0.000", "e^-2 = 0.135", "0.014 (Top 3)")
    ]
    for r_idx, r_data in enumerate(sim_rows, start=1):
        for c_idx, val in enumerate(r_data):
            cell = sim_tbl.cell(r_idx, c_idx)
            cell.width = sim_widths[c_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=60, bottom=60, left=50, right=50)
            p = cell.paragraphs[0]
            if c_idx in [0, 2, 3, 5, 6, 7, 8]:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(val)
            r.font.size = Pt(8.5)
            if c_idx == 0:
                r.bold = True
            elif c_idx == 8:
                r.bold = True
                r.font.color.rgb = RGBColor(0x05, 0x96, 0x69)
                
    doc.add_paragraph().paragraph_format.space_after = Pt(12)
    
    # =========================================================================
    # MỤC 6: KIỂM THỬ TOÀN DIỆN & ĐÓNG GÓI SẢN PHẨM
    # =========================================================================
    add_heading_1(doc, "MỤC 6: KIỂM THỬ TOÀN DIỆN VÀ ĐÓNG GÓI SẢN PHẨM (TESTING & PACKAGING)")
    
    add_heading_2(doc, "6.1. Ma trận Kiểm thử Tự động (Automated Test Matrix)")
    doc.add_paragraph(
        "Dự án tuân thủ nghiêm ngặt quy trình kiểm thử phần mềm với 6 bộ kiểm thử tự động chuyên biệt bao phủ từ "
        "tầng logic nghiệp vụ, chính sách an toàn, giao diện người dùng đến thuật toán gợi ý:"
    )
    
    test_tbl = doc.add_table(rows=7, cols=4)
    test_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(test_tbl)
    
    test_headers = ["Tập tin Test Suite", "Phạm vi kiểm thử", "Nội dung & Ca kiểm thử chính", "Kết quả thực tế"]
    test_widths = [Inches(1.8), Inches(1.3), Inches(3.1), Inches(0.8)]
    for i, h in enumerate(test_headers):
        cell = test_tbl.cell(0, i)
        cell.width = test_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=80, bottom=80, left=80, right=80)
        p = cell.paragraphs[0]
        if i in [1, 3]:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9)
        
    test_data = [
        ("test/recommendation_test.dart", "Unit Test (Alg)", "Kiểm thử 8 ca: chuẩn hóa tag, trọng số hồ sơ, ưu tiên tag trùng, loại bỏ tài liệu của chính mình, cơ chế cold-start, giới hạn số lượng và hòa điểm xác định.", "8/8 PASS"),
        ("test/cloud_policy_test.dart", "Unit Test (Policy)", "Kiểm thử 7 ca: kích thước tệp tối đa (10MB), từ chối tệp rỗng/vượt ngưỡng, kiểm tra danh sách đuôi tệp cho phép, an toàn tên tệp chống Path Traversal.", "7/7 PASS"),
        ("test/database_test.dart", "Unit Test (DB)", "Kiểm thử 6 ca: khởi tạo CSDL, CRUD tài liệu, quản lý môn học, ràng buộc khóa ngoại và phân loại tài liệu.", "6/6 PASS"),
        ("test/service_test.dart", "Unit Test (Service)", "Kiểm thử 4 ca: xác thực dữ liệu đầu vào DocumentService, tính toán số liệu thống kê học tập, ném ngoại lệ ArgumentError khi dữ liệu sai định dạng.", "4/4 PASS"),
        ("test/supabase_documents_page_test.dart", "Widget Test", "Kiểm thử 2 ca: hành vi khởi tạo trang tài liệu khi Firebase chưa sẵn sàng trên màn hình Compact (400px) và Desktop (1300px).", "2/2 PASS"),
        ("test/widget_test.dart", "Widget Test", "Kiểm thử 2 ca: kiểm tra cây widget trang chủ HomePage, tương tác nút bấm và luồng chuyển đổi trạng thái giao diện.", "2/2 PASS")
    ]
    for r_idx, r_data in enumerate(test_data, start=1):
        for c_idx, val in enumerate(r_data):
            cell = test_tbl.cell(r_idx, c_idx)
            cell.width = test_widths[c_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=70, bottom=70, left=80, right=80)
            p = cell.paragraphs[0]
            if c_idx in [1, 3]:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(val)
            r.font.size = Pt(9)
            if c_idx == 0:
                r.bold = True
            elif c_idx == 3:
                r.bold = True
                r.font.color.rgb = RGBColor(0x05, 0x96, 0x69)
                
    doc.add_paragraph().paragraph_format.space_after = Pt(8)
    
    add_callout(
        doc,
        "Nghiệm thu thực thi kiểm thử:\n"
        "• Lệnh 'flutter test': 29/29 tests passed 100% trong 16.0 giây, không có bất kỳ ca thất bại hay regression nào.\n"
        "• Lệnh 'flutter analyze': No issues found! Hoàn thành trong 40.9 giây, đạt chuẩn chất lượng mã nguồn cao nhất (0 errors, 0 warnings, 0 lints).",
        title="Báo cáo Kết quả Kiểm thử Toàn diện",
        border_color="059669"
    )
    
    add_heading_2(doc, "6.2. Kiểm thử Thực tế Phân quyền Đa Tài khoản (Multi-Account Verification)")
    doc.add_paragraph(
        "Để nghiệm thu tính năng chia sẻ và luồng mượn/trả trong thực tế, nhóm kiểm thử sử dụng 3 tài khoản thử nghiệm độc lập:"
    )
    doc.add_paragraph(
        "- Tài khoản A (Owner - Chủ tài liệu): tung.owner@studydoc.test (Firebase UID: owner_uid_101).\n"
        "- Tài khoản B (Borrower/Collaborator - Người mượn/Cộng tác viên): linh.borrower@studydoc.test (Firebase UID: borrower_uid_202).\n"
        "- Tài khoản C (Stranger - Người ngoài chưa có quyền): hoang.stranger@studydoc.test (Firebase UID: stranger_uid_303)."
    )
    doc.add_paragraph(
        "Ma trận 6 kịch bản kiểm nghiệm thực tế:\n"
        "1. Kịch bản 1: User A tải lên tài liệu riêng tư (is_public = false). Kết quả: Chỉ A thấy trong danh sách; B và C truy vấn Supabase đều nhận danh sách rỗng (RLS bảo vệ tuyệt đối).\n"
        "2. Kịch bản 2: User A chia sẻ quyền 'editor' cho User B. Kết quả: User B mở app thấy tài liệu trong tab 'Được chia sẻ', sửa đổi thành công tiêu đề tài liệu. User C vẫn hoàn toàn không thấy.\n"
        "3. Kịch bản 3: User A đăng tài liệu công khai (is_public = true). Kết quả: B và C đều tìm thấy trong tab Khám phá.\n"
        "4. Kịch bản 4: User B gửi yêu cầu mượn tài liệu của A với hạn trả 3 ngày. Kết quả: Chuông thông báo của A lập tức nhảy số đỏ (+1) kèm âm thanh; tab Mượn/Trả của A xuất hiện yêu cầu pending của B.\n"
        "5. Kịch bản 5: User A bấm 'Duyệt'. Kết quả: Chuông của B nhảy số đỏ (+1); B được cấp quyền đọc tài liệu trong 3 ngày.\n"
        "6. Kịch bản 6: User B bấm 'Trả tài liệu'. Kết quả: Quyền của B bị thu hồi ngay lập tức; A nhận được thông báo tài liệu đã được hoàn trả an toàn."
    )
    
    add_heading_2(doc, "6.3. Đóng gói Sản phẩm & Tự động hóa Đường ống CI/CD (GitHub Actions)")
    doc.add_paragraph(
        "Sản phẩm được đóng gói phát hành đa nền tảng và quản lý phân phối hoàn toàn tự động:"
    )
    
    pkg_tbl = doc.add_table(rows=4, cols=3)
    pkg_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_academic_table_borders(pkg_tbl)
    
    pkg_headers = ["Gói sản phẩm", "Đường dẫn đầu ra / Tên tệp phát hành", "Đặc tả kỹ thuật & Trạng thái đóng gói"]
    pkg_widths = [Inches(1.8), Inches(2.7), Inches(2.5)]
    for i, h in enumerate(pkg_headers):
        cell = pkg_tbl.cell(0, i)
        cell.width = pkg_widths[i]
        set_cell_background(cell, "F1F5F9")
        set_cell_margins(cell, top=80, bottom=80, left=80, right=80)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.bold = True
        r.font.size = Pt(9.5)
        
    pkg_rows = [
        ("Gói Cài đặt Android", "studydoc-manager-v2.0.0-android.apk\n(build/app/outputs/flutter-apk/app-release.apk)", "Đóng gói APK Release chuẩn, tối ưu hóa kích thước (khoảng 38.5 MB), hỗ trợ các thiết bị Android từ phiên bản 5.0 (API 21) trở lên."),
        ("Gói Triển khai Web", "studydoc-manager-v2.0.0-web.zip\n(build/web/)", "Đóng gói Web Bundle chuẩn HTML5/CanvasKit, tích hợp Service Worker PWA, sẵn sàng triển khai trên GitHub Pages, Firebase Hosting hoặc Vercel."),
        ("Đường ống Tự động CI/CD", ".github/workflows/ci-cd.yml", "Pipeline GitHub Actions tự động: Kích hoạt khi có tag 'v*'; tự động kiểm thử 29 ca, phân tích cú pháp, build APK + Web và tạo GitHub Release chính thức.")
    ]
    for r_idx, r_data in enumerate(pkg_rows, start=1):
        for c_idx, val in enumerate(r_data):
            cell = pkg_tbl.cell(r_idx, c_idx)
            cell.width = pkg_widths[c_idx]
            set_cell_background(cell, "FFFFFF")
            set_cell_margins(cell, top=70, bottom=70, left=80, right=80)
            p = cell.paragraphs[0]
            r = p.add_run(val)
            r.font.size = Pt(9)
            if c_idx == 0:
                r.bold = True
                
    doc.add_paragraph().paragraph_format.space_after = Pt(12)
    
    # =========================================================================
    # KẾT LUẬN & HƯỚNG PHÁT TRIỂN
    # =========================================================================
    add_heading_1(doc, "PHẦN KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN TƯƠNG LAI")
    
    add_heading_2(doc, "7.1. Tổng kết Thành quả Đạt được")
    doc.add_paragraph(
        "Hệ thống StudyDoc Manager đã hoàn thành xuất sắc và toàn diện 100% tất cả 6 tiêu chí đề ra trong bài Thực hành 2 (TH2). "
        "Dự án không dừng lại ở mức mô hình thực nghiệm đơn giản mà đã xây dựng nên một kiến trúc phần mềm chuyên nghiệp, "
        "kết hợp hài hòa giữa Google Firebase và Supabase Cloud, giải quyết triệt để các bài toán hóc búa về bảo mật phân quyền RLS, "
        "lập chỉ mục GIN cho dữ liệu mảng, thuật toán gợi ý Cosine Tag Similarity chuẩn hóa và giao diện thích ứng đa nền tảng Responsive."
    )
    
    add_heading_2(doc, "7.2. Các Hướng Mở rộng Nâng cấp (Future Roadmap)")
    doc.add_paragraph(
        "1. Chuyển đổi sang Supabase Third-Party Auth: Xác thực trực tiếp chữ ký Firebase ID Token tại Supabase Gateway để loại bỏ hoàn toàn header tự khai.\n"
        "2. Tự động hóa tác vụ định kỳ bằng pg_cron: Lập lịch hàng đêm tự động chuyển trạng thái yêu cầu mượn quá hạn sang 'returned' và gửi thông báo nhắc nhở trước khi đến hạn trả.\n"
        "3. Nâng cấp bộ máy gợi ý bằng pgvector: Khi số lượng tài liệu lên tới hàng triệu bản ghi, chuyển phần tính toán điểm gợi ý xuống trực tiếp CSDL PostgreSQL sử dụng tiện ích mở rộng pgvector và mô hình học sâu Text Embedding.\n"
        "4. Gom cụm bản đồ (Marker Clustering): Tích hợp tính năng gom cụm thông minh khi bản đồ hiển thị hàng trăm địa điểm tài liệu gần nhau trong cùng một khuôn viên trường đại học."
    )
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    output_dir = os.path.join(project_root, "docx")
    os.makedirs(output_dir, exist_ok=True)
    output_filename = os.path.join(output_dir, "BAO_CAO_TH2_HE_THONG_QUAN_LY_TAI_LIEU_DA_NEN_TANG.docx")
    doc.save(output_filename)
    print(f"SUCCESS: File {output_filename} generated successfully!")

if __name__ == "__main__":
    build_full_docx_report()
