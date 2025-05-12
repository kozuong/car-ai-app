import 'dart:io';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/storage_service.dart';
import '../models/car_model.dart';
import 'result_page.dart';

class HistoryPage extends StatelessWidget {
  final String langCode;

  const HistoryPage({super.key, required this.langCode});

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Lịch sử' : 'History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final storage = StorageService();
              await storage.clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppConstants.messages[langCode]!['clearHistory']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<CarModel>>(
        future: StorageService().getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          final cars = snapshot.data ?? [];

          if (cars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.messages[langCode]!['noHistory']!,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: car.imagePath != null && car.imagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(car.imagePath),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.car_rental),
                        ),
                  title: Text(
                    car.carName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (car.year.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(car.year),
                      ],
                      if (car.price.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          car.price,
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    if (car.imagePath == null || car.imagePath.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppConstants.messages[langCode]!['noImage']!,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultPage(
                          imagePath: car.imagePath,
                          carName: car.carName,
                          year: car.year,
                          price: car.price,
                          power: car.power,
                          acceleration: car.acceleration,
                          topSpeed: car.topSpeed,
                          engine: car.engine,
                          interior: car.interior,
                          features: car.features,
                          description: car.description,
                          langCode: langCode,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 