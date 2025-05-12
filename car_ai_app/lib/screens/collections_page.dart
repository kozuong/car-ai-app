import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/car_model.dart';
import '../services/storage_service.dart';

class CollectionsPage extends StatelessWidget {
  final String langCode;

  const CollectionsPage({super.key, required this.langCode});

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Bộ sưu tập' : 'Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement add collection
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCollectionItem(
            context,
            icon: Icons.star,
            title: isVi ? 'Yêu thích' : 'Favorites',
            count: '2 cars',
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildCollectionItem(
            context,
            icon: Icons.history,
            title: isVi ? 'Xe cổ điển' : 'Retro cars',
            count: '2 cars',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildCollectionItem(
            context,
            icon: Icons.diamond,
            title: isVi ? 'Xe sang' : 'Luxury cars',
            count: '1 car',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          count,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to collection details
        },
      ),
    );
  }
} 