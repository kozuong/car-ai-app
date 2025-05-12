import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ResultPage extends StatelessWidget {
  final String imagePath;
  final String carName;
  final String year;
  final String price;
  final String description;
  final String interior;
  final String engine;
  final String features;
  final String langCode;

  const ResultPage({
    super.key,
    required this.imagePath,
    required this.carName,
    required this.year,
    required this.price,
    required this.description,
    required this.interior,
    required this.engine,
    required this.features,
    required this.langCode,
  });

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'[*#]'), '').trim();
  }

  String _extractCleanDescription(String rawDescription) {
    final lines = rawDescription.split('\n');
    final cleanLines = lines.map((line) => _cleanText(line)).where((line) => line.isNotEmpty);
    return cleanLines.join('\n');
  }

  Future<void> _shareResult() async {
    final isVi = langCode == 'vi';
    final message = isVi
        ? '🚗 Thông tin xe:\n\n'
            'Tên xe: $carName\n'
            'Năm sản xuất: $year\n'
            'Giá: $price\n'
            'Động cơ: $engine\n'
            'Nội thất: $interior\n'
            'Tính năng: $features\n'
            'Mô tả: ${_extractCleanDescription(description)}'
        : '🚗 Car Information:\n\n'
            'Car Name: $carName\n'
            'Year: $year\n'
            'Price: $price\n'
            'Engine: $engine\n'
            'Interior: $interior\n'
            'Features: $features\n'
            'Description: ${_extractCleanDescription(description)}';

    final imageFile = XFile(imagePath);
    await Share.shareXFiles([imageFile], text: message);
  }

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    final file = File(imagePath);
    final theme = Theme.of(context);

    if (!file.existsSync()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVi ? 'Không tìm thấy ảnh' : 'Image not found'),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Kết quả phân tích' : 'Analysis Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResult,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section
            Hero(
              tag: 'car_image_$imagePath',
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                ),
                child: file.existsSync()
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: theme.disabledColor,
                        ),
                      ),
              ),
            ),

            // Car Name Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                carName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Info Cards Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (year.isNotEmpty)
                    _buildInfoCard(
                      context,
                      isVi ? 'Năm sản xuất' : 'Year',
                      year,
                      Icons.calendar_today,
                      theme.primaryColor,
                    ),
                  if (price.isNotEmpty)
                    _buildInfoCard(
                      context,
                      isVi ? 'Giá' : 'Price',
                      price,
                      Icons.attach_money,
                      Colors.green,
                    ),
                  if (engine.isNotEmpty)
                    _buildInfoCard(
                      context,
                      isVi ? 'Động cơ' : 'Engine',
                      engine,
                      Icons.settings,
                      Colors.blue,
                    ),
                  if (interior.isNotEmpty)
                    _buildInfoCard(
                      context,
                      isVi ? 'Nội thất' : 'Interior',
                      interior,
                      Icons.weekend,
                      Colors.orange,
                    ),
                  if (features.isNotEmpty)
                    _buildInfoCard(
                      context,
                      isVi ? 'Tính năng' : 'Features',
                      features,
                      Icons.engineering,
                      Colors.purple,
                    ),
                  if (description.isNotEmpty)
                    _buildInfoCard(
                      context,
                      isVi ? 'Mô tả' : 'Description',
                      _extractCleanDescription(description),
                      Icons.description,
                      Colors.teal,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
