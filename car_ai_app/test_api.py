import requests
import time
import os
from pathlib import Path

def test_api():
    try:
        print("Starting API test...")
        
        # Get the absolute path to test_car.jpg in the Flutter_app directory
        current_dir = Path(__file__).parent.absolute()
        root_dir = current_dir.parent.absolute()  # This is Flutter_app directory
        image_path = root_dir / 'test_car.jpg'
        
        print(f"Current directory: {current_dir}")
        print(f"Root directory: {root_dir}")
        print(f"Looking for image at: {image_path}")
        print(f"File exists: {image_path.exists()}")
        
        if not image_path.exists():
            print("Error: Image file not found!")
            return
            
        print(f"File size: {os.path.getsize(image_path) / 1024:.2f}KB")

        # Prepare request
        url = 'http://127.0.0.1:5000/analyze_car'  # Using localhost instead of 10.0.2.2
        print(f"\nOpening image file...")
        files = {'image': open(image_path, 'rb')}
        data = {'lang': 'en'}

        print("\nSending request to API...")
        print(f"URL: {url}")
        
        # Send request and measure time
        start_time = time.time()
        try:
            print("Making API request...")
            response = requests.post(url, files=files, data=data, timeout=10)
            end_time = time.time()
            
            # Print results
            print(f"\nResponse Time: {(end_time - start_time) * 1000:.2f}ms")
            print(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print("\nResponse Data:")
                print(f"Car Name: {data.get('car_name', '')}")
                print(f"Year: {data.get('year', '')}")
                print(f"Price: {data.get('price', '')}")
                print(f"Power: {data.get('power', '')}")
                print(f"Acceleration: {data.get('acceleration', '')}")
                print(f"Top Speed: {data.get('top_speed', '')}")
                print(f"Engine: {data.get('engine', '')}")
                print(f"Interior: {data.get('interior', '')}")
                print(f"Features: {data.get('features', '')}")
                print(f"Description: {data.get('description', '')}")
            else:
                print("\nError Response:")
                print(f"Status Code: {response.status_code}")
                print(f"Response Text: {response.text}")
                
        except requests.exceptions.Timeout:
            end_time = time.time()
            print(f"\nTimeout after {(end_time - start_time) * 1000:.2f}ms")
            print("API request timed out after 10 seconds")
        except requests.exceptions.ConnectionError:
            end_time = time.time()
            print(f"\nConnection error after {(end_time - start_time) * 1000:.2f}ms")
            print("Could not connect to API server. Make sure the server is running and accessible")
        except Exception as e:
            end_time = time.time()
            print(f"\nError occurred after {(end_time - start_time) * 1000:.2f}ms")
            print(f"Error: {str(e)}")
        finally:
            files['image'].close()
    except Exception as e:
        print(f"Critical error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    test_api() 