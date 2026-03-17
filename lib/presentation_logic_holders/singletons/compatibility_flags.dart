import 'dart:io';

import 'package:flutter/services.dart';

class CompatibilityFlags {
  const CompatibilityFlags({
    required this.isLegacyGpuDevice,
    required this.isLowRamDevice,
  });

  final bool isLegacyGpuDevice;
  final bool isLowRamDevice;

  bool get shouldUseLegacyRendering => isLegacyGpuDevice || isLowRamDevice;

  static const _channel = MethodChannel('rolify/compat');

  static Future<CompatibilityFlags> load() async {
    if (!Platform.isAndroid) {
      return const CompatibilityFlags(
        isLegacyGpuDevice: false,
        isLowRamDevice: false,
      );
    }

    try {
      final data = await _channel.invokeMapMethod<String, dynamic>(
        'getCompatibilityFlags',
      );

      return CompatibilityFlags(
        isLegacyGpuDevice: data?['isLegacyGpuDevice'] == true,
        isLowRamDevice: data?['isLowRamDevice'] == true,
      );
    } catch (_) {
      return const CompatibilityFlags(
        isLegacyGpuDevice: false,
        isLowRamDevice: false,
      );
    }
  }
}
