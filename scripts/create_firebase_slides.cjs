const fs = require('node:fs');
const path = require('node:path');
const PptxGenJS = require('pptxgenjs');

const ROOT = path.resolve(__dirname, '..');
const OUTPUT = path.join(ROOT, 'SLIDE_FIREBASE_CLOUD_DMS.pptx');
const THEME = {
  name: 'StudyDoc Firebase | Charcoal and Orange',
  headFontFace: 'Cambria',
  bodyFontFace: 'Calibri',
  colors: {
    dk1: '182126', lt1: 'FFFFFF', dk2: '53616B', lt2: 'F1F4F5',
    accent1: 'FF9F1C', accent2: 'FFCA28', accent3: '34454F',
    accent4: '14735B', accent5: 'AC3C30', accent6: 'C8D2D8',
    hlink: '14735B', folHlink: '53616B',
  },
};
const DESIGN = {
  grid: 0.125,
  font: {
    cover: 42, title: 36, stat: 60, h1: 32, h2: 24, h3: 22, h4: 20,
    body: 20, small: 18, code: 16, caption: 12, footer: 11,
  },
  stroke: { thin: 0.8, normal: 1.2, arrow: 1.8 },
  radius: 0.16,
  paragraphGap: 0,
  frames: {
    eyebrow: [5, 4, 97, 2], title: [5, 7, 97, 7], subtitle: [5, 14, 97, 3],
    footer: [5, 54, 89, 2], number: [98, 54, 4, 2], sources: [5, 51.5, 97, 2],
    coverTitle: [5, 12, 62, 13], coverSubtitle: [5, 28, 60, 9],
  },
};
const presentation = new PptxGenJS();
presentation.layout = 'LAYOUT_WIDE';
presentation.theme = {
  headFontFace: THEME.headFontFace,
  bodyFontFace: THEME.bodyFontFace,
};
presentation.title = 'StudyDoc Manager | Bài tập tích hợp Cloud';
presentation.subject = 'Firebase Public Cloud cho thư viện tài liệu riêng tư';
presentation.author = 'StudyDoc Manager';
presentation.lang = 'vi-VN';
presentation.revision = '1';
const scheme = presentation.SchemeColor;
const COLORS = {
  ink: scheme.text1, white: scheme.background1, muted: scheme.text2,
  surface: scheme.background2, orange: scheme.accent1, amber: scheme.accent2,
  darkSurface: scheme.accent3, success: scheme.accent4, error: scheme.accent5,
  border: scheme.accent6,
};
const SHAPES = presentation.ShapeType;
const grid = (units) => units * DESIGN.grid;
const position = ([horizontal, vertical, width, height]) => ({
  x: grid(horizontal), y: grid(vertical), w: grid(width), h: grid(height),
});
let objectCount = 0;
let currentSection;
const timings = [];

function text(slide, content, frame, style = {}) {
  slide.addText(content, {
    ...position(frame), isTextBox: true, margin: 0, breakLine: false,
    fontFace: '+mn-lt', fontSize: DESIGN.font.body, color: COLORS.ink,
    valign: 'top', paraSpaceAfter: DESIGN.paragraphGap, lineSpacingMultiple: 1.06, fit: 'none',
    objectName: `Text ${++objectCount}: ${String(content).slice(0, 65)}`,
    ...style,
  });
}

function panel(slide, frame, fill = COLORS.surface, border = fill) {
  slide.addShape(SHAPES.roundRect, {
    ...position(frame), rectRadius: DESIGN.radius,
    fill: { color: fill }, line: { color: border, width: DESIGN.stroke.thin },
    objectName: `Content panel ${++objectCount}`,
  });
}

function badge(slide, label, frame, dark = false) {
  panel(slide, frame, dark ? COLORS.orange : COLORS.ink);
  text(slide, label, frame, {
    fontSize: DESIGN.font.small, color: dark ? COLORS.ink : COLORS.white,
    bold: true, valign: 'mid', align: 'center',
  });
}

function counter(slide, label, horizontal, vertical, dark = false) {
  const frame = [horizontal, vertical, 4, 4];
  slide.addShape(SHAPES.ellipse, {
    ...position(frame), fill: { color: dark ? COLORS.orange : COLORS.ink },
    line: { color: dark ? COLORS.orange : COLORS.ink, width: DESIGN.stroke.thin },
    objectName: `Step ${label}`,
  });
  text(slide, label, frame, {
    fontSize: DESIGN.font.small, bold: true, align: 'center', valign: 'mid',
    color: dark ? COLORS.ink : COLORS.white,
  });
}

function card(slide, title, body, frame, options = {}) {
  const [horizontal, vertical, width, height] = frame;
  panel(slide, frame, options.fill || COLORS.surface, options.border || options.fill || COLORS.surface);
  const inset = 2;
  const top = options.number ? vertical + 7 : vertical + inset;
  if (options.number) counter(slide, options.number, horizontal + inset, vertical + inset, options.dark);
  text(slide, title, [horizontal + inset, top, width - inset * 2, 5], {
    fontSize: DESIGN.font.h3, bold: true, color: options.color || COLORS.ink,
  });
  text(slide, body, [horizontal + inset, top + 6, width - inset * 2, height - (top - vertical) - 7], {
    fontSize: options.bodySize || DESIGN.font.body, color: options.color || COLORS.ink,
  });
}

function node(slide, title, detail, frame, dark = false) {
  const [horizontal, vertical, width, height] = frame;
  panel(slide, frame, dark ? COLORS.ink : COLORS.white, dark ? COLORS.ink : COLORS.border);
  text(slide, title, [horizontal + 1, vertical + 1, width - 2, 4], {
    fontSize: DESIGN.font.h3, bold: true, color: dark ? COLORS.white : COLORS.ink,
    align: 'center', valign: 'mid',
  });
  text(slide, detail, [horizontal + 1, vertical + 5, width - 2, height - 6], {
    fontSize: DESIGN.font.small, color: dark ? COLORS.border : COLORS.muted,
    align: 'center', valign: 'mid',
  });
}

function arrow(slide, start, end, color = COLORS.muted, dashed = false) {
  slide.addShape(SHAPES.line, {
    x: grid(Math.min(start[0], end[0])), y: grid(Math.min(start[1], end[1])),
    w: grid(Math.abs(end[0] - start[0])), h: grid(Math.abs(end[1] - start[1])),
    flipH: end[0] < start[0], flipV: end[1] < start[1],
    line: { color, width: DESIGN.stroke.arrow, endArrowType: 'triangle', dashType: dashed ? 'dash' : 'solid' },
    objectName: `Data flow ${++objectCount}`,
  });
}

function callout(slide, content, frame, dark = false) {
  const [horizontal, vertical, width, height] = frame;
  panel(slide, frame, dark ? COLORS.darkSurface : COLORS.surface);
  text(slide, content, [horizontal + 2, vertical + 1, width - 4, height - 2], {
    fontSize: DESIGN.font.small, color: dark ? COLORS.white : COLORS.ink, valign: 'mid',
  });
}

