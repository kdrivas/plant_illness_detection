# Plant Health Guardian 🌱

A cross-platform Flutter mobile application for plant illness detection, sensor monitoring, and AI-powered plant care assistance.

## Features

- **🔬 Disease Detection** - AI-powered plant health analysis using computer vision
- **📊 Sensor Monitoring** - Real-time sensor data with charts (pH, EC, Temperature, Humidity, UV, VOC)
- **🗓️ Planting Calendar** - Location-based seasonal planting guide
- **💬 AI Chat Assistant** - Gemini/OpenAI powered plant care assistant with sensor context
- **🔔 Smart Alerts** - Sustained reading alerts for out-of-range conditions
- **🌾 Harvest Tracking** - Day counting with manual confirmation

## Supported Plants

- 🥬 Lettuce
- 🍓 Strawberry
- 🫐 Blueberry

## Getting Started

### Prerequisites

- Flutter SDK >= 3.2.0
- Dart >= 3.2.0
- iOS Simulator or Android Emulator (or physical device)

### Installation

1. **Clone the repository**
   ```bash
   cd plant_illness_detection
   ```

2. **Generate platform files**
   ```bash
   flutter create .
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Configure platform permissions** (see below)

6. **Run the app**
   ```bash
   flutter run
   ```

## Platform Configuration

### Android

Edit `android/app/src/main/AndroidManifest.xml` and add these permissions inside the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- For image picker -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

Also add these queries inside `<manifest>`:
```xml
<queries>
    <intent>
        <action android:name="android.media.action.IMAGE_CAPTURE" />
    </intent>
</queries>
```

### iOS

Edit `ios/Runner/Info.plist` and add these entries:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to capture plant photos for disease detection</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is needed to select plant photos for disease detection</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to determine planting seasons for your region</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Location is used to determine planting seasons for your region</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Environment Variables

Create a `.env` file in the root directory:

```env
# API Configuration
API_BASE_URL=https://your-api-server.com
SENSOR_API_URL=https://your-api-server.com/api/sensors
DETECTION_API_URL=https://your-api-server.com/api/detection

# LLM Configuration
GEMINI_API_KEY=your_gemini_api_key
OPENAI_API_KEY=your_openai_api_key
LLM_PROVIDER=gemini

# Sensor Configuration
SENSOR_POLLING_INTERVAL=60
SUSTAINED_READING_THRESHOLD=3
DEFAULT_CHART_HOURS=24
```

## Architecture

```
lib/
├── core/
│   ├── constants/     # API URLs, enums, config
│   ├── theme/         # Colors, themes
│   ├── router/        # GoRouter navigation
│   └── widgets/       # Reusable UI components
├── features/
│   ├── home/          # Dashboard screen
│   ├── calendar/      # Planting calendar
│   ├── detection/     # Disease detection
│   ├── sensors/       # Sensor monitoring
│   └── chat/          # AI assistant
├── models/            # Data models
├── providers/         # Riverpod state management
├── services/          # API services
└── main.dart          # App entry point
```

## Key Dependencies

- **State Management**: flutter_riverpod
- **Navigation**: go_router
- **Charts**: fl_chart
- **Location**: geolocator, geocoding
- **Animations**: flutter_animate
- **HTTP**: http
- **Environment**: flutter_dotenv
- **Notifications**: flutter_local_notifications

## API Integration

### Sensor Data Endpoint
```
GET /api/sensors/{block_id}
GET /api/sensors/{block_id}/history?hours={1|6|24}
```

### Disease Detection Endpoint
```
POST /api/detection/analyze
Body: multipart/form-data
  - image: File
  - plant_type: string
```

### Alert Evaluation Endpoint
```
POST /api/alerts/evaluate
Body: JSON (BlockSensorData)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is licensed under the MIT License.

---

Built with 💚 Flutter
