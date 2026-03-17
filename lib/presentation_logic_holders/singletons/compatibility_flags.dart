import 'dart:io';

import 'package:flutter/services.dart';

class CompatibilityFlags {
  const CompatibilityFlags({
    required this.isLegacyGpuDevice,
    required this.isLowRamDevice,
    required this.forceLegacyFromDefine,
    required this.isArmV7Device,
  });

  final bool isLegacyGpuDevice;
  final bool isLowRamDevice;
  final bool forceLegacyFromDefine;
  final bool isArmV7Device;

  bool get shouldUseLegacyRendering =>
      forceLegacyFromDefine || isLegacyGpuDevice;

  static const _channel = MethodChannel('rolify/compat');
  static const _forceLegacyFromDefine =
      String.fromEnvironment('ROLIFY_FORCE_LEGACY_RENDER', defaultValue: 'false');

  static Future<CompatibilityFlags> load() async {
    final forceLegacy = _forceLegacyFromDefine.toLowerCase() == 'true';

    if (!Platform.isAndroid) {
      return CompatibilityFlags(
        isLegacyGpuDevice: false,
        isLowRamDevice: false,
        forceLegacyFromDefine: forceLegacy,
        isArmV7Device: false,
      );
    }

    try {
      final data = await _channel.invokeMapMethod<String, dynamic>(
        'getCompatibilityFlags',
      );

      return CompatibilityFlags(
        isLegacyGpuDevice: data?['isLegacyGpuDevice'] == true,
        isLowRamDevice: data?['isLowRamDevice'] == true,
        forceLegacyFromDefine: forceLegacy,
        isArmV7Device: data?['isArmV7Device'] == true,
      );
    } catch (_) {
      return CompatibilityFlags(
        isLegacyGpuDevice: false,
        isLowRamDevice: false,
        forceLegacyFromDefine: forceLegacy,
        isArmV7Device: false,
      );
    }
  }
}
