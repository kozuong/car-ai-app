import 'package:flutter/material.dart';

class CarDetailPage extends StatelessWidget {
  final String carName;
  final String imageUrl;
  final String? power;
  final String? acceleration;
  final String? topSpeed;
  final String? year;
  final String? value;
  final String? production;
  final String? produced;
  final double? rarity;
  final String? description;

  const CarDetailPage({
    super.key,
    required this.carName,
    required this.imageUrl,
    this.power,
    this.acceleration,
    this.topSpeed,
    this.year,
    this.value,
    this.production,
    this.produced,
    this.rarity,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Ảnh xe + nút back/share/favorite
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 64,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.share, color: Colors.black),
                      onPressed: () {},
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.red),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(carName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                    const SizedBox(height: 18),
                    // Thông số kỹ thuật
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SpecItem(value: power ?? '--', label: 'Power', unit: 'hp', color: Colors.blue),
                        _SpecItem(value: acceleration ?? '--', label: '0-100 km/h', unit: 's', color: Colors.indigo),
                        _SpecItem(value: topSpeed ?? '--', label: 'Top speed', unit: 'km/h', color: Colors.lightBlue),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _OverviewRow(label: 'Year', value: year ?? '--'),
                    _OverviewRow(label: 'Value', value: value ?? '--'),
                    _OverviewRow(label: 'Production', value: production ?? '--'),
                    _OverviewRow(label: 'Number produced', value: produced ?? '--'),
                    Row(
                      children: [
                        const Text('Rarity:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: rarity ?? 0.5,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(description ?? 'No description.', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String value, label, unit;
  final Color color;
  const _SpecItem({required this.value, required this.label, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(unit, style: const TextStyle(fontSize: 12, color: Colors.black38)),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label, value;
  const _OverviewRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
} 