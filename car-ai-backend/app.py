from flask import Flask, request, jsonify
import base64
import os
import re
import io
import requests
from PIL import Image
from dotenv import load_dotenv
import logging
from datetime import datetime
import json

# Configure logging with more detail
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load API key từ biến môi trường
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
logger.info(f"Loaded API key: {api_key[:5]}...{api_key[-5:] if api_key else 'None'}")

app = Flask(__name__)

HISTORY_FILE = "history.json"
COLLECTION_FILE = "collections.json"

# Resize ảnh và mã hóa base64
def encode_image(image_file, max_size=512):
    try:
        # Đọc và kiểm tra kích thước file
        image_file.seek(0, os.SEEK_END)
        original_size = image_file.tell()
        image_file.seek(0)
        logger.info(f"Original file size: {original_size / 1024:.2f}KB")

        if original_size > 10 * 1024 * 1024:  # 10MB limit
            raise ValueError("File size exceeds 10MB limit")

        # Đọc ảnh
        image = Image.open(image_file)
        logger.info(f"Original image size: {image.size}, mode: {image.mode}")

        # Chuyển đổi sang RGB nếu cần
        if image.mode != 'RGB':
            logger.info(f"Converting image from {image.mode} to RGB")
            image = image.convert('RGB')

        # Tính toán kích thước mới
        if max(image.size) > max_size:
            ratio = max_size / max(image.size)
            new_size = tuple(int(dim * ratio) for dim in image.size)
            logger.info(f"Resizing image from {image.size} to {new_size}")
            image = image.resize(new_size, Image.Resampling.LANCZOS)

        # Nén ảnh với chất lượng tự động điều chỉnh
        quality = 85
        buffer = io.BytesIO()
        while True:
            buffer.seek(0)
            buffer.truncate()
            image.save(buffer, format='JPEG', quality=quality, optimize=True)
            size = buffer.tell()
            logger.info(f"Compressed size with quality {quality}: {size / 1024:.2f}KB")
            
            if size <= 800 * 1024 or quality <= 30:  # Giới hạn 800KB
                break
                
            quality -= 10

        buffer.seek(0)
        base64_data = base64.b64encode(buffer.read()).decode("utf-8")
        logger.info(f"Final base64 size: {len(base64_data) / 1024:.2f}KB")
        return base64_data

    except Exception as e:
        logger.error(f"Error encoding image: {str(e)}")
        raise

def research_missing_info(car_name, missing_fields, lang='en'):
    """Research missing information using Gemini API"""
    try:
        # Always request all three sections for consistency and require real/estimated engine info
        prompt = f'''
Research and provide accurate information about the car model: {car_name}.
Return the result in exactly three clear sections, in this order:

Overview:
(2-3 sentences about the car's overall characteristics)

Engine Details:
- Engine type: (e.g. V8, V6, inline-4, hybrid, electric, etc.)
- Displacement: (in liters or cc)
- Power: (in hp or kW)
- Induction: (turbocharged, supercharged, naturally aspirated, etc.)
- Transmission: (manual, automatic, dual-clutch, number of speeds)
- Drivetrain: (RWD, AWD, FWD, etc.)
If you cannot find the exact engine for this model/year, provide the most likely or typical engine for this car line, and clearly state it is an estimate. Do not return "No information available". Always provide the most likely real-world information, or a well-informed estimate.

Interior & Features:
- Seating: (material and configuration)
- Dashboard: (key features)
- Technology: (main tech features)
- Key Features: (list 3-4 standout features)

Do not return "No information available". Always provide the most likely real-world information, or a well-informed estimate for each section.
'''

        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }

        headers = {
            "Content-Type": "application/json"
        }

        response = requests.post(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent",
            params={"key": api_key},
            headers=headers,
            json=payload,
            timeout=20
        )
        
        response.raise_for_status()
        result = response.json()
        content = result["candidates"][0]["content"]["parts"][0]["text"]
        
        # Parse researched information
        researched_fields = extract_fields(content)
        logger.info(f"Successfully researched missing information for {car_name}")
        return researched_fields
        
    except Exception as e:
        logger.error(f"Error researching information: {str(e)}")
        return None

