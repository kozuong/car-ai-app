# Car AI App

Ứng dụng nhận dạng và phân tích xe hơi thông qua hình ảnh sử dụng Flutter và Firebase.

## Tính năng chính

- Nhận dạng xe hơi qua hình ảnh
- Phân tích thông số kỹ thuật
- Lưu trữ lịch sử và bộ sưu tập
- Hỗ trợ đa ngôn ngữ
- Tích hợp Firebase

## Yêu cầu hệ thống

- Flutter SDK (phiên bản mới nhất)
- Dart SDK (phiên bản mới nhất)
- Firebase CLI
- Python 3.8+ (cho backend)
- Git

## Cài đặt

1. Clone repository:
```bash
git clone https://github.com/your-username/car-ai-app.git
cd car-ai-app
```

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Cấu hình Firebase:
- Tạo project trên Firebase Console
- Thêm ứng dụng Android/iOS
- Tải và thêm file cấu hình:
  - Android: `google-services.json` vào `android/app/`
  - iOS: `GoogleService-Info.plist` vào `ios/Runner/`

4. Cấu hình backend:
```bash
cd car-ai-backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# hoặc
.\venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

## Chạy ứng dụng

1. Backend:
```bash
cd car-ai-backend
python app.py
```

2. Flutter app:
```bash
flutter run
```

## Cấu trúc dự án

```
car_ai_app/
├── lib/
│   ├── screens/      # Các màn hình
│   ├── models/       # Model dữ liệu
│   ├── services/     # Services
│   ├── widgets/      # Widgets tái sử dụng
│   ├── utils/        # Tiện ích
│   └── config/       # Cấu hình
├── assets/          # Tài nguyên
└── test/           # Unit tests

car-ai-backend/
├── app.py          # Backend API
└── requirements.txt # Python dependencies
```

## Đóng góp

Mọi đóng góp đều được hoan nghênh! Vui lòng tạo issue hoặc pull request.

## Giấy phép

MIT License
