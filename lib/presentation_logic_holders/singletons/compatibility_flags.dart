import 'dart:io';

import 'package:flutter/services.dart';

class CompatibilityFlags {
  const CompatibilityFlags({
    required this.isLegacyGpuDevice,
    required this.isLowRamDevice,
    required this.forceLegacyFromDefine,
  });

  final bool isLegacyGpuDevice;
  final bool isLowRamDevice;
  final bool forceLegacyFromDefine;

  bool get shouldUseLegacyRendering =>
      forceLegacyFromDefine || isLegacyGpuDevice || isLowRamDevice;

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
      );
    } catch (_) {
      return CompatibilityFlags(
        isLegacyGpuDevice: false,
        isLowRamDevice: false,
        forceLegacyFromDefine: forceLegacy,
      );
    }
  }
}