def research_engine_info(car_name):
    """Research engine information when not available"""
    try:
        prompt = f"""Research and provide detailed engine specifications for {car_name}. Include the following information in Vietnamese:

1. Thông số kỹ thuật động cơ:
- Loại động cơ: (V6, V8, inline-4, hybrid, electric, etc.)
- Dung tích xi-lanh: (cc hoặc L)
- Công suất: (hp hoặc kW)
- Mô-men xoắn: (Nm)
- Hệ thống nạp khí: (turbo, supercharger, naturally aspirated)
- Hệ thống nhiên liệu: (direct injection, port injection, etc.)
- Tiêu chuẩn khí thải: (Euro 6, Euro 5, etc.)

2. Hệ thống truyền động:
- Loại hộp số: (số tự động, số sàn, số ly hợp kép)
- Số cấp số: (6 cấp, 8 cấp, etc.)
- Hệ dẫn động: (FWD, RWD, AWD)
- Tỷ số truyền: (nếu có)

3. Hiệu suất:
- Thời gian tăng tốc 0-100 km/h
- Vận tốc tối đa
- Mức tiêu thụ nhiên liệu: (l/100km)
- Dung tích bình nhiên liệu: (L)

4. Công nghệ đặc biệt:
- Hệ thống tiết kiệm nhiên liệu: (start/stop, cylinder deactivation, etc.)
- Công nghệ tăng áp: (twin-turbo, bi-turbo, etc.)
- Hệ thống làm mát: (liquid cooling, etc.)

Nếu không tìm thấy thông tin chính xác, hãy cung cấp thông tin ước tính dựa trên phiên bản tương tự hoặc cùng dòng xe. Không trả về "Không có thông tin". Luôn cung cấp thông tin thực tế hoặc ước tính có căn cứ."""

        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }

        headers = {
            "Content-Type": "application/json"
        }

        response = requests.post(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent",
            params={"key": api_key},
            headers=headers,
            json=payload,
            timeout=20
        )
        
        response.raise_for_status()
        result = response.json()
        engine_info = result["candidates"][0]["content"]["parts"][0]["text"]
        
        # Format the response into clear sections
        sections = engine_info.split('\n\n')
        formatted_info = []
        
        for section in sections:
            if section.strip():
                # Add bullet points if not present
                if not section.strip().startswith('-'):
                    lines = section.split('\n')
                    formatted_lines = ['- ' + line.strip() for line in lines if line.strip()]
                    formatted_info.extend(formatted_lines)
                else:
                    formatted_info.append(section.strip())
        
        return '\n'.join(formatted_info) if formatted_info else "- Không có thông tin chi tiết về động cơ."
    except Exception as e:
        logger.error(f"Error researching engine info: {str(e)}")
        return "- Không có thông tin chi tiết về động cơ."