function defineLayout(name, dark = false, cover = false) {
  const titleFrame = cover ? DESIGN.frames.coverTitle : DESIGN.frames.title;
  const subtitleFrame = cover ? DESIGN.frames.coverSubtitle : DESIGN.frames.subtitle;
  presentation.defineSlideMaster({
    title: name,
    background: { color: dark ? COLORS.ink : COLORS.white },
    margin: grid(5),
    objects: [
      { placeholder: { options: {
        name: 'title', type: 'title', ...position(titleFrame), margin: 0,
        fontFace: '+mj-lt', fontSize: cover ? DESIGN.font.cover : DESIGN.font.title,
        color: dark ? COLORS.white : COLORS.ink, bold: true, valign: 'mid',
      }, text: '' } },
      { placeholder: { options: {
        name: 'eyebrow', type: 'body', ...position(DESIGN.frames.eyebrow), margin: 0,
        fontSize: DESIGN.font.caption, color: dark ? COLORS.orange : COLORS.muted,
        bold: true, valign: 'mid',
      }, text: '' } },
      { placeholder: { options: {
        name: 'subtitle', type: 'body', ...position(subtitleFrame), margin: 0,
        fontSize: cover ? DESIGN.font.h3 : DESIGN.font.small,
        color: dark ? COLORS.border : COLORS.muted, valign: 'mid',
      }, text: '' } },
      { text: { text: 'StudyDoc Manager | Firebase', options: {
        ...position(DESIGN.frames.footer), isTextBox: true, margin: 0,
        fontSize: DESIGN.font.footer, color: dark ? COLORS.border : COLORS.muted,
      } } },
    ],
    slideNumber: {
      ...position(DESIGN.frames.number), margin: 0, align: 'right',
      fontSize: DESIGN.font.footer, color: dark ? COLORS.border : COLORS.muted,
    },
  });
}

defineLayout('Cover', true, true);
defineLayout('Light');
defineLayout('Diagram');
defineLayout('Comparison');
defineLayout('Runbook');
defineLayout('Dark', true);

const SOURCES = {
  F1: ['Firebase overview', 'https://firebase.google.com/docs'],
  F2: ['Flutter Google Auth', 'https://firebase.google.com/docs/auth/flutter/federated-auth'],
  F3: ['Firestore Security Rules', 'https://firebase.google.com/docs/firestore/security/rules-conditions'],
  F4: ['Storage download: Flutter / Web', 'https://firebase.google.com/docs/storage/flutter/download-files', 'https://firebase.google.com/docs/storage/web/download-files'],
  F5: ['Storage Rules', 'https://firebase.google.com/docs/storage/security'],
  F6: ['Blaze and Storage changes', 'https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024'],
  F7: ['Pricing and budget alerts', 'https://firebase.google.com/pricing', 'https://firebase.google.com/docs/projects/billing/avoid-surprise-bills'],
  F8: ['NIST: Hybrid cloud', 'https://csrc.nist.gov/glossary/term/hybrid_cloud'],
};

function newSlide({ section, layout = 'Light', title, subtitle, seconds, narration, sources = [] }) {
  if (section !== currentSection) {
    presentation.addSection({ title: section });
    currentSection = section;
  }
  const slide = presentation.addSlide({ masterName: layout, sectionTitle: section });
  slide.addText(title, { placeholder: 'title' });
  slide.addText(section.toUpperCase(), { placeholder: 'eyebrow' });
  slide.addText(subtitle, { placeholder: 'subtitle' });
  if (sources.length) {
    text(slide, `Nguồn: ${sources.join(' · ')} | URL đầy đủ trong ghi chú và slide 18`, DESIGN.frames.sources, {
      fontSize: DESIGN.font.caption, color: layout === 'Dark' || layout === 'Cover' ? COLORS.border : COLORS.muted,
    });
  }
  slide.addNotes([
    `Thời lượng dự kiến: ${seconds} giây.`,
    narration,
    sources.length ? `Nguồn tham khảo: ${sources.map((key) => `${key}: ${SOURCES[key].join(' | ')}`).join('\n')}` : '',
    'Đối chiếu mã nguồn: lib/cloud/cloudDocumentService.dart; lib/cloud/cloudDocument.dart; lib/cloud/firebaseBootstrap.dart; firestore.rules; storage.rules. Không sử dụng đề xuất AWS trong báo cáo cũ làm căn cứ kiến trúc.',
  ].filter(Boolean).join('\n\n'));
  timings.push(seconds);
  return slide;
}

{
  const slide = newSlide({
    section: '01 | Bài toán và quyết định', layout: 'Cover',
    title: 'StudyDoc Manager |\nBài tập tích hợp Cloud',
    subtitle: 'Giữ quản lý offline cục bộ.\nBổ sung thư viện Cloud riêng tư trên Web / Android.',
    seconds: 25, sources: ['F1', 'F2'],
    narration: 'Bài tập chọn Firebase Public Cloud theo yêu cầu giảng viên. Mục tiêu là lưu và truy cập tài liệu riêng tư theo tài khoản Google, không thay thế hệ thống SQLite hiện có. Bài trình bày gồm 18 slide, khoảng 11 phút. Bảy nội dung kiểm tra là: bốn thành phần hiện tại; điểm nghẽn; lựa chọn mô hình Cloud; dịch vụ sử dụng; kiến trúc và luồng dữ liệu; bảo mật, chi phí, hiệu năng; thiết lập tài khoản nhóm và demo có bằng chứng. Các slide không giả định nhóm đã có dự án, tài khoản hay kết quả triển khai Cloud thật.',
  });
  badge(slide, 'Firebase Public Cloud · Tệp tối đa 10 MiB', [5, 40, 60, 4], true);
  badge(slide, '01  Hiện trạng', [5, 46, 18, 4], true);
  badge(slide, '02  Thiết kế', [26, 46, 18, 4], true);
  badge(slide, '03  Kiểm chứng', [47, 46, 18, 4], true);
  panel(slide, [72, 13, 30, 16], COLORS.darkSurface);
  text(slide, 'LOCAL', [74, 15, 26, 3], { fontSize: DESIGN.font.caption, bold: true, color: COLORS.orange });
  text(slide, 'SQLite', [74, 20, 26, 5], { fontSize: DESIGN.font.h1, bold: true, color: COLORS.white });
  text(slide, 'Offline · độc lập', [74, 25, 26, 3], { fontSize: DESIGN.font.small, color: COLORS.border });
  panel(slide, [72, 33, 30, 16], COLORS.white);
  text(slide, 'CLOUD', [74, 35, 26, 3], { fontSize: DESIGN.font.caption, bold: true });
  text(slide, 'Firebase', [74, 40, 26, 5], { fontSize: DESIGN.font.h1, bold: true });
  text(slide, 'Google · UID · binary', [74, 45, 26, 3], { fontSize: DESIGN.font.small });
}

{
  const slide = newSlide({
    section: '01 | Bài toán và quyết định', title: 'Hiện trạng: bốn thành phần cốt lõi',
    subtitle: 'Ứng dụng Flutter phân tầng, nghiệp vụ chạy trong tiến trình thiết bị', seconds: 30,
    narration: 'Bốn thành phần hiện tại được đối chiếu với mã nguồn. Giao diện Flutter gồm trang danh sách, biểu mẫu, chi tiết và quản lý môn học. DocumentService thực hiện kiểm tra dữ liệu và thống kê; DatabaseGlobal cùng AppDatabase làm lớp truy cập dữ liệu, không có REST backend độc lập. SQLite có các bảng subjects và documents, lưu metadata như tiêu đề, môn học, deadline, yêu thích và fileUrl. Phần tệp cũ chỉ lưu đường dẫn hoặc URL do người dùng nhập; không có BLOB binary trong bảng SQLite và không phải một object store. Nguồn nội bộ: lib/main.dart; lib/pages; lib/widgets; lib/struct/documentService.dart; lib/database/appDatabase.dart; lib/database/tables.dart.',
  });
  card(slide, '01 | Frontend', 'Flutter Pages + Widgets\nDanh sách, biểu mẫu, chi tiết, môn học', [5, 19, 47, 14], { bodySize: DESIGN.font.small });
  card(slide, '02 | Logic ứng dụng', 'DocumentService + DatabaseGlobal\nValidation, thống kê, lời gọi trực tiếp', [55, 19, 47, 14], { bodySize: DESIGN.font.small });
  card(slide, '03 | Database', 'SQLite: subjects và documents\nMetadata, ghi chú, deadline, trạng thái', [5, 36, 47, 14], { bodySize: DESIGN.font.small });
  card(slide, '04 | File / liên kết', 'fileUrl là đường dẫn hoặc URL\nChưa có kho binary do ứng dụng quản lý', [55, 36, 47, 14], { bodySize: DESIGN.font.small });
  text(slide, 'SQLite lưu metadata, không lưu nội dung tệp trong BLOB.', [5, 51, 97, 3], { fontSize: DESIGN.font.small, bold: true });
}

