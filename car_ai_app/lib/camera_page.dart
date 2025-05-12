import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'result_page.dart';
import 'history_page.dart';

class CameraPage extends StatefulWidget {
  final String langCode;
  const CameraPage({super.key, required this.langCode});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _imageFile;
  bool _loading = false;
  final picker = ImagePicker();

  @override
  void dispose() {
    _imageFile?.delete();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );
    await _processPickedImage(picked);
  }

  Future<void> _pickFromGallery() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );
    await _processPickedImage(picked);
  }

  Future<void> _processPickedImage(XFile? picked) async {
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _loading = true;
    });

    final result = await _sendToApi(_imageFile!);
    if (!mounted) return;

    if (result['car_name'] == 'API error' || result['car_name'] == 'Exception') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result[widget.langCode] ?? 'Error')),
      );
      setState(() {
        _imageFile = null;
        _loading = false;
      });
      return;
    }

    final tempImagePath = _imageFile!.path;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          imagePath: tempImagePath,
          carName: result['car_name'] ?? 'Unknown',
          year: result['year'] ?? '',
          price: result['price'] ?? '',
          description: result[widget.langCode] ?? '',
          interior: result['interior'] ?? '',
          engine: result['engine'] ?? '',
          features: result['features'] ?? '',
          langCode: widget.langCode,
        ),
      ),
    );

    // Delete the temporary image file after returning from result page
    if (mounted) {
      setState(() {
        _imageFile = null;
        _loading = false;
      });
      try {
        await File(tempImagePath).delete();
      } catch (e) {
        debugPrint('Error deleting temporary image: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _sendToApi(File imageFile) async {
    final uri = Uri.parse('http://192.168.1.74:5000/analyze_car');  // Thay IP này bằng IP thực của máy tính
    
    try {
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) { // Giảm giới hạn xuống 5MB
        return {
          "car_name": "File too large",
          "year": "",
          "price": "",
          "interior": "",
          "engine": "",
          "vi": "⚠️ File ảnh quá lớn (>5MB). Vui lòng chọn ảnh nhỏ hơn.",
          "en": "⚠️ Image file too large (>5MB). Please select a smaller image."
        };
      }

      final request = http.MultipartRequest('POST', uri)
        ..fields['lang'] = widget.langCode
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null || data['car_name'] == null) {
          return {
            "car_name": "Invalid response",
            "year": "",
            "price": "",
            "interior": "",
            "engine": "",
            "vi": "⚠️ Không nhận diện được xe trong ảnh",
            "en": "⚠️ Could not recognize car in image"
          };
        }

        await _saveToHistory({
          "imagePath": imageFile.path,
          "car_name": data['car_name'],
          "year": data['year'] ?? "",
          "price": data['price'] ?? "",
          "interior": data['interior'] ?? "",
          "engine": data['engine'] ?? "",
          "vi": data['vi'] ?? "",
          "en": data['en'] ?? "",
        });

        return data;
      } else {
        return {
          "car_name": "API error",
          "year": "",
          "price": "",
          "interior": "",
          "engine": "",
          "vi": "⚠️ Lỗi máy chủ: ${response.statusCode}",
          "en": "⚠️ Server error: ${response.statusCode}"
        };
      }
    } on SocketException {
      return {
        "car_name": "Connection Error",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": '🚫 Không thể kết nối đến máy chủ. Vui lòng kiểm tra:\n1. Kết nối mạng\n2. Địa chỉ IP máy chủ\n3. Cửa sổ terminal đang chạy Flask',
        "en": '🚫 Cannot connect to server. Please check:\n1. Network connection\n2. Server IP address\n3. Flask terminal window'
      };
    } on TimeoutException {
      return {
        "car_name": "Timeout",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": '⏱️ Quá thời gian chờ phản hồi (10 giây).\nVui lòng kiểm tra:\n1. Kết nối mạng\n2. Địa chỉ IP máy chủ\n3. Cửa sổ terminal đang chạy Flask',
        "en": '⏱️ Response timeout (10 seconds).\nPlease check:\n1. Network connection\n2. Server IP address\n3. Flask terminal window'
      };
    } catch (e) {
      return {
        "car_name": "Error",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": '❌ Lỗi: $e',
        "en": '❌ Error: $e'
      };
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveToHistory(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    history.add(jsonEncode(item));
    await prefs.setStringList('history', history);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.langCode == 'vi' ? '✅ Đã lưu vào lịch sử' : '✅ Saved to history',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.langCode == 'vi' ? '📝 Chưa có lịch sử' : '📝 No history yet',
          ),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryPage(
          history: history,
          langCode: widget.langCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = widget.langCode == 'vi';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Phân tích xe' : 'Car Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview or Image
          if (_imageFile != null)
            Center(
              child: Image.file(
                _imageFile!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: theme.primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isVi ? 'Chụp ảnh hoặc chọn từ thư viện' : 'Take a photo or choose from gallery',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

          // Loading Overlay
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Action Buttons
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'camera',
                  onPressed: _loading ? null : _pickFromCamera,
                  child: const Icon(Icons.camera_alt),
                ),
                FloatingActionButton(
                  heroTag: 'gallery',
                  onPressed: _loading ? null : _pickFromGallery,
                  child: const Icon(Icons.photo_library),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
