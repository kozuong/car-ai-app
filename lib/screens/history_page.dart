import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/car_brand.dart';
import 'car_detail_page.dart';
import 'package:shimmer/shimmer.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Dữ liệu mẫu: mỗi xe có name, year, brand, imageUrl
  List<Map<String, String>> history = [
    {
      'name': 'Ford Raptor',
      'year': '2022',
      'brand': 'Ford',
      'imageUrl': 'https://cdn.motor1.com/images/mgl/0ANk6/s1/2022-ford-f-150-raptor.jpg'
    },
    {
      'name': 'Lagonda Rapide',
      'year': '1961',
      'brand': 'Lagonda',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/2/2b/Lagonda_Rapide_1961.jpg'
    },
    {
      'name': 'BMW X5',
      'year': '2021',
      'brand': 'BMW',
      'imageUrl': 'https://cdn.bmwblog.com/wp-content/uploads/2021/06/2021-bmw-x5-xdrive45e-01.jpg'
    },
    {
      'name': 'Toyota Camry',
      'year': '2020',
      'brand': 'Toyota',
      'imageUrl': 'https://toyota.com.vn//uploads/images/Camry/Exterior/1.png'
    },
    {
      'name': 'Ford Mustang',
      'year': '2019',
      'brand': 'Ford',
      'imageUrl': 'https://www.ford.com/is/image/content/dam/brand_ford/en_us/brand/cars/mustang/2022/collections/dm/22_FRD_MST_wdmp_200505_00199.tif?croppathe=1_3x2&wid=900'
    },
  ];
  String? selectedBrand;
  List<CarBrand> brands = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBrands();
  }

  Future<void> fetchBrands() async {
    const url = 'https://raw.githubusercontent.com/ducanhnguyen/car-brand-data/main/car_brands.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          brands = data.map((e) => CarBrand.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load brands');
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String? getLogoUrl(String brandName) {
    final brand = brands.firstWhere(
      (b) => b.name.toLowerCase() == brandName.toLowerCase(),
      orElse: () => CarBrand(name: '', logoUrl: ''),
    );
    return brand.logoUrl.isNotEmpty ? brand.logoUrl : null;
  }

  void removeItem(int index) {
    setState(() {
      history.removeAt(index);
    });
  }

  void clearHistory() {
    setState(() {
      history.clear();
    });
  }

  void openCarDetail(Map<String, String> car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailPage(
          carName: car['name'] ?? '',
          imageUrl: car['imageUrl'] ?? '',
          // Các trường khác có thể truyền dữ liệu mẫu hoặc null
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách các hãng xe duy nhất trong lịch sử
    final brandNames = history.map((e) => e['brand']!).toSet().toList();
    // Đếm số lượng xe mỗi hãng
    final Map<String, int> brandCounts = {};
    for (var item in history) {
      brandCounts[item['brand']!] = (brandCounts[item['brand']!] ?? 0) + 1;
    }
    // Lọc lịch sử theo hãng nếu có chọn tag
    final filteredHistory = selectedBrand == null
        ? history
        : history.where((e) => e['brand'] == selectedBrand).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (history.isNotEmpty)
            TextButton(
              onPressed: clearHistory,
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: isLoading
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListView.builder(
                  itemCount: 4,
                  itemBuilder: (context, i) => Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag filter hãng xe
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả', style: TextStyle(fontWeight: FontWeight.bold)),
                        selected: selectedBrand == null,
                        selectedColor: const Color(0xFF2196F3),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selectedBrand == null ? Colors.white : Colors.black,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: selectedBrand == null ? const Color(0xFF2196F3) : Colors.grey[300]!),
                        ),
                        onSelected: (_) => setState(() => selectedBrand = null),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      const SizedBox(width: 8),
                      ...brandNames.map((brand) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$brand ${brandCounts[brand] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          selected: selectedBrand == brand,
                          selectedColor: const Color(0xFF2196F3),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedBrand == brand ? Colors.white : Colors.black,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: selectedBrand == brand ? const Color(0xFF2196F3) : Colors.grey[300]!),
                          ),
                          onSelected: (_) => setState(() => selectedBrand = brand),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      )),
                    ],
                  ),
                ),
                // Danh sách lịch sử xe
                Expanded(
                  child: filteredHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 80, color: Color(0xFF2196F3)),
                              const SizedBox(height: 18),
                              const Text(
                                'Chưa có lịch sử phân tích',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, i) {
                            final item = filteredHistory[i];
                            final logoUrl = getLogoUrl(item['brand']!);
                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => openCarDetail(item),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          color: Colors.white,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Ảnh xe
                                              item['imageUrl'] != null
                                                  ? Image.network(
                                                      item['imageUrl']!,
                                                      height: 160,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Container(
                                                            height: 160,
                                                            color: Colors.grey[200],
                                                            child: const Icon(Icons.image, size: 60),
                                                          ),
                                                    )
                                                  : Container(
                                                      height: 160,
                                                      color: Colors.grey[200],
                                                      child: const Icon(Icons.image, size: 60),
                                                    ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // Logo hãng xe
                                                    if (logoUrl != null && logoUrl.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(right: 10),
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(16),
                                                          child: Image.network(
                                                            logoUrl,
                                                            width: 32,
                                                            height: 32,
                                                            fit: BoxFit.contain,
                                                            errorBuilder: (context, error, stackTrace) =>
                                                                const Icon(Icons.image_not_supported, size: 24),
                                                          ),
                                                        ),
                                                      ),
                                                    // Tên xe
                                                    Expanded(
                                                      child: Text(
                                                        item['name']!,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                    // Năm
                                                    Text(
                                                      item['year']!,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Nút xoá nổi trên ảnh
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () => removeItem(
                                              history.indexOf(item)),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 