{
  const slide = newSlide({
    section: '01 | Bài toán và quyết định', title: 'Điểm nghẽn của mô hình cục bộ',
    subtitle: 'Ưu tiên kho tài liệu từ xa theo tài khoản, không phóng đại tốc độ hay quy mô', seconds: 25,
    narration: 'Điểm nghẽn chính là dữ liệu gắn với từng thiết bị, đường dẫn cục bộ không có ý nghĩa trên thiết bị khác, và việc lưu metadata không chứng minh rằng ứng dụng đã lưu hay sao lưu tệp thật. SQLite vẫn có lợi thế sử dụng offline. Không đưa ra số mili giây, số người dùng tối đa hoặc khẳng định dữ liệu mất 100 phần trăm khi chưa đo và chưa kiểm chứng. Phạm vi bài tập xử lý một phần bài toán bằng thư viện Cloud riêng tư, không triển khai cộng tác nhóm hoặc tự đồng bộ SQLite.',
  });
  const issues = [
    ['1', 'Dữ liệu gắn với thiết bị', 'Không có kho từ xa theo tài khoản.'],
    ['2', 'Đường dẫn dễ mất hiệu lực', 'Máy khác không có cùng fileUrl cục bộ.'],
    ['3', 'Metadata không phải tệp thật', 'Chưa có cơ chế backup / versioning.'],
  ];
  issues.forEach(([number, title, body], index) => {
    const vertical = 19 + index * 11;
    panel(slide, [5, vertical, 52, 9]);
    counter(slide, number, 7, vertical + 2);
    text(slide, title, [13, vertical + 1, 42, 3], { fontSize: DESIGN.font.h3, bold: true });
    text(slide, body, [13, vertical + 5, 42, 3], { fontSize: DESIGN.font.small });
  });
  panel(slide, [61, 19, 41, 31], COLORS.ink);
  node(slide, 'Thiết bị 1', 'Metadata + đường dẫn local', [65, 22, 33, 10]);
  text(slide, 'Chưa có kho tài khoản chung', [64, 34, 35, 4], { fontSize: DESIGN.font.small, color: COLORS.orange, align: 'center', valign: 'mid' });
  node(slide, 'Thiết bị 2', 'Dữ liệu local độc lập', [65, 40, 33, 8]);
}

{
  const slide = newSlide({
    section: '01 | Bài toán và quyết định', layout: 'Comparison', title: 'Trước và sau: thay đổi có giới hạn',
    subtitle: 'Sau tích hợp = giữ Local + thêm thư viện Firebase riêng tư, không phải chuyển đổi toàn bộ', seconds: 35,
    narration: 'So sánh bốn khía cạnh. Phần local trước đây không có danh tính Cloud; phần mới dùng Google Auth và UID. Metadata cloud ở Firestore và metadata SQLite vẫn riêng biệt. Tệp mới được upload binary vào Cloud Storage thay vì chỉ giữ đường dẫn. Cùng tài khoản có thể truy cập thư viện Cloud trên Web hoặc Android khi có mạng. Local vẫn offline; thư viện Cloud không có cache file offline và không tự nhập dữ liệu vào SQLite. Bảng này mô tả khả năng trong mã, không chứng nhận triển khai Cloud thật, không hứa đồng bộ hai chiều, chia sẻ nhóm hoặc sao lưu tự động.',
  });
  const columns = [5, 27, 61];
  const widths = [22, 34, 41];
  ['Khía cạnh', 'Truyền thống / cục bộ', 'Sau tích hợp Firebase'].forEach((label, index) => {
    panel(slide, [columns[index], 19, widths[index], 5], index === 2 ? COLORS.orange : COLORS.ink);
    text(slide, label, [columns[index] + 1, 20, widths[index] - 2, 3], { fontSize: DESIGN.font.h4, bold: true, color: index === 2 ? COLORS.ink : COLORS.white, valign: 'mid' });
  });
  const rows = [
    ['Danh tính', 'Không có tài khoản Cloud', 'Google Auth → UID riêng'],
    ['Metadata', 'SQLite trên thiết bị', 'Firestore theo UID;\nSQLite giữ độc lập'],
    ['Tệp tài liệu', 'fileUrl / liên kết nhập tay', 'Storage chứa binary;\ntải bằng SDK có xác thực'],
    ['Truy cập', 'Local offline, từng thiết bị', 'Cloud: cùng UID, cần mạng;\nLocal: vẫn offline'],
  ];
  rows.forEach((row, rowIndex) => row.forEach((value, columnIndex) => {
    const vertical = 25 + rowIndex * 6;
    panel(slide, [columns[columnIndex], vertical, widths[columnIndex], 5.5], rowIndex % 2 === 0 ? COLORS.surface : COLORS.white, COLORS.border);
    text(slide, value, [columns[columnIndex] + 1, vertical + 0.5, widths[columnIndex] - 2, 4.5], { fontSize: DESIGN.font.small, bold: columnIndex === 0, valign: 'mid' });
  }));
  text(slide, 'Không có tự đồng bộ, chia sẻ nhóm hoặc backup tự động trong phạm vi hiện tại.', [5, 51, 97, 3], { fontSize: DESIGN.font.small, bold: true });
}

{
  const slide = newSlide({
    section: '02 | Thiết kế tích hợp', layout: 'Comparison', title: 'Chọn Public Cloud, không gọi nhầm Hybrid',
    subtitle: '“Thư viện riêng tư” là quyền truy cập ứng dụng, không phải mô hình Private Cloud', seconds: 30, sources: ['F8'],
    narration: 'Public Cloud là hạ tầng do nhà cung cấp vận hành, như Firebase trên Google Cloud; đây là lựa chọn bắt buộc theo yêu cầu giảng viên và phù hợp bài tập. Private Cloud là một hạ tầng cloud dành riêng cho tổ chức, không đơn giản là dữ liệu của người dùng được đặt riêng theo UID. Theo định nghĩa NIST, Hybrid Cloud kết hợp các hạ tầng cloud khác nhau và có công nghệ liên kết chúng. SQLite trên thiết bị, kể cả khi được dùng làm cache trong một thiết kế khác, không tự biến hệ thống thành Hybrid Cloud. Ở đây SQLite còn không đóng vai trò cache Firebase vì không có đồng bộ giữa hai kho.',
  });
  card(slide, 'Public Cloud', 'Firebase do Google vận hành.\n\nĐáp ứng yêu cầu giảng viên;\nkhông tự quản trị máy chủ.', [5, 19, 31, 27], { fill: COLORS.orange });
  card(slide, 'Private Cloud', 'Hạ tầng cloud dành riêng\ncho một tổ chức.\n\nKhông được triển khai\ntrong bài tập này.', [38, 19, 31, 27]);
  card(slide, 'Hybrid Cloud', 'Kết hợp nhiều hạ tầng cloud\ncó công nghệ liên kết.\n\nKhông phải Firebase\ncộng với SQLite local.', [71, 19, 31, 27]);
  badge(slide, 'ĐÃ CHỌN', [7, 40, 14, 4]);
  callout(slide, 'SQLite local / cache ≠ Private Cloud; Local + Public Cloud không tự động là Hybrid Cloud.', [5, 48, 97, 3]);
}

