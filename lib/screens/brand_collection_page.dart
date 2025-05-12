import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/car_brand.dart';
import 'car_detail_page.dart';
import 'package:shimmer/shimmer.dart';

class BrandCollectionPage extends StatefulWidget {
  const BrandCollectionPage({super.key});

  @override
  State<BrandCollectionPage> createState() => _BrandCollectionPageState();
}

class _BrandCollectionPageState extends State<BrandCollectionPage> {
  List<CarBrand> brands = [];
  bool isLoading = true;
  // Demo: danh sách các hãng đã nhận diện (index)
  Set<int> identifiedIndexes = {0, 1, 2, 3, 4};

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

  void toggleIdentify(int index) {
    setState(() {
      if (identifiedIndexes.contains(index)) {
        identifiedIndexes.remove(index);
      } else {
        identifiedIndexes.add(index);
      }
    });
  }

  void openCarDetail(CarBrand brand) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailPage(
          carName: brand.name,
          imageUrl: brand.logoUrl,
          // Các trường khác có thể truyền dữ liệu mẫu hoặc null
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Identify Car', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.black)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: GridView.builder(
                  itemCount: 9,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, i) => Container(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      const Text('Identified brands', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                      const Spacer(),
                      Text(
                        '${identifiedIndexes.length}/${brands.length}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: brands.length,
                    itemBuilder: (context, i) {
                      final isIdentified = identifiedIndexes.contains(i);
                      return GestureDetector(
                        onTap: () {
                          toggleIdentify(i);
                          openCarDetail(brands[i]);
                        },
                        child: Stack(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isIdentified ? 1.0 : 0.4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Image.network(
                                      brands[i].logoUrl,
                                      height: 54,
                                      width: 54,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image_not_supported, size: 40),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Tick nếu đã nhận diện
                            if (isIdentified)
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFD1D1D6)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Photo Library', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
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