# Trích xuất các trường từ phản hồi
def extract_fields(text):
    try:
        fields = {
            "brand": "", "model": "", "year": "",
            "price": "", "power": "", "acceleration": "",
            "top_speed": "", "description": "",
            "engine_detail": "", "interior": ""
        }

        current_section = None
        sections = {
            "overview": [],
            "engine": [],
            "interior": []
        }
        
        lines = text.strip().splitlines()
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            # Check for section headers
            if line.endswith(':'):
                header = line[:-1].lower()
                if "overview" in header:
                    current_section = "overview"
                elif "engine" in header:
                    current_section = "engine"
                elif "interior" in header or "features" in header:
                    current_section = "interior"
                continue
                
            # Handle performance metrics
            if "power:" in line.lower():
                fields["power"] = line.split(":", 1)[1].strip()
            elif "0-60" in line.lower() or "0-100" in line.lower():
                fields["acceleration"] = line.split(":", 1)[1].strip()
            elif "top speed" in line.lower():
                fields["top_speed"] = line.split(":", 1)[1].strip()
            elif ":" in line and not line.startswith('-'):
                try:
                    key, value = line.split(":", 1)
                    key = key.strip().lower()
                    value = value.strip()
                    
                    if "brand" in key:
                        fields["brand"] = value
                    elif "model" in key:
                        fields["model"] = value
                    elif "year" in key:
                        fields["year"] = value
                    elif "price" in key:
                        fields["price"] = value
                except:
                    continue
            elif current_section:
                if line.startswith('-'):
                    sections[current_section].append(line.strip('- '))
                else:
                    sections[current_section].append(line)

        # Construct final fields
        fields["description"] = " ".join(sections["overview"]).strip()
        fields["engine_detail"] = "\n".join(f"• {spec}" for spec in sections["engine"])
        fields["interior"] = "\n".join(f"• {feature}" for feature in sections["interior"])

        car_name = f"{fields['brand']} {fields['model']}".strip()
        if not car_name:
            car_name = "Unknown Car"

        return (
            car_name, 
            fields["year"] or "N/A", 
            fields["price"] or "N/A",
            fields["power"] or "N/A", 
            fields["acceleration"] or "N/A", 
            fields["top_speed"] or "N/A",
            fields["engine_detail"] or "No engine details available.",
            fields["interior"] or "No interior details available.",
            fields["description"] or "No detailed description available."
        )
    except Exception as e:
        logger.error(f"Error in extract_fields: {str(e)}")
        return (
            "Unknown Car", "N/A", "N/A",
            "N/A", "N/A", "N/A",
            "No engine details available.",
            "No interior details available.",
            "Unable to extract detailed information from the image."
        )

def translate_to_vietnamese(content):
    """Translate content to Vietnamese"""
    try:
        # Split content into sections
        sections = content.split('\n\n')
        translated_sections = []
        
        for section in sections:
            if not section.strip():
                continue
                
            # Check if section is already in Vietnamese
            if any(vn_word in section.lower() for vn_word in ['động cơ', 'nội thất', 'tính năng', 'công suất', 'tốc độ', 'xe', 'hệ thống', 'trang bị']):
                translated_sections.append(section)
                continue
                
            prompt = f"""Translate the following car information to Vietnamese. Keep all numbers, units and technical specifications as is:

{section}

Translation rules:
1. Keep all numbers and units (hp, km/h, etc) unchanged
2. Keep car brand names unchanged
3. Translate all descriptions and features to Vietnamese
4. Keep technical terms in their common Vietnamese form (e.g. 'turbo' -> 'tăng áp', 'hybrid' -> 'hybrid')
5. Maintain bullet points and formatting
6. Translate all English text to Vietnamese, including descriptions and features
7. Keep any Vietnamese text as is"""

            payload = {
                "contents": [{
                    "parts": [{"text": prompt}]
                }]
            }

            response = requests.post(
                "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent",
                params={"key": api_key},
                json=payload,
                timeout=20
            )
            
            response.raise_for_status()
            result = response.json()
            translated = result["candidates"][0]["content"]["parts"][0]["text"]
            translated_sections.append(translated)
        
        return '\n\n'.join(translated_sections)
    except Exception as e:
        logger.error(f"Error translating content: {str(e)}")
        return content  # Return original content if translation fails

