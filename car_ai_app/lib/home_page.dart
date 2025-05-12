import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
  }

  Future<void> _changeLanguage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('language'); // Xoá ngôn ngữ đã chọn
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
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVi 
                          ? 'Phân tích xe hơi bằng AI\nChỉ cần chụp ảnh'
                          : 'Analyze cars with AI\nJust take a photo',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      context,
                      Icons.camera_alt,
                      isVi ? 'Chụp ảnh xe' : 'Take Car Photo',
                      isVi 
                          ? 'Chụp ảnh xe từ camera hoặc chọn từ thư viện'
                          : 'Take a photo of the car or choose from gallery',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context,
                      Icons.analytics,
                      isVi ? 'Phân tích AI' : 'AI Analysis',
                      isVi 
                          ? 'Phân tích chi tiết về xe bằng công nghệ AI'
                          : 'Detailed car analysis using AI technology',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context,
                      Icons.description,
                      isVi ? 'Thông tin chi tiết' : 'Detailed Information',
                      isVi 
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraPage(langCode: langCode),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        isVi ? 'Bắt đầu phân tích' : 'Start Analysis',
                        style: const TextStyle(
                          fontSize: 18,
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

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
