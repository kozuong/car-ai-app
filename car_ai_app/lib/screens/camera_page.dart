import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/car_model.dart';
import 'result_page.dart';

class CameraPage extends StatefulWidget {
  final String langCode;

  const CameraPage({super.key, required this.langCode});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _errorMessage;
  XFile? _selectedImage;
  bool _isCancelled = false;
  int _retryCount = 0;
  static const int maxRetries = 2;

  @override
  void dispose() {
    _isCancelled = true;
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return;

      setState(() {
        _selectedImage = image;
        _errorMessage = null;
        _isLoading = true;
        _isCancelled = false;
        _retryCount = 0;
      });

      await _analyzeImage(image);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> _analyzeImage(XFile image) async {
    if (_isCancelled) return;

    try {
      final api = ApiService();
      final car = await api.analyzeCarImage(File(image.path), widget.langCode);

      if (_isCancelled || !mounted) return;

      final storage = StorageService();
      await storage.saveCarToHistory(car);

      if (_isCancelled || !mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });

      if (!mounted) return;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            imagePath: image.path,
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
            langCode: widget.langCode,
          ),
        ),
      );
    } catch (e) {
      if (_isCancelled || !mounted) return;
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    if (!mounted || _isCancelled) return;
    
    setState(() {
      _errorMessage = error;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: AppConstants.messages[widget.langCode]!['retry']!,
          textColor: Colors.white,
          onPressed: () {
            if (_selectedImage != null) {
              _retryAnalysis();
            }
          },
        ),
      ),
    );
  }

  Future<void> _retryAnalysis() async {
    if (_selectedImage == null || _retryCount >= maxRetries) {
      _handleError(widget.langCode == 'vi'
          ? 'Đã thử lại nhiều lần không thành công. Vui lòng chọn ảnh khác.'
          : 'Multiple retry attempts failed. Please try another image.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isCancelled = false;
      _retryCount++;
    });
    
    await _analyzeImage(_selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    final isVi = widget.langCode == 'vi';
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) {
          setState(() {
            _isCancelled = true;
            _isLoading = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isVi ? 'Chụp ảnh xe' : 'Take Car Photo'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_isLoading) {
                setState(() {
                  _isCancelled = true;
                  _isLoading = false;
                });
              }
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedImage!.path),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isVi ? 'Chọn ảnh từ:' : 'Choose image from:',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(isVi ? 'Camera' : 'Camera'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: Text(isVi ? 'Thư viện' : 'Gallery'),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          isVi 
                            ? 'Đang phân tích ảnh...\nVui lòng đợi trong giây lát'
                            : 'Analyzing image...\nPlease wait a moment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isCancelled = true;
                            _isLoading = false;
                          });
                        },
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.white,
                        ),
                        label: Text(
                          isVi ? 'Hủy phân tích' : 'Cancel analysis',
                          style: theme.textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }
} 