{
  const slide = newSlide({
    section: '02 | Thiết kế tích hợp', title: 'Firebase: BaaS và bộ dịch vụ được chọn',
    subtitle: 'Ứng dụng gọi Firebase SDK; nhóm vẫn chịu trách nhiệm Rules, cấu hình, chi phí và kiểm thử', seconds: 35, sources: ['F1', 'F2', 'F3', 'F5'],
    narration: 'Firebase cung cấp các dịch vụ backend được quản lý, thường được mô tả là Backend-as-a-Service. Auth xác thực tài khoản Google và cấp UID. Firestore lưu metadata tài liệu theo UID. Cloud Storage lưu byte thực của PDF, Office, văn bản, ZIP và ảnh. Hosting chỉ là lựa chọn để phục vụ bản Flutter Web tĩnh hoặc SPA; Hosting không thay thế kho tệp riêng tư. Trong phạm vi này không có backend REST riêng, Cloud Functions, OCR hay dịch vụ AWS. Nhà cung cấp vận hành hạ tầng, nhưng nhóm phải tạo dự án, triển khai Rules đúng, quản lý billing và thu thập bằng chứng thực tế.',
  });
  panel(slide, [5, 19, 31, 31], COLORS.ink);
  text(slide, 'BaaS', [7, 22, 27, 9], { fontSize: DESIGN.font.stat, color: COLORS.orange, bold: true });
  text(slide, 'Backend-as-a-Service', [7, 32, 27, 4], { fontSize: DESIGN.font.small, color: COLORS.white });
  text(slide, 'SDK phía client\n+ dịch vụ quản lý\n+ Security Rules', [7, 39, 27, 9], { fontSize: DESIGN.font.h3, color: COLORS.white });
  card(slide, 'Firebase Auth', 'Google → UID\nDanh tính người dùng', [40, 19, 30, 14], { bodySize: DESIGN.font.small });
  card(slide, 'Cloud Firestore', 'Metadata theo UID\nDanh sách qua snapshots()', [73, 19, 29, 14], { bodySize: DESIGN.font.small });
  card(slide, 'Cloud Storage', 'Binary thực của tài liệu\nputData() / getData()', [40, 36, 30, 14], { bodySize: DESIGN.font.small });
  card(slide, 'Hosting tùy chọn', 'Flutter Web tĩnh / SPA\nKhông chứa file riêng tư', [73, 36, 29, 14], { bodySize: DESIGN.font.small });
}

{
  const slide = newSlide({
    section: '02 | Thiết kế tích hợp', layout: 'Diagram', title: 'Kiến trúc: hai kho, hai trách nhiệm',
    subtitle: 'Sơ đồ native PowerPoint: tất cả khối và mũi tên có thể chỉnh sửa', seconds: 55, sources: ['F1', 'F2', 'F3', 'F5'],
    narration: 'Đọc sơ đồ từ trái sang phải. Ứng dụng Flutter giữ hai khu vực: Local với SQLite và thư viện Cloud cho Web hoặc Android. CloudDocumentService chạy phía client, gọi SDK tới Google Auth, Firestore và Storage. Auth cung cấp UID. Firestore lưu metadata nhỏ. Storage lưu binary, cả đọc và ghi được kiểm tra bằng Security Rules đã deploy. Mũi tên thể hiện lời gọi SDK, không phải API Gateway hay một backend tự xây. Không có mũi tên đồng bộ SQLite với Firestore. Hosting tùy chọn không nằm trong đường truyền tài liệu riêng tư. Sơ đồ trình bày kiến trúc đã viết trong mã; nhóm phải triển khai lên dự án thật để xác nhận vận hành.',
  });
  panel(slide, [5, 19, 30, 31]);
  panel(slide, [46, 19, 56, 31]);
  text(slide, 'Ứng dụng Flutter', [7, 21, 26, 4], { fontSize: DESIGN.font.h3, bold: true });
  text(slide, 'Firebase | Public Cloud', [49, 21, 50, 4], { fontSize: DESIGN.font.h2, bold: true });
  node(slide, 'Cloud UI + SDK', 'CloudDocumentService', [7, 27, 26, 10], true);
  node(slide, 'SQLite offline', 'Độc lập, không tự sync', [7, 40, 26, 9]);
  node(slide, 'Auth + Google', 'UID của người dùng', [50, 26, 49, 9], true);
  node(slide, 'Firestore', 'Metadata\ntheo UID', [50, 39, 23, 10]);
  node(slide, 'Storage', 'Binary\ntheo UID', [76, 39, 23, 10]);
  arrow(slide, [33, 32], [40, 32], COLORS.orange);
  arrow(slide, [40, 29], [40, 44], COLORS.orange);
  arrow(slide, [40, 29], [50, 29], COLORS.orange);
  arrow(slide, [40, 44], [50, 44], COLORS.orange);
  arrow(slide, [40, 37], [87.5, 37], COLORS.orange);
  arrow(slide, [87.5, 37], [87.5, 39], COLORS.orange);
  text(slide, 'SDK', [36, 24, 8, 3], { fontSize: DESIGN.font.small, bold: true, align: 'center' });
  text(slide, 'Rules kiểm tra UID / đường dẫn / dữ liệu', [49, 50, 50, 2], { fontSize: DESIGN.font.caption, color: COLORS.muted });
}

{
  const slide = newSlide({
    section: '02 | Thiết kế tích hợp', layout: 'Diagram', title: 'Ba luồng dữ liệu chính',
    subtitle: 'Đăng nhập → danh tính; upload → binary + metadata; download → byte được xác thực', seconds: 40, sources: ['F2', 'F4'],
    narration: 'Đăng nhập Web dùng signInWithPopup với GoogleAuthProvider. Android lấy Google ID token rồi signInWithCredential. Firebase Auth cung cấp UID cho thư viện riêng. Upload kiểm tra trường dữ liệu, phần mở rộng và tối đa 10 MiB trước khi putData vào Storage rồi ghi metadata bằng doc.set. Download chọn metadata, kiểm tra ownerId và storagePath ở client, sau đó gọi Storage getData với maxBytes, đồng thời Rules phía dịch vụ kiểm tra UID. Code không gọi getDownloadURL và không phát hành public link. getData trả Uint8List và nạp toàn bộ tệp vào RAM; đây không phải cơ chế cache tệp Cloud để xem offline.',
  });
  const flows = [
    ['1  Đăng nhập', ['Google', 'Firebase Auth', 'UID', 'Kho riêng']],
    ['2  Upload', ['Tệp ≤10 MiB', 'putData()', 'doc.set()', 'Danh sách']],
    ['3  Download', ['Chọn tài liệu', 'Kiểm tra chủ', 'getData()', 'Binary']],
  ];
  const steps = [[26, 16], [46, 18], [68, 13], [85, 17]];
  flows.forEach(([label, values], flowIndex) => {
    const vertical = 19 + flowIndex * 10;
    panel(slide, [5, vertical, 97, 8]);
    text(slide, label, [7, vertical + 2, 18, 4], { fontSize: DESIGN.font.h4, bold: true, valign: 'mid' });
    values.forEach((value, stepIndex) => {
      const [horizontal, width] = steps[stepIndex];
      panel(slide, [horizontal, vertical + 1, width, 6], stepIndex === 3 ? COLORS.orange : COLORS.white, stepIndex === 3 ? COLORS.orange : COLORS.border);
      text(slide, value, [horizontal + 0.5, vertical + 1.5, width - 1, 5], { fontSize: DESIGN.font.small, align: 'center', valign: 'mid', bold: stepIndex === 3 });
      if (stepIndex < steps.length - 1) arrow(slide, [horizontal + width, vertical + 4], [steps[stepIndex + 1][0], vertical + 4]);
    });
  });
  callout(slide, 'Tải bằng SDK có xác thực; không tạo getDownloadURL và không phát hành public link.', [5, 48, 97, 3]);
}

