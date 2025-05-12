import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/storage_service.dart';
import '../widgets/feature_card.dart';
import 'camera_page.dart';
import 'history_page.dart';
import 'language_selection_page.dart';

class HomePage extends StatelessWidget {
  final String langCode;

  const HomePage({super.key, required this.langCode});

  void _openCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CameraPage(langCode: langCode)),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HistoryPage(langCode: langCode)),
    );
  }

  Future<void> _changeLanguage(BuildContext context) async {
    final storage = StorageService();
    await storage.saveLanguage('');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LanguageSelectionPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Car AI Analyzer' : 'Car AI Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _openHistory(context),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _changeLanguage(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isVi ? 'Car AI Analyzer' : 'Car AI Analyzer',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVi 
                          ? 'Phân tích xe hơi bằng AI\nChỉ cần chụp ảnh'
                          : 'Analyze cars with AI\nJust take a photo',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Features Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVi ? 'Tính năng chính' : 'Key Features',
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 16),
                    FeatureCard(
                      icon: Icons.camera_alt,
                      title: isVi ? 'Chụp ảnh xe' : 'Take Car Photo',
                      description: isVi 
                          ? 'Chụp ảnh xe từ camera hoặc chọn từ thư viện'
                          : 'Take a photo of the car or choose from gallery',
                    ),
                    const SizedBox(height: 12),
                    FeatureCard(
                      icon: Icons.analytics,
                      title: isVi ? 'Phân tích AI' : 'AI Analysis',
                      description: isVi 
                          ? 'Phân tích chi tiết về xe bằng công nghệ AI'
                          : 'Detailed car analysis using AI technology',
                    ),
                    const SizedBox(height: 12),
                    FeatureCard(
                      icon: Icons.description,
                      title: isVi ? 'Thông tin chi tiết' : 'Detailed Information',
                      description: isVi 
                          ? 'Nhận thông tin về động cơ, nội thất và tính năng'
                          : 'Get information about engine, interior and features',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Start Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => _openCamera(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        isVi ? 'Bắt đầu phân tích' : 'Start Analysis',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 