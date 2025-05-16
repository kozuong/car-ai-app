import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'result_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import '../config/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/error_handler.dart';
import '../services/storage_service.dart';
import '../models/car_model.dart';

class CameraPage extends StatefulWidget {
  final String langCode;
  const CameraPage({super.key, required this.langCode});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _getImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      
      // Kiểm tra kết nối mạng
      if (!await ErrorHandler.checkInternetConnection()) {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, 'Không có kết nối mạng. Vui lòng kiểm tra lại.');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Gửi 2 request: 1 cho tiếng Anh, 1 cho tiếng Việt
        final resultEn = await _analyzeImageWithLang(image.path, 'en');
        final resultVi = await _analyzeImageWithLang(image.path, 'vi');
        if (!mounted) return;

        if (resultEn['car_name'] == 'API error' || resultEn['car_name'] == 'Exception') {
          ErrorHandler.showErrorSnackBar(context, resultEn[widget.langCode] ?? 'Error');
          return;
        }

        // Lưu vào lịch sử
        try {
          final carModel = CarModel(
            imagePath: image.path,
            carName: resultEn['car_name'] ?? '',
            brand: resultEn['brand'] ?? '',
            year: resultEn['year'] ?? '',
            price: resultEn['price'] ?? '',
            power: resultEn['power'] ?? '',
            acceleration: resultEn['acceleration'] ?? '',
            topSpeed: resultEn['top_speed'] ?? '',
            engine: resultEn['engineDetail'] ?? '',
            interior: resultEn['interior'] ?? '',
            features: resultEn['features'] != null ? (resultEn['features'] as List).map((e) => e.toString()).toList() : [],
            description: resultEn['description'] ?? '',
            descriptionEn: resultEn['description'] ?? '',
            descriptionVi: resultVi['description'] ?? '',
            engineDetailEn: resultEn['engineDetail'] ?? '',
            engineDetailVi: resultVi['engineDetail'] ?? '',
            interiorEn: resultEn['interior'] ?? '',
            interiorVi: resultVi['interior'] ?? '',
          );

          // Kiểm tra dữ liệu trước khi lưu
          if (carModel.carName.isEmpty) {
            throw Exception('Tên xe không được để trống');
          }

          // Lưu vào lịch sử
          await StorageService().saveCarToHistory(carModel);
          
          // Đảm bảo collection 'Favorites' tồn tại trước khi lưu
          try {
            await StorageService().addCollection('Favorites');
            await StorageService().saveCarToCollection(carModel, 'Favorites');
          } catch (e) {
            print('Error saving to collection: $e');
          }
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.langCode == 'vi' 
                  ? '✅ Đã lưu vào lịch sử và bộ sưu tập'
                  : '✅ Saved to history and collection'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Chuyển đến trang kết quả và quay về trang chủ
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(
                imagePath: image.path,
                carName: resultEn['car_name'] ?? '',
                brand: resultEn['brand'] ?? '',
                year: resultEn['year'] ?? '',
                price: resultEn['price'] ?? '',
                power: resultEn['power'] ?? '',
                acceleration: resultEn['acceleration'] ?? '',
                topSpeed: resultEn['top_speed'] ?? '',
                description: widget.langCode == 'vi' ? resultVi['description'] : resultEn['description'],
                features: resultEn['features'] != null ? List<String>.from(resultEn['features']) : [],
                engineDetail: widget.langCode == 'vi' ? resultVi['engineDetail'] : resultEn['engineDetail'],
                interior: widget.langCode == 'vi' ? resultVi['interior'] : resultEn['interior'],
              ),
            ),
          );
          
          // Quay về trang chủ và chuyển đến tab lịch sử
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          if (context.mounted) {
            HomePage.switchToHistory(context);
          }
        } catch (e) {
          if (!mounted) return;
          ErrorHandler.showErrorSnackBar(
            context, 
            widget.langCode == 'vi'
              ? '❌ Không thể lưu vào lịch sử: $e'
              : '❌ Failed to save to history: $e'
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Không thể lấy ảnh. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeImageWithLang(String imagePath, String lang) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.analyzeEndpoint}');
    final file = File(imagePath);
    
    try {
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
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
        ..fields['lang'] = lang
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));

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
    }
  }

  Future<void> _checkPermissionAndGetImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        _getImage(source);
      } else {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, 'Cần quyền truy cập camera để sử dụng tính năng này');
      }
    } else {
      _getImage(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = widget.langCode == 'vi';
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 80,
                color: Color(0xFF2196F3),
              ),
              const SizedBox(height: 24),
              Text(
                isVi ? 'Chụp ảnh xe' : 'Take Car Photo',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isVi 
                  ? 'Đặt xe vào khung hình và chụp ảnh rõ nét'
                  : 'Place the car in frame and take a clear photo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _checkPermissionAndGetImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(isVi ? 'Máy ảnh' : 'Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _checkPermissionAndGetImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(isVi ? 'Thư viện' : 'Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
} 