{
  const slide = newSlide({
    section: '02 | Thiết kế tích hợp', layout: 'Diagram', title: 'Nhất quán giữa Storage và Firestore',
    subtitle: 'Không có transaction chung giữa hai dịch vụ: chọn thứ tự thao tác và xử lý lỗi rõ ràng', seconds: 40,
    narration: 'Upload trước tiên hoàn tất object Storage, sau đó ghi metadata Firestore. Nếu ghi metadata thất bại, code cố xóa object để bù trừ. Nếu cleanup cũng thất bại, thông báo trả đường dẫn tệp mồ côi để xử lý trong Console; không hứa rollback hoàn hảo. Xóa thực hiện Storage trước, Firestore sau. Nếu object đã mất, code bỏ qua object-not-found để cho phép người dùng thử xóa lại metadata. Nếu xóa metadata lỗi, việc retry thao tác xóa là an toàn đối với object đã xóa; đây là khả năng thử lại, không phải hàng đợi retry tự động. Nhóm cần demo đường thành công và kiểm tra lỗi trong môi trường test phù hợp.',
  });
  panel(slide, [5, 19, 47, 31]);
  panel(slide, [55, 19, 47, 31]);
  text(slide, 'Upload có bù trừ', [7, 21, 43, 4], { fontSize: DESIGN.font.h2, bold: true });
  text(slide, 'Xóa có thể thử lại', [57, 21, 43, 4], { fontSize: DESIGN.font.h2, bold: true });
  const upload = [
    ['01  Upload object', 'putData() hoàn tất trước.'],
    ['02  Ghi metadata', 'doc.set() sau khi có binary.'],
    ['03  Metadata lỗi → cleanup', 'Cleanup lỗi: xử lý trong Console.'],
  ];
  const deletion = [
    ['01  Xóa Storage', 'Object đã mất: vẫn đi tiếp.'],
    ['02  Xóa Firestore', 'Chỉ xóa metadata sau object.'],
    ['03  Metadata lỗi → thử lại', 'Không phải retry tự động nền.'],
  ];
  [upload, deletion].forEach((flow, flowIndex) => flow.forEach(([title, detail], index) => {
    const horizontal = flowIndex === 0 ? 7 : 57;
    const vertical = 27 + index * 8;
    text(slide, title, [horizontal, vertical, 43, 3], { fontSize: DESIGN.font.h4, bold: true });
    text(slide, detail, [horizontal, vertical + 3, 43, 4], { fontSize: DESIGN.font.small, color: COLORS.muted });
  }));
  text(slide, 'Bù trừ giảm rủi ro dữ liệu lệch; không thay thế một transaction xuyên dịch vụ.', [5, 51, 97, 3], { fontSize: DESIGN.font.small, bold: true });
}

{
  const slide = newSlide({
    section: '02 | Thiết kế tích hợp', layout: 'Diagram', title: 'Schema: metadata khác với binary',
    subtitle: 'UID và documentId liên kết quyền sở hữu với đường dẫn object, không lưu URL công khai', seconds: 30,
    narration: 'Firestore lưu document trong users/{uid}/documents/{documentId}. Chín trường đúng với code là ownerId, title, subject, note, fileName, contentType, size, storagePath và createdAt. createdAt được ghi bằng serverTimestamp, Rules yêu cầu bằng thời gian request khi tạo. Storage object luôn ở users/{uid}/documents/{documentId}/file. documentId do Firestore cấp, tên tệp gốc nằm ở metadata. Rules chỉ cho chỉnh title và note; ownerId, path và thông tin tệp không được thay đổi bằng update. Cặp schema này không liên kết với subjects trong SQLite và không tạo cơ chế đồng bộ.',
  });
  panel(slide, [5, 19, 57, 31], COLORS.ink);
  panel(slide, [65, 19, 37, 31]);
  text(slide, 'Cloud Firestore', [7, 21, 53, 4], { fontSize: DESIGN.font.h2, bold: true, color: COLORS.white });
  text(slide, 'users/{uid}/documents/{documentId}', [7, 28, 53, 4], { fontSize: DESIGN.font.small, color: COLORS.orange });
  text(slide, 'ownerId, title, subject, note\nfileName, contentType, size\nstoragePath, createdAt', [7, 36, 53, 11], { fontSize: DESIGN.font.body, color: COLORS.white });
  text(slide, 'Cloud Storage', [67, 21, 33, 4], { fontSize: DESIGN.font.h2, bold: true });
  text(slide, 'users/{uid}/documents/\n{documentId}/file', [67, 28, 33, 7], { fontSize: DESIGN.font.small, bold: true });
  text(slide, 'Nội dung binary thực\nKhông có public URL', [67, 39, 33, 8], { fontSize: DESIGN.font.body });
  text(slide, 'Chỉ sửa title và note; createdAt = serverTimestamp().', [5, 51, 97, 3], { fontSize: DESIGN.font.small, bold: true });
}

{
  const slide = newSlide({
    section: '03 | Bảo mật, chi phí, hiệu năng', title: 'Bảo mật: chặn ở dịch vụ, không chỉ UI',
    subtitle: 'Thư viện theo chủ sở hữu; không có RBAC hoặc chia sẻ tài liệu giữa nhóm người dùng', seconds: 40, sources: ['F3', 'F5'],
    narration: 'Điều kiện cốt lõi là có request.auth và request.auth.uid trùng uid trong path. Client có kiểm tra ownerId và storagePath, nhưng Security Rules đã deploy mới là ranh giới bảo mật phía dịch vụ. Firestore kiểm tra đủ và đúng chín trường, kiểu dữ liệu, ownerId, đường dẫn, giới hạn chuỗi và timestamp. Storage chỉ cho tạo object với MIME được cho phép, dữ liệu lớn hơn 0 và tối đa 10 MiB; không cho ghi đè object. Định dạng được chấp nhận là PDF, DOCX, PPTX, XLSX, TXT, ZIP, PNG, JPG/JPEG. MIME và phần mở rộng không phải quét malware hay xác minh nội dung tệp. Tài khoản khác và người chưa đăng nhập phải bị chặn khi truy cập đường dẫn trực tiếp. CORS chỉ cho phép nguồn Web phù hợp, không cấp quyền thay Rules. Không dùng service-account key trong app.',
  });
  panel(slide, [5, 19, 45, 28], COLORS.ink);
  text(slide, 'Security Rules', [7, 21, 41, 4], { fontSize: DESIGN.font.h2, color: COLORS.white, bold: true });
  text(slide, 'request.auth != null\nrequest.auth.uid == uid', [7, 28, 41, 7], { fontSize: DESIGN.font.h3, color: COLORS.orange, bold: true });
  text(slide, 'Firestore: trường + chủ + path\nStorage: MIME, 0 < size ≤10 MiB\nKhông ghi đè object', [7, 38, 41, 8], { fontSize: DESIGN.font.small, color: COLORS.white });
  const cases = [
    ['UID trùng đường dẫn', 'Cho phép theo Rules của chủ sở hữu', COLORS.success],
    ['UID khác chủ sở hữu', 'Từ chối đọc / ghi dữ liệu của người khác', COLORS.error],
    ['Chưa đăng nhập', 'Từ chối truy cập kho Cloud', COLORS.error],
  ];
  cases.forEach(([title, body, color], index) => {
    const vertical = 19 + index * 10;
    panel(slide, [54, vertical, 48, 8]);
    text(slide, title, [56, vertical + 1, 44, 3], { fontSize: DESIGN.font.h4, bold: true, color });
    text(slide, body, [56, vertical + 4, 44, 3], { fontSize: DESIGN.font.small });
  });
  callout(slide, 'CORS không thay thế Rules. Không công khai bucket và không phát hành link tải public.', [5, 48, 97, 3]);
}

