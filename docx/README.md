# Thư mục Tài liệu Báo cáo Word (DOCX)

Thư mục này tập trung toàn bộ các tài liệu báo cáo kỹ thuật định dạng Microsoft Word (`.docx`) hoàn chỉnh của dự án **StudyDoc Manager**.

---

## 1. Danh mục Tài liệu Báo cáo (.docx)

| Tên tập tin | Nội dung & Phạm vi nghiệm thu | Thời gian / Giai đoạn |
|---|---|:---:|
| **`BAO_CAO_TH2_HE_THONG_QUAN_LY_TAI_LIEU_DA_NEN_TANG.docx`** | **Báo cáo nghiệm thu chính thức theo 6 mục Checklist của đề bài TH2**: Kiến trúc Hybrid Firebase + Supabase, Giao diện Responsive Mobile/Web, Tag GIN Index & OpenStreetMap, Luồng Mượn/Duyệt & Quyền RLS có hạn, Thuật toán Recommendation Cosine-Tag, Kiểm thử 29/29 Pass & CI/CD. | **TH2 (v2.0.0)** |
| **`BAO_CAO_HE_THONG_QUAN_LY_TAI_LIEU_FLUTTER_FIREBASE_SUPABASE.docx`** | Báo cáo chuyên sâu về kiến trúc tích hợp Cloud: Google OAuth 2.0 PKCE, Firebase Storage, Supabase PostgreSQL, phân quyền RLS và kiểm thử đa tài khoản (Owner, Viewer, Editor). | **TH2 (Cloud)** |
| **`BAO_CAO_TH1_KIEN_TRUC_CASHEW.docx`** | Báo cáo kỹ thuật bài TH1: Kiến trúc phân tầng Cashew, cơ sở dữ liệu cục bộ SQLite, quản lý tài liệu học tập offline. | **TH1** |

---

## 2. Mã nguồn Sinh Báo cáo Tự động (Python)

Mã nguồn Python sinh các tài liệu Word trên được quản lý tập trung tại thư mục `scripts/`:

* **`scripts/generate_th2_checklist_report_docx.py`**: Sinh báo cáo nghiệm thu 6 mục Checklist TH2.
* **`scripts/generate_cloud_report_docx.py`**: Sinh báo cáo tích hợp hệ sinh thái Cloud.
* **`scripts/create_academic_docx.py`**: Sinh báo cáo kiến trúc Cashew TH1.

### Lệnh chạy sinh lại báo cáo khi cần cập nhật:
```powershell
# Sinh báo cáo nghiệm thu TH2 (Checklist 6 mục)
uv run --with python-docx python scripts/generate_th2_checklist_report_docx.py

# Sinh báo cáo Cloud TH2
uv run --with python-docx python scripts/generate_cloud_report_docx.py

# Sinh báo cáo Cashew TH1
uv run --with python-docx python scripts/create_academic_docx.py
```

