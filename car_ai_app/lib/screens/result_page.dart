import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../config/constants.dart';
import '../widgets/car_info_card.dart';
import '../widgets/performance_stats.dart';

class ResultPage extends StatelessWidget {
  final String imagePath;
  final String carName;
  final String year;
  final String price;
  final String power;
  final String acceleration;
  final String topSpeed;
  final String engine;
  final String interior;
  final String features;
  final String description;
  final String langCode;

  const ResultPage({
    super.key,
    required this.imagePath,
    required this.carName,
    required this.year,
    required this.price,
    required this.power,
    required this.acceleration,
    required this.topSpeed,
    required this.engine,
    required this.interior,
    this.features = '',
    required this.description,
    required this.langCode,
  });

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .trim();
  }

  String _extractCleanDescription(String text) {
    final cleanText = _cleanText(text);
    if (cleanText.isEmpty) {
      return langCode == 'vi' 
          ? 'Không có thông tin chi tiết.'
          : 'No detailed information available.';
    }
    return cleanText;
  }

  Future<void> _shareResult(BuildContext context) async {
    try {
      final isVi = langCode == 'vi';
      final file = XFile(imagePath);
      
      final text = isVi
          ? '''
🚗 Thông tin xe:
${carName.isNotEmpty ? '• Tên: $carName' : ''}
${year.isNotEmpty ? '• Năm: $year' : ''}
${price.isNotEmpty ? '• Giá: $price' : ''}
${power.isNotEmpty ? '• Công suất: $power' : ''}
${acceleration.isNotEmpty ? '• Tăng tốc 0-100: $acceleration' : ''}
${topSpeed.isNotEmpty ? '• Tốc độ tối đa: $topSpeed' : ''}
${engine.isNotEmpty ? '\n🔧 Động cơ:\n${_cleanText(engine)}' : ''}
${interior.isNotEmpty ? '\n🛋 Nội thất:\n${_cleanText(interior)}' : ''}
${description.isNotEmpty ? '\n📝 Mô tả:\n${_cleanText(description)}' : ''}'''
          : '''
🚗 Car Information:
${carName.isNotEmpty ? '• Name: $carName' : ''}
${year.isNotEmpty ? '• Year: $year' : ''}
${price.isNotEmpty ? '• Price: $price' : ''}
${power.isNotEmpty ? '• Power: $power' : ''}
${acceleration.isNotEmpty ? '• Acceleration 0-60: $acceleration' : ''}
${topSpeed.isNotEmpty ? '• Top Speed: $topSpeed' : ''}
${engine.isNotEmpty ? '\n🔧 Engine:\n${_cleanText(engine)}' : ''}
${interior.isNotEmpty ? '\n🛋 Interior:\n${_cleanText(interior)}' : ''}
${description.isNotEmpty ? '\n📝 Description:\n${_cleanText(description)}' : ''}''';

      await Share.shareXFiles(
        [file],
        text: text,
        subject: carName,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              langCode == 'vi'
                  ? 'Không thể chia sẻ kết quả: ${e.toString()}'
                  : 'Could not share result: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    final theme = Theme.of(context);
    final imageFile = File(imagePath);

    if (!imageFile.existsSync()) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isVi ? 'Kết quả' : 'Result'),
        ),
        body: Center(
          child: Icon(
            Icons.broken_image,
            size: 64,
            color: theme.primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Kết quả' : 'Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResult(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Car Image
            Stack(
              children: [
                Image.file(
                  imageFile,
                  height: AppConstants.imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (year.isNotEmpty || price.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              [
                                if (year.isNotEmpty) year,
                                if (price.isNotEmpty) price,
                              ].join(' • '),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Performance Stats
            if (power.isNotEmpty || acceleration.isNotEmpty || topSpeed.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: PerformanceStats(
                  power: power,
                  acceleration: acceleration,
                  topSpeed: topSpeed,
                  langCode: langCode,
                ),
              ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview
                  Text(
                    isVi ? 'Tổng quan' : 'Overview',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _extractCleanDescription(description),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                  ),

                  // Engine Specifications
                  if (engine.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    CarInfoCard(
                      icon: Icons.engineering,
                      title: isVi ? 'Thông số động cơ' : 'Engine Specifications',
                      content: _cleanText(engine),
                      langCode: langCode,
                    ),
                  ],

                  // Interior & Features
                  if (interior.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    CarInfoCard(
                      icon: Icons.event_seat,
                      title: isVi ? 'Nội thất & Tính năng' : 'Interior & Features',
                      content: _cleanText(interior),
                      langCode: langCode,
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 