{
  const slide = newSlide({
    section: '03 | Bảo mật, chi phí, hiệu năng', title: 'Chi phí: Blaze và kiểm soát mức dùng',
    subtitle: 'Không cam kết “miễn phí $0”; phải kiểm tra giá theo vùng và loại tài nguyên thực tế', seconds: 35, sources: ['F6', 'F7'],
    narration: 'Theo Firebase, từ tháng 2 năm 2026, Cloud Storage for Firebase yêu cầu dự án dùng gói Blaze và gắn Cloud Billing; việc tạo bucket mới đã yêu cầu Blaze từ trước. Slide dùng mốc tháng để tránh nhầm ngày triển khai yêu cầu. Có thể có mức dùng miễn phí trên Blaze, nhưng phụ thuộc loại bucket, khu vực và mức dùng, nên không bảo đảm hóa đơn bằng 0. Firestore có chi phí đọc, ghi, xóa, dung lượng và các mục tính phí liên quan; Storage tính dung lượng, thao tác, lưu lượng ra theo vùng và điều kiện. Thiết lập budget alerts cho chủ billing của nhóm, kiểm tra usage và dọn dữ liệu demo. Budget alerts chỉ là thông báo, không tự dừng Storage hoặc Firestore và không phải hard cap chi phí. Không đưa ra giá USD hư cấu khi chưa biết vùng và tài nguyên của dự án thật.',
  });
  panel(slide, [5, 19, 35, 31], COLORS.ink);
  text(slide, 'YÊU CẦU ĐỂ DÙNG STORAGE', [7, 21, 31, 3], { fontSize: DESIGN.font.caption, color: COLORS.border, bold: true });
  text(slide, 'Blaze', [7, 26, 31, 9], { fontSize: DESIGN.font.stat, color: COLORS.orange, bold: true });
  text(slide, 'Từ tháng 02/2026', [7, 36, 31, 4], { fontSize: DESIGN.font.h3, color: COLORS.white, bold: true });
  text(slide, 'Gắn Cloud Billing.\nKhông bảo đảm chi phí $0.', [7, 43, 31, 6], { fontSize: DESIGN.font.small, color: COLORS.white });
  text(slide, 'Đơn giá phụ thuộc vùng và mức dùng', [45, 20, 57, 4], { fontSize: DESIGN.font.h2, bold: true });
  text(slide, 'Firestore: reads / writes / deletes.\nStorage: dung lượng, thao tác, egress.\nKiểm tra bảng giá và usage thật.', [45, 27, 57, 10], { fontSize: DESIGN.font.body });
  panel(slide, [45, 39, 57, 11]);
  text(slide, 'Budget alerts ≠ hard cap', [47, 41, 53, 4], { fontSize: DESIGN.font.h3, bold: true });
  text(slide, 'Cảnh báo không tự dừng phát sinh phí.', [47, 46, 53, 3], { fontSize: DESIGN.font.small });
}

{
  const slide = newSlide({
    section: '03 | Bảo mật, chi phí, hiệu năng', title: 'Hiệu năng: bắt đầu từ workload có thật',
    subtitle: 'Ví dụ khối lượng cho một kỳ đánh giá, không phải kết quả benchmark hay dự toán giá', seconds: 30, sources: ['F4', 'F7'],
    narration: 'Đặt giả định rõ ràng: có 30 tài liệu, mỗi tài liệu đúng 2 MiB, nên phần binary lưu là 60 MiB. Có 120 lượt download đầy đủ, mỗi lượt 2 MiB, nên khối lượng file đi ra là 240 MiB. Đây chỉ là phép tính workload giả định, không phải lưu lượng tính phí đã đo; chưa tính metadata, reads của listeners, request retries, overhead hoặc cách nhà cung cấp tính phí. Không có cache file Cloud trong bản này nên không trừ đi lượt tải từ cache. getData nạp toàn bộ tệp vào RAM, vì thế giới hạn 10 MiB cần được tôn trọng. Tốc độ còn tùy mạng, vùng Firestore/Storage và thiết bị; nhóm phải đo upload, download, lỗi và số lần đọc trên dự án thật trước khi công bố benchmark.',
  });
  panel(slide, [5, 19, 47, 17]);
  panel(slide, [55, 19, 47, 17], COLORS.orange);
  text(slide, 'BINARY LƯU TRỮ', [7, 21, 43, 3], { fontSize: DESIGN.font.caption, bold: true });
  text(slide, '60 MiB', [7, 26, 43, 8], { fontSize: DESIGN.font.stat, bold: true });
  text(slide, '30 tài liệu × 2 MiB', [7, 33, 43, 3], { fontSize: DESIGN.font.small });
  text(slide, 'DỮ LIỆU FILE ĐI RA', [57, 21, 43, 3], { fontSize: DESIGN.font.caption, bold: true });
  text(slide, '240 MiB', [57, 26, 43, 8], { fontSize: DESIGN.font.stat, bold: true });
  text(slide, '120 download × 2 MiB', [57, 33, 43, 3], { fontSize: DESIGN.font.small });
  panel(slide, [5, 39, 97, 11]);
  text(slide, 'Giả định tải đủ tệp, không cache; chưa tính overhead', [7, 41, 93, 4], { fontSize: DESIGN.font.h3, bold: true });
  text(slide, 'getData nạp toàn bộ tệp vào RAM. Tốc độ tùy mạng và vị trí dịch vụ.\nCần đo trên dự án thật trước khi công bố số giây, độ trễ hoặc mức cải thiện.', [7, 46, 93, 4], { fontSize: DESIGN.font.small });
}

function checklistTile(slide, title, body, horizontal, vertical, highlight = false) {
  panel(slide, [horizontal, vertical, 31, 14], highlight ? COLORS.orange : COLORS.surface);
  text(slide, title, [horizontal + 2, vertical + 2, 27, 4], { fontSize: DESIGN.font.h4, bold: true });
  text(slide, body, [horizontal + 2, vertical + 8, 27, 5], { fontSize: DESIGN.font.small });
}

{
  const slide = newSlide({
    section: '04 | Thiết lập và nghiệm thu', layout: 'Runbook', title: 'Thiết lập nhóm 1: Console và tài khoản',
    subtitle: 'Dùng thông tin thật do nhóm tạo; không bịa tên nhóm, project ID hoặc ảnh Console', seconds: 40, sources: ['F1', 'F2', 'F6'],
    narration: 'Nhóm thống nhất người chịu trách nhiệm billing và tạo dự án trên Firebase Console bằng tài khoản Google thật được phép sử dụng. Mời các thành viên qua quyền IAM phù hợp, không chia sẻ mật khẩu. IAM quản trị project không phải RBAC chia sẻ tài liệu trong ứng dụng. Đăng ký ứng dụng Web, lưu firebaseConfig thực của project. Bật provider Google trong Authentication và thêm localhost hoặc tên miền triển khai vào Authorized domains nếu chưa có; không giả định localhost tự được thêm. Tạo Firestore, chọn region phù hợp và không dùng Rules test mở. Chuyển Blaze với sự đồng ý của chủ billing, tạo Storage bucket và thiết lập budget alerts. Nếu demo Android: đăng ký applicationId thực trong android/app/build.gradle.kts, thêm SHA-1/SHA-256 của bản build và cấu hình OAuth Web client ID cho GOOGLE_SERVER_CLIENT_ID. Chưa có thông tin tài khoản hoặc project thật nên slide là hướng dẫn, không phải biên bản hoàn tất.',
  });
  const items = [
    ['01 | Dự án + nhóm', 'Tài khoản Google thật.\nMời thành viên bằng IAM.'],
    ['02 | Web + Google', 'Bật provider Google.\nLưu cấu hình Web thật.'],
    ['03 | Miền hợp lệ', 'Thêm localhost / tên miền\nvào Authorized domains.'],
    ['04 | Firestore', 'Chọn vị trí database.\nKhông dùng Rules test mở.'],
    ['05 | Blaze + Storage', 'Gắn Billing, tạo bucket.\nChọn vùng, bật cảnh báo.'],
    ['06 | Android', 'applicationId, SHA-1/256.\nOAuth Web client ID thật.'],
  ];
  items.forEach(([title, body], index) => checklistTile(slide, title, body, 5 + (index % 3) * 33, index < 3 ? 19 : 36));
}

{
  const slide = newSlide({
    section: '04 | Thiết lập và nghiệm thu', layout: 'Runbook', title: 'Thiết lập nhóm 2: config, Rules, CORS',
    subtitle: 'Chạy từ thư mục repo; project ID và bucket phải lấy từ cấu hình thật của nhóm', seconds: 50, sources: ['F4'],
    narration: 'Chuẩn bị Node/Firebase CLI, Google Cloud CLI và Flutter. Lưu JSON firebaseConfig của Web app thật từ Console vào firebase_web_config.json, gồm apiKey, appId, messagingSenderId, projectId, storageBucket, authDomain. Chạy scripts/configure_firebase.ps1 với WebConfigPath; script tạo firebase_config.json và từ chối demo project ID cũng như ghi đè file đang tồn tại. Đọc file đã sinh bằng PowerShell: $firebaseConfig = Get-Content -Raw firebase_config.json | ConvertFrom-Json; $env:FIREBASE_PROJECT_ID = $firebaseConfig.FIREBASE_PROJECT_ID; $env:FIREBASE_STORAGE_BUCKET = $firebaseConfig.FIREBASE_STORAGE_BUCKET. Đăng nhập Firebase CLI và deploy firestore.rules cùng storage.rules vào đúng project qua --project. CORS hiện cho GET/HEAD từ localhost:7357 và 127.0.0.1:7357; bổ sung đúng origin Hosting nếu triển khai Web, không dùng wildcard tùy tiện. Chạy gcloud auth login với tài khoản có quyền quản trị bucket, rồi cập nhật CORS. flutter run dùng --dart-define-from-file=firebase_config.json và không bật USE_FIREBASE_EMULATOR. Trong PowerShell dấu backtick nối dòng. Android dùng cấu hình Android thực của cùng project, đặc biệt FIREBASE_APP_ID dạng Android và GOOGLE_SERVER_CLIENT_ID là OAuth Web client ID; lưu vào firebase_android_config.json rồi dùng flutter run --dart-define-from-file=firebase_android_config.json. Không đưa service-account private key vào các file cấu hình client. Hosting tùy chọn: flutter build web --dart-define-from-file=firebase_config.json, sau đó firebase deploy --only hosting --project $env:FIREBASE_PROJECT_ID.',
  });
  const commands = [
    ['01  Web → JSON', 'Nguồn: Console thật', 'pwsh -File scripts/configure_firebase.ps1 `\n  -WebConfigPath firebase_web_config.json'],
    ['02  Rules', 'ID từ JSON đã sinh', 'firebase login\nfirebase deploy --only firestore:rules,storage --project $env:FIREBASE_PROJECT_ID'],
    ['03  CORS', 'Thêm đúng origin Web', 'gcloud storage buckets update `\n  "gs://$env:FIREBASE_STORAGE_BUCKET" --cors-file=storage.cors.json'],
    ['04  Chạy Web', 'Không bật Emulator', 'flutter run -d chrome --web-port=7357 `\n  --dart-define-from-file=firebase_config.json'],
  ];
  commands.forEach(([label, detail, command], index) => {
    const vertical = 19 + index * 8;
    panel(slide, [5, vertical, 97, 7]);
    text(slide, label, [7, vertical + 1, 22, 3], { fontSize: DESIGN.font.h4, bold: true });
    text(slide, detail, [7, vertical + 4, 22, 2.5], { fontSize: DESIGN.font.code, color: COLORS.muted });
    text(slide, command, [31, vertical + 1, 69, 5], { fontSize: DESIGN.font.code });
  });
}

{
  const slide = newSlide({
    section: '04 | Thiết lập và nghiệm thu', title: 'Demo: bằng chứng trên Cloud thật',
    subtitle: 'Checklist cần ghi nhận, không phải kết quả đã chạy hoặc ảnh tài khoản giả', seconds: 65,
    narration: 'Demo khoảng một phút với dữ liệu nhỏ và thời gian dự phòng. Trước khi chạy, xác nhận không có banner Emulator và app trỏ đúng project thật; Google popup hoặc Google sign-in Android phải là luồng thật. Thu bằng chứng Auth Console với provider Google và UID, che thông tin cá nhân khi nộp. Tài khoản thứ nhất trên thiết bị thứ nhất upload một tệp hợp lệ; ghi lại tiến trình và kết quả, đối chiếu Firestore metadata và object Storage cùng documentId, path, size và MIME. Trên thiết bị thứ hai đăng nhập cùng tài khoản và tải đủ tệp, mở kiểm tra nội dung hoặc so sánh hash với tệp gốc. Dùng tài khoản Google thứ hai để chứng minh kho riêng; không chỉ thấy danh sách rỗng mà thử đọc trực tiếp đường dẫn của tài khoản một bằng SDK và nhận permission-denied hoặc unauthorized. Kiểm tra file quá 10 MiB hoặc định dạng không cho phép; kiểm tra xóa và thử lại khi metadata chưa xóa trong môi trường test có kiểm soát. Emulator giúp kiểm thử Rules và nhánh lỗi, nhưng tài khoản giả trong Emulator không chứng minh Google OAuth, bucket thật, billing hay tải Cloud. Nhóm cần ảnh hoặc video thật kèm thời điểm và các bước, không chụp token, mật khẩu hay service-account key.',
  });
  const items = [
    ['01 | Google thật', 'Đăng nhập, đối chiếu UID.\nAuth Console: provider Google.'],
    ['02 | Upload binary', 'Firestore + object Storage.\nĐối chiếu path, size, MIME.'],
    ['03 | Thiết bị thứ hai', 'Cùng UID → tải đủ tệp.\nKiểm tra nội dung / hash.'],
    ['04 | Tài khoản thứ hai', 'Kho riêng không có tệp A.\nĐọc đường dẫn A: bị chặn.'],
    ['05 | Lỗi + xóa', 'Tệp >10 MiB bị chặn.\nXóa object rồi metadata.'],
    ['06 | Emulator ≠ Cloud', 'Chỉ là kiểm thử cục bộ.\nKhông là bằng chứng Cloud.'],
  ];
  items.forEach(([title, body], index) => checklistTile(slide, title, body, 5 + (index % 3) * 33, index < 3 ? 19 : 36, index === 5));
  text(slide, 'Chỉ đánh dấu hoàn tất sau khi lưu bằng chứng thật của từng bước.', [5, 51, 97, 3], { fontSize: DESIGN.font.small, bold: true });
}

