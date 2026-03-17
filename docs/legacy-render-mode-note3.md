# Legacy render mode cho Samsung Note 3 / Adreno 3xx

Tài liệu này cung cấp **mẫu code Android + Flutter** để bật chế độ tương thích (legacy) cho thiết bị cũ như Samsung Note 3 (Adreno 3xx), nhằm giảm crash/hang ở GPU driver.

> Mục tiêu: chỉ áp dụng fallback trên máy có rủi ro cao, không ảnh hưởng đa số thiết bị mới.

## 1) Android: detect thiết bị rủi ro + expose qua MethodChannel

Thêm channel mới trong `MainActivity.kt`.

```kotlin
package com.example.rolify

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : AudioServiceActivity() {
    private val COMPAT_CHANNEL = "rolify/compat"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COMPAT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCompatibilityFlags" -> {
                        result.success(
                            mapOf(
                                "isLegacyGpuDevice" to isLegacyGpuDevice(),
                                "isLowRamDevice" to isLowRamDevice(),
                                "sdkInt" to Build.VERSION.SDK_INT,
                                "manufacturer" to Build.MANUFACTURER,
                                "model" to Build.MODEL,
                                "hardware" to Build.HARDWARE
                            )
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isLowRamDevice(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.isLowRamDevice
    }

    private fun isLegacyGpuDevice(): Boolean {
        val model = Build.MODEL.lowercase(Locale.US)
        val device = Build.DEVICE.lowercase(Locale.US)
        val hardware = Build.HARDWARE.lowercase(Locale.US)
        val manufacturer = Build.MANUFACTURER.lowercase(Locale.US)

        // Note 3 phổ biến: SM-N900*, codename hlte
        val isNote3 =
            manufacturer.contains("samsung") &&
            (model.contains("n900") || device.contains("hlte"))

        // Heuristic cho nhóm thiết bị/ROM cũ có nguy cơ cao
        val looksLikeOldQualcomm = hardware.contains("qcom") || hardware.contains("msm")
        val veryOldAndroid = Build.VERSION.SDK_INT <= Build.VERSION_CODES.M // <= Android 6

        return isNote3 || (looksLikeOldQualcomm && veryOldAndroid)
    }
}
```

## 2) Flutter: đọc cờ tương thích ngay lúc khởi động

Tạo service để lấy cờ từ Android:

```dart
import 'dart:io';
import 'package:flutter/services.dart';

class CompatibilityFlags {
  final bool isLegacyGpuDevice;
  final bool isLowRamDevice;

  const CompatibilityFlags({
    required this.isLegacyGpuDevice,
    required this.isLowRamDevice,
  });

  static const _channel = MethodChannel('rolify/compat');

  static Future<CompatibilityFlags> load() async {
    if (!Platform.isAndroid) {
      return const CompatibilityFlags(
        isLegacyGpuDevice: false,
        isLowRamDevice: false,
      );
    }

    final data = await _channel
        .invokeMapMethod<String, dynamic>('getCompatibilityFlags');

    return CompatibilityFlags(
      isLegacyGpuDevice: data?['isLegacyGpuDevice'] == true,
      isLowRamDevice: data?['isLowRamDevice'] == true,
    );
  }
}
```

Trong `main()`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final flags = await CompatibilityFlags.load();
  runApp(MyApp(flags: flags));
}
```

## 3) Áp dụng fallback an toàn trong UI Flutter

### 3.1 Tắt hiệu ứng nặng khi legacy mode bật

```dart
class CompatOptions {
  final bool disableBlur;
  final bool disableHeavyOpacity;
  final FilterQuality imageFilterQuality;

  const CompatOptions({
    required this.disableBlur,
    required this.disableHeavyOpacity,
    required this.imageFilterQuality,
  });

  factory CompatOptions.fromFlags(CompatibilityFlags flags) {
    final legacy = flags.isLegacyGpuDevice || flags.isLowRamDevice;
    return CompatOptions(
      disableBlur: legacy,
      disableHeavyOpacity: legacy,
      imageFilterQuality:
          legacy ? FilterQuality.low : FilterQuality.medium,
    );
  }
}
```

```dart
Widget buildHeader(CompatOptions options) {
  if (options.disableBlur) {
    return Container(color: Colors.black54);
  }

  return ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(color: Colors.black26),
    ),
  );
}
```

### 3.2 Giảm rủi ro ở luồng ảnh

```dart
Image.network(
  imageUrl,
  fit: BoxFit.cover,
  filterQuality: options.imageFilterQuality,
  cacheWidth: options.disableBlur ? 720 : null,
  errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12),
)
```

## 4) Fallback cho Android WebView (nếu app có màn WebView native)

Với device lỗi nặng, bạn có thể tắt hardware acceleration riêng cho WebView:

```kotlin
if (isLegacyGpuDevice()) {
    webView.setLayerType(android.view.View.LAYER_TYPE_SOFTWARE, null)
}
```

Hoặc tắt hardware acceleration theo Activity trong `AndroidManifest.xml` (chỉ cho màn WebView):

```xml
<activity
    android:name=".LegacyWebViewActivity"
    android:hardwareAccelerated="false" />
```

> Cảnh báo: software rendering sẽ giảm hiệu năng; chỉ bật trên nhóm thiết bị bị crash/hang.

## 5) Checklist A/B test nhanh

1. Legacy OFF, chạy luồng UI nặng (blur/opacity/image list).
2. Legacy ON, chạy lại cùng luồng.
3. So sánh số crash (SIGSEGV/libsc-a3xx.so), ANR, jank.
4. Nếu crash giảm rõ rệt, giữ compat mode theo device fingerprint.

## 6) Lưu ý thực tế

- Đây là workaround để né lỗi driver, không phải sửa gốc vendor blob.
- Có thể cần thêm blacklist theo model/ROM cụ thể sau khi thu thập crash log thực tế.