def translate_to_english(content):
    """Translate content to English"""
    try:
        # Split content into sections
        sections = content.split('\n\n')
        translated_sections = []
        
        for section in sections:
            if not section.strip():
                continue
                
            # Check if section is already in English
            if not any(vn_word in section.lower() for vn_word in ['động cơ', 'nội thất', 'tính năng', 'công suất', 'tốc độ']):
                translated_sections.append(section)
                continue
                
            prompt = f"""Translate the following car information to English. Keep all numbers, units and technical specifications as is:

{section}

Translation rules:
1. Keep all numbers and units (hp, km/h, etc) unchanged
2. Keep car brand names unchanged
3. Translate all descriptions and features to English
4. Keep technical terms in their common English form
5. Maintain bullet points and formatting"""

            payload = {
                "contents": [{
                    "parts": [{"text": prompt}]
                }]
            }

            response = requests.post(
                "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent",
                params={"key": api_key},
                json=payload,
                timeout=20
            )
            
            response.raise_for_status()
            result = response.json()
            translated = result["candidates"][0]["content"]["parts"][0]["text"]
            translated_sections.append(translated)
        
        return '\n\n'.join(translated_sections)
    except Exception as e:
        logger.error(f"Error translating content: {str(e)}")
        return content  # Return original content if translation fails

def save_to_history(car_data):
    try:
        if os.path.exists(HISTORY_FILE):
            with open(HISTORY_FILE, "r", encoding="utf-8") as f:
                history = json.load(f)
        else:
            history = []
        history.insert(0, car_data)  # Thêm mới lên đầu
        with open(HISTORY_FILE, "w", encoding="utf-8") as f:
            json.dump(history, f, ensure_ascii=False, indent=2)
    except Exception as e:
        logger.error(f"Error saving to history: {str(e)}")

def save_to_collection(car_data, collection_name="Favorites"):
    try:
        if os.path.exists(COLLECTION_FILE):
            with open(COLLECTION_FILE, "r", encoding="utf-8") as f:
                collections = json.load(f)
        else:
            collections = {}
        if collection_name not in collections:
            collections[collection_name] = []
        # Kiểm tra trùng lặp
        if not any(car.get('car_name') == car_data.get('car_name') and car.get('brand') == car_data.get('brand') for car in collections[collection_name]):
            collections[collection_name].insert(0, car_data)
        with open(COLLECTION_FILE, "w", encoding="utf-8") as f:
            json.dump(collections, f, ensure_ascii=False, indent=2)
    except Exception as e:
        logger.error(f"Error saving to collection: {str(e)}")