{
  const slide = newSlide({
    section: '04 | Thiết lập và nghiệm thu', layout: 'Dark', title: 'Giới hạn rõ ràng, kết luận có điều kiện',
    subtitle: 'Không đánh đồng “có mã triển khai” với “đã nghiệm thu Google / Cloud thật”', seconds: 35,
    narration: 'Kết luận: Firebase Public Cloud đáp ứng lựa chọn nền tảng của bài tập, trong khi SQLite vẫn độc lập để giữ quản lý tài liệu local offline. Thư viện Cloud có Auth Google, metadata theo UID, Storage binary và tải qua SDK xác thực, tối đa 10 MiB. Chưa có tự đồng bộ SQLite với Firestore, cache file Cloud offline, RBAC, chia sẻ nhóm, OCR, backup hoặc versioning; những khả năng đó chỉ nằm trong lộ trình cần thiết kế và kiểm thử riêng. Không coi độ bền của nhà cung cấp là backup ứng dụng đã triển khai. Điều kiện nghiệm thu là nhóm tạo dự án thật, bật Google, deploy Rules, cấu hình billing và CORS đúng, rồi hoàn thành bằng chứng hai thiết bị và hai tài khoản. Không thể thay điều kiện này bằng demo Emulator.',
  });
  panel(slide, [5, 19, 47, 23], COLORS.darkSurface);
  panel(slide, [55, 19, 47, 23], COLORS.white);
  text(slide, 'Giá trị hiện tại trong code', [7, 21, 43, 4], { fontSize: DESIGN.font.h3, bold: true, color: COLORS.orange });
  text(slide, 'Local vẫn quản lý offline.\nCloud lưu metadata + binary.\nQuyền truy cập theo UID.\nHỗ trợ Web và Android.', [7, 29, 43, 11], { fontSize: DESIGN.font.body, color: COLORS.white });
  text(slide, 'Lộ trình, chưa triển khai', [57, 21, 43, 4], { fontSize: DESIGN.font.h3, bold: true });
  text(slide, 'Sync SQLite ↔ Firestore;\ncache file Cloud offline;\nRBAC, chia sẻ nhóm, OCR;\nbackup và versioning.', [57, 29, 43, 11], { fontSize: DESIGN.font.body });
  callout(slide, 'Kết luận: giữ SQLite độc lập, bổ sung Firebase; nghiệm thu bằng dữ liệu trên Cloud thật.', [5, 45, 97, 6], true);
}

{
  const slide = newSlide({
    section: '05 | Tài liệu đối chiếu', title: 'Nguồn chính thức và mã nguồn đối chiếu',
    subtitle: 'Liên kết có thể bấm; URL đầy đủ trong speaker notes. Đối chiếu ngày 08/10/2026.', seconds: 20,
    narration: `Tài liệu chính thức Firebase và NIST dùng để kiểm tra khái niệm, Auth, Rules, download SDK và chi phí. Những mô tả tính năng dựa trực tiếp vào mã nguồn trong repo, không dựa vào đề xuất AWS, Sync Engine hay public CDN của báo cáo cũ. Các nguồn tham khảo:\n${Object.entries(SOURCES).map(([key, details]) => `${key}: ${details.join(' | ')}`).join('\n')}\nNguồn nội bộ: lib/cloud/cloudDocumentService.dart; lib/cloud/cloudDocument.dart; lib/cloud/firebaseBootstrap.dart; firestore.rules; storage.rules; storage.cors.json; scripts/configure_firebase.ps1; lib/struct/documentService.dart; lib/database/appDatabase.dart; lib/database/tables.dart. Ngày đối chiếu nội dung: 08/10/2026. Đơn giá và yêu cầu cấu hình cần kiểm tra lại tại thời điểm triển khai thật.`,
  });
  panel(slide, [5, 19, 47, 31]);
  panel(slide, [55, 19, 47, 31]);
  const labels = [
    'Firebase / BaaS', 'Google Auth cho Flutter', 'Firestore Security Rules', 'Storage: tải bằng SDK',
    'Storage Security Rules', 'Storage yêu cầu Blaze', 'Giá và budget alerts', 'NIST: Hybrid Cloud',
  ];
  Object.entries(SOURCES).forEach(([key, details], index) => {
    const horizontal = index < 4 ? 7 : 57;
    const vertical = 21 + (index % 4) * 7;
    counter(slide, key, horizontal, vertical);
    text(slide, labels[index], [horizontal + 6, vertical, 36, 3], { fontSize: DESIGN.font.h4, bold: true, hyperlink: { url: details[1] } });
    text(slide, key === 'F8' ? 'csrc.nist.gov' : 'firebase.google.com', [horizontal + 6, vertical + 3, 36, 3], { fontSize: DESIGN.font.small, color: COLORS.muted, hyperlink: { url: details[1] } });
  });
  text(slide, 'Mã nguồn: lib/cloud/* · firestore.rules · storage.rules · scripts/configure_firebase.ps1', [5, 51, 97, 3], { fontSize: DESIGN.font.caption, color: COLORS.muted });
}

async function applyDeckTheme() {
  const JSZip = require(require.resolve('jszip', { paths: [require.resolve('pptxgenjs')] }));
  const archive = await JSZip.loadAsync(fs.readFileSync(OUTPUT));
  const themePart = 'ppt/theme/theme1.xml';
  const original = await archive.file(themePart).async('string');
  const xmlName = THEME.name.replace(/&/g, '&amp;');
  const colorXml = Object.entries(THEME.colors).map(([slot, color]) =>
    `<a:${slot}><a:srgbClr val="${color}"/></a:${slot}>`).join('');
  archive.file(themePart, original.replace(/<a:clrScheme\b[\s\S]*?<\/a:clrScheme>/,
    `<a:clrScheme name="${xmlName}">${colorXml}</a:clrScheme>`)
    .replace(/(<a:(?:theme|fontScheme)\b[^>]*?\bname=")[^"]*"/g, `$1${xmlName}"`));
  fs.writeFileSync(OUTPUT, await archive.generateAsync({ type: 'nodebuffer', compression: 'DEFLATE' }));
}

async function main() {
  await presentation.writeFile({ fileName: OUTPUT });
  await applyDeckTheme();
  console.log(`Generated ${OUTPUT}`);
  console.log(`Slides: ${presentation.slides.length}; planned narration: ${timings.reduce((total, duration) => total + duration, 0)} seconds.`);
}

if (require.main === module) main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
