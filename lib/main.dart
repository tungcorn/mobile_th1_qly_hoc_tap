import 'package:flutter/material.dart';
import 'colors.dart';
import 'pages/homePage.dart';
import 'struct/databaseGlobal.dart';
import 'struct/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Khởi tạo Singleton Database toàn cục theo đúng nguyên lý Cashew
    await initGlobalDatabase();
  } catch (e, stack) {
    debugPrint('Lỗi khởi tạo cơ sở dữ liệu: $e\n$stack');
  }

  runApp(const StudyDocApp());
}

/// [StudyDocApp]: Widget gốc của Ứng dụng Quản lý Tài liệu Học tập
class StudyDocApp extends StatelessWidget {
  const StudyDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Quản lý Tài liệu Học tập',
          debugShowCheckedModeBanner: false,
          theme: AppColors.lightTheme,
          darkTheme: AppColors.darkTheme,
          themeMode: themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}
