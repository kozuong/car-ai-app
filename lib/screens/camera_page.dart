import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool isLoading = false;

  void _simulateScan() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => isLoading = false);
    // TODO: Chuyển sang trang kết quả hoặc chi tiết xe
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: const Text('Chụp ảnh xe', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.camera_alt, size: 90, color: Color(0xFF2196F3)),
              const SizedBox(height: 24),
              const Text('Chọn ảnh từ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: _simulateScan,
                  ),
                  const SizedBox(width: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: _simulateScan,
                  ),
                ],
              ),
              const Spacer(flex: 2),
            ],
          ),
          // Overlay hướng dẫn
          if (!isLoading)
            Positioned(
              left: 0,
              right: 0,
              top: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Phân tích xe hơi bằng AI\nChỉ cần chụp ảnh hoặc chọn từ thư viện để bắt đầu!',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2196F3)),
                    SizedBox(height: 18),
                    Text('Đang nhận diện xe...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 