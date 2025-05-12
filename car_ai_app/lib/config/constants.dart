class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://192.168.1.74:5000';
  static const String analyzeEndpoint = '/analyze_car';
  static const int apiTimeoutSeconds = 15;
  static const int streamTimeoutSeconds = 5;
  static const int maxRetries = 2;
  static const int retryDelaySeconds = 1;
  static const double maxImageSizeMB = 10.0;  // Unified max file size constant

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double iconSize = 24.0;
  static const double imageHeight = 250.0;

  // Storage Keys
  static const String historyKey = 'car_history';
  static const String languageKey = 'language';
  static const String defaultLanguage = 'vi';

  // Messages
  static const Map<String, Map<String, String>> messages = {
    'vi': {
      'analyzing': 'Đang phân tích ảnh...\nQuá trình này có thể mất vài giây',
      'error': 'Có lỗi xảy ra',
      'timeout': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.',
      'fileTooLarge': 'Hình ảnh quá lớn (tối đa 10MB)',
      'invalidResponse': 'Không thể phân tích hình ảnh',
      'noImage': 'Không tìm thấy hình ảnh',
      'share': 'Chia sẻ kết quả',
      'history': 'Lịch sử',
      'clearHistory': 'Xóa lịch sử',
      'noHistory': 'Chưa có lịch sử phân tích',
      'retry': 'Thử lại',
      'cancel': 'Hủy',
      'cancel_analysis': 'Hủy phân tích',
      'please_wait': 'Vui lòng đợi trong giây lát',
    },
    'en': {
      'analyzing': 'Analyzing image...\nThis may take a few seconds',
      'error': 'An error occurred',
      'timeout': 'Could not connect to server. Please check your network connection and try again.',
      'fileTooLarge': 'Image is too large (max 10MB)',
      'invalidResponse': 'Could not analyze image',
      'noImage': 'No image found',
      'share': 'Share result',
      'history': 'History',
      'clearHistory': 'Clear history',
      'noHistory': 'No analysis history yet',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'cancel_analysis': 'Cancel analysis',
      'please_wait': 'Please wait a moment',
    },
  };

  static const Map<String, Map<String, String>> errorMessages = {
    'vi': {
      'file_too_large': 'Kích thước ảnh quá lớn (tối đa 10MB). Vui lòng chọn ảnh khác.',
      'timeout': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.',
      'connection_error': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      'server_error': 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
      'api_error': 'Có lỗi xảy ra',
      'invalid_response': 'Không thể nhận dạng xe trong ảnh. Vui lòng thử lại với ảnh khác.',
      'unknown_error': 'Có lỗi không xác định xảy ra. Vui lòng thử lại.',
      'retry_failed': 'Đã thử lại nhiều lần không thành công. Vui lòng thử lại sau.',
    },
    'en': {
      'file_too_large': 'Image size is too large (max 10MB). Please choose another image.',
      'timeout': 'Could not connect to server. Please check your network connection and try again.',
      'connection_error': 'Could not connect to server. Please check your network connection.',
      'server_error': 'Server is experiencing issues. Please try again later.',
      'api_error': 'An error occurred',
      'invalid_response': 'Could not recognize the car in the image. Please try again with a different image.',
      'unknown_error': 'An unknown error occurred. Please try again.',
      'retry_failed': 'Multiple retry attempts failed. Please try again later.',
    },
  };
} 