@app.route('/analyze_car', methods=['POST'])
def analyze_car():
    try:
        logger.info("Received analyze_car request")
        if not api_key:
            logger.error("API key is not configured")
            return jsonify({"error": "API key is not configured"}), 500

        logger.debug(f"Using API key: {api_key[:5]}...{api_key[-5:]}")

        if 'image' not in request.files:
            logger.error("No image file provided")
            return jsonify({"error": "No image file provided"}), 400
            
        image_file = request.files['image']
        logger.info(f"Received image file: {image_file.filename}")
        
        if not image_file.filename:
            logger.error("No image file selected")
            return jsonify({"error": "No image file selected"}), 400
            
        lang = request.form.get('lang', 'vi')
        logger.info(f"Language: {lang}")
        
        start_time = datetime.now()
        
        try:
            base64_image = encode_image(image_file, max_size=512)
            logger.info("Image encoded successfully")
        except Exception as e:
            logger.error(f"Error encoding image: {str(e)}")
            error_msg = {
                'vi': "Lỗi xử lý ảnh. Vui lòng thử lại với ảnh khác.",
                'en': "Image processing failed. Please try with a different image."
            }
            return jsonify({"error": error_msg[lang]}), 400

        session = requests.Session()
        retries = 3
        backoff_factor = 0.5
        retry_strategy = requests.adapters.Retry(
            total=retries,
            backoff_factor=backoff_factor,
            status_forcelist=[429, 500, 502, 503, 504],
        )
        session.mount("https://", requests.adapters.HTTPAdapter(max_retries=retry_strategy))

        try:
            # Use English prompt for initial analysis
            prompt = """Analyze this car image and provide the following information in this EXACT format:
Brand: (manufacturer name)
Model: (model name)
Year: (specific year or year range)
Price: (price range in USD)
Performance:
- Power: (exact HP number or range)
- 0-60 mph: (exact seconds)
- Top Speed: (exact km/h)

Description:
Overview:
(Write 2-3 sentences about the car's overall characteristics)

Engine Details:
- Configuration: (engine type and layout)
- Displacement: (in liters)
- Turbo/Supercharging: (if applicable)
- Transmission: (type and speeds)

Interior & Features:
- Seating: (material and configuration)
- Dashboard: (key features)
- Technology: (main tech features)
- Key Features: (list 3-4 standout features)

Note: Please maintain the exact format with proper line breaks and section headers."""

            payload = {
                "contents": [{
                    "parts": [
                        {"text": prompt},
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": base64_image
                            }
                        }
                    ]
                }]
            }

            headers = {
                "Content-Type": "application/json"
            }

            logger.info("Sending request to Gemini API")
            response = session.post(
                "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent",
                params={"key": api_key},
                headers=headers,
                json=payload,
                timeout=(3, 15)
            )
            
            if response.status_code != 200:
                logger.error(f"API Error: {response.status_code} - {response.text}")
                error_msg = {
                    'vi': "Không thể phân tích ảnh. Vui lòng thử lại với ảnh khác.",
                    'en': "Unable to analyze image. Please try with a different image."
                }
                return jsonify({"error": error_msg[lang]}), 400
            
            result = response.json()
            logger.info("Received response from Gemini API")
            
            if 'error' in result:
                logger.error(f"Gemini API error: {result['error']}")
                error_msg = {
                    'vi': "Không thể phân tích ảnh. Vui lòng thử lại với ảnh khác.",
                    'en': "Unable to analyze image. Please try with a different image."
                }
                return jsonify({"error": error_msg[lang]}), 400
                
            if 'candidates' not in result or not result['candidates']:
                logger.error("No candidates in Gemini API response")
                error_msg = {
                    'vi': "Không thể phân tích ảnh. Vui lòng thử lại với ảnh khác.",
                    'en': "Unable to analyze image. Please try with a different image."
                }
                return jsonify({"error": error_msg[lang]}), 400
                
            content = result["candidates"][0]["content"]["parts"][0]["text"]
            logger.info("Extracting fields from response")
            
            try:
                car_name, year, price, power, acceleration, top_speed, engine_detail, interior, description = extract_fields(content)
                logger.info(f"Successfully extracted fields for car: {car_name}")
            except Exception as e:
                logger.error(f"Error extracting fields: {str(e)}")
                error_msg = {
                    'vi': "Lỗi xử lý thông tin xe. Vui lòng thử lại.",
                    'en': "Error processing car information. Please try again."
                }
                return jsonify({"error": error_msg[lang]}), 400
            
            # Always research engine details first if missing or incomplete
            if not engine_detail or engine_detail == "No engine details available." or "needs the engine specifications" in engine_detail:
                try:
                    logger.info("Researching engine details")
                    engine_detail = research_engine_info(car_name)
                    if not engine_detail or engine_detail == "No engine details available.":
                        # Try one more time with a different prompt
                        engine_detail = research_missing_info(car_name, ['engine'], lang)[6]  # Get engine details from research
                except Exception as e:
                    logger.error(f"Error researching engine info: {str(e)}")
                    pass

            # Validate essential fields
            missing_fields = []
            if not power or power == "N/A":
                missing_fields.append('power')
            if not acceleration or acceleration == "N/A":
                missing_fields.append('acceleration')
            if not top_speed or top_speed == "N/A":
                missing_fields.append('top_speed')
            
            if missing_fields:
                try:
                    logger.info(f"Researching missing fields: {missing_fields}")
                    researched = research_missing_info(car_name, missing_fields, lang)
                    if researched:
                        _, _, _, r_power, r_acc, r_speed, r_engine, r_interior, r_desc = researched
                        power = r_power if 'power' in missing_fields else power
                        acceleration = r_acc if 'acceleration' in missing_fields else acceleration
                        top_speed = r_speed if 'top_speed' in missing_fields else top_speed
                        engine_detail = r_engine if not engine_detail or engine_detail == "No engine details available." else engine_detail
                        interior = r_interior if not interior or interior == "No interior details available." else interior
                        description = r_desc if not description or description == "No detailed description available." else description
                        logger.info("Successfully researched missing information")
                except Exception as e:
                    logger.error(f"Error researching missing info: {str(e)}")
                    pass

            # Translate content based on language preference
            if lang == 'vi':
                try:
                    logger.info("Translating content to Vietnamese")
                    # Translate price description if it contains "depending on"
                    if "depending on" in price.lower():
                        price = price.replace("depending on year and trim level", "tùy thuộc vào phiên bản và năm sản xuất")
                        price = price.replace("depending on", "tùy thuộc")
                    
                    # Translate description
                    if description:
                        description = translate_to_vietnamese(description)
                    
                    # Translate interior
                    if interior:
                        interior = translate_to_vietnamese(interior)
                    
                    # Translate engine details
                    if engine_detail:
                        engine_detail = translate_to_vietnamese(engine_detail)
                    
                    # Translate features
                    if response_data["features"]:
                        response_data["features"] = [translate_to_vietnamese(feature) for feature in response_data["features"]]
                except Exception as e:
                    logger.error(f"Error translating content: {str(e)}")
                    pass
            else:  # English
                try:
                    logger.info("Translating content to English")
                    # Translate price description if it contains Vietnamese
                    if any(vn_word in price.lower() for vn_word in ['tùy thuộc', 'phiên bản', 'năm sản xuất']):
                        price = price.replace("tùy thuộc vào phiên bản và năm sản xuất", "depending on year and trim level")
                        price = price.replace("tùy thuộc", "depending on")
                    
                    # Translate description to English if it's in Vietnamese
                    if description and any(vn_word in description.lower() for vn_word in ['động cơ', 'nội thất', 'tính năng', 'công suất', 'tốc độ', 'xe', 'hệ thống', 'trang bị']):
                        description = translate_to_english(description)
                    
                    # Translate interior to English if it's in Vietnamese
                    if interior and any(vn_word in interior.lower() for vn_word in ['động cơ', 'nội thất', 'tính năng', 'công suất', 'tốc độ', 'xe', 'hệ thống', 'trang bị']):
                        interior = translate_to_english(interior)
                    
                    # Translate engine details to English if it's in Vietnamese
                    if engine_detail and any(vn_word in engine_detail.lower() for vn_word in ['động cơ', 'nội thất', 'tính năng', 'công suất', 'tốc độ', 'xe', 'hệ thống', 'trang bị']):
                        engine_detail = translate_to_english(engine_detail)
                    
                    # Translate features to English if they're in Vietnamese
                    if response_data["features"]:
                        response_data["features"] = [translate_to_english(feature) if any(vn_word in feature.lower() for vn_word in ['động cơ', 'nội thất', 'tính năng', 'công suất', 'tốc độ', 'xe', 'hệ thống', 'trang bị']) else feature for feature in response_data["features"]]
                except Exception as e:
                    logger.error(f"Error translating content: {str(e)}")
                    pass

            end_time = datetime.now()
            processing_time = (end_time - start_time).total_seconds()
            
            response_data = {
                "car_name": car_name,
                "brand": car_name.split()[0] if car_name else "",  # Extract brand from car name
                "year": year,
                "price": price,
                "power": power,
                "acceleration": acceleration,
                "top_speed": top_speed,
                "description": description,
                "engineDetail": engine_detail,
                "interior": interior,
                "features": [],  # Will be populated from interior section
                "processing_time": processing_time,
                "timestamp": datetime.now().isoformat()  # Add timestamp for history
            }
            
            # Extract features from interior section
            if response_data["interior"]:
                features = [line.strip('- ').strip() for line in response_data["interior"].split('\n') if line.strip().startswith('-')]
                response_data["features"] = features
            
            # Lưu vào lịch sử
            save_to_history(response_data)
            # Lưu vào collection mặc định
            save_to_collection(response_data)
            logger.info(f"Successfully processed request in {processing_time} seconds")
            return jsonify(response_data)
            
        except requests.exceptions.Timeout:
            logger.error("Request timeout")
            error_msg = {
                'vi': "Quá thời gian phân tích. Vui lòng thử lại với ảnh khác (ảnh rõ nét hơn hoặc góc chụp khác).",
                'en': "Analysis timeout. Please try again with a different image (clearer image or different angle)."
            }
            return jsonify({"error": error_msg[lang]}), 504
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Request error: {str(e)}")
            error_msg = {
                'vi': "Lỗi kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại sau.",
                'en': "Server connection error. Please check your network and try again later."
            }
            return jsonify({"error": error_msg[lang]}), 500
            
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        error_msg = {
            'vi': "Đã xảy ra lỗi không mong muốn. Vui lòng thử lại sau.",
            'en': "An unexpected error occurred. Please try again later."
        }
        return jsonify({"error": error_msg[lang]}), 500

@app.route('/test_api', methods=['GET'])
def test_api():
    try:
        if not api_key:
            return jsonify({"error": "API key is not configured"}), 500

        logger.info(f"Using API key: {api_key}")
        prompt = "Hello, this is a test message."
        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }

        headers = {
            "Content-Type": "application/json"
        }

        # Sử dụng API endpoint từ AI Studio
        api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
        logger.info(f"Calling API URL: {api_url}")
        
        response = requests.post(
            api_url,
            params={"key": api_key},
            headers=headers,
            json=payload,
            timeout=10
        )
        
        if response.status_code != 200:
            logger.error(f"API Error: {response.status_code} - {response.text}")
            return jsonify({"error": f"API Error: {response.status_code} - {response.text}"}), 500
        
        result = response.json()
        logger.info(f"API Response: {result}")
        
        if 'error' in result:
            return jsonify({"error": result['error']}), 500
            
        if 'candidates' not in result or not result['candidates']:
            return jsonify({"error": "No response from API"}), 500
            
        return jsonify({
            "status": "success",
            "response": result["candidates"][0]["content"]["parts"][0]["text"]
        })
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error: {str(e)}")
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/brands', methods=['GET'])
def get_brands():
    brands = [
        {"name": "Toyota", "logo_url": "https://example.com/toyota.png"},
        {"name": "Honda", "logo_url": "https://example.com/honda.png"},
        {"name": "BMW", "logo_url": "https://example.com/bmw.png"},
        {"name": "Mercedes", "logo_url": "https://example.com/mercedes.png"},
        {"name": "Audi", "logo_url": "https://example.com/audi.png"},
        # Thêm các thương hiệu khác nếu muốn
    ]
    return jsonify(brands)

@app.route('/history', methods=['GET'])
def get_history():
    try:
        if os.path.exists(HISTORY_FILE):
            with open(HISTORY_FILE, "r", encoding="utf-8") as f:
                history = json.load(f)
        else:
            history = []
        return jsonify(history)
    except Exception as e:
        logger.error(f"Error reading history: {str(e)}")
        return jsonify([]), 500

@app.route('/collection', methods=['GET'])
def get_collection():
    collection_name = request.args.get('name', 'Favorites')
    try:
        if os.path.exists(COLLECTION_FILE):
            with open(COLLECTION_FILE, "r", encoding="utf-8") as f:
                collections = json.load(f)
            return jsonify(collections.get(collection_name, []))
        else:
            return jsonify([])
    except Exception as e:
        logger.error(f"Error reading collection: {str(e)}")
        return jsonify([]), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
