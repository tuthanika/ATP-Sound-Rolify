import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';

enum LocalAudioSource { assets, file }

class Audio extends Equatable {
  final String name, path, image;
  final LocalAudioSource audioSource;
  final LoopMode loopMode;
  final double volume;

  const Audio({
    required this.name,
    required this.path,
    this.image = 'assets/images/tavern.jpg',
    this.audioSource = LocalAudioSource.assets,
    this.loopMode = LoopMode.one,
    this.volume = 0.5,
  });

  Audio.fromJson(Map json)
      : name = json['name']?.toString() ?? removeFileExtension(json['path']?.toString()),
        path = json['path']?.toString() ?? '',
        image = json['image']?.toString() ?? 'assets/images/tavern.jpg',
        audioSource = json['audio_source'] == 'assets'
            ? LocalAudioSource.assets
            : LocalAudioSource.file,
        loopMode = json['loop_mode'] == 'off' ? LoopMode.off : LoopMode.one,
        volume = json['volume'] != null ? (json['volume'] as num).toDouble() : 0.5;

  toJson() => {
        'name': name,
        'path': path,
        'image': image,
        'audio_source':
            audioSource == LocalAudioSource.assets ? 'assets' : 'file',
        'loop_mode': loopMode == LoopMode.off ? 'off' : 'one',
        'volume': volume,
      };

  Audio copyFrom({
    String? name,
    String? path,
    String? image,
    LocalAudioSource? audioSource,
    LoopMode? loopMode,
    double? volume,
  }) =>
      Audio(
        name: name ?? this.name,
        path: path ?? this.path,
        image: image ?? this.image,
        audioSource: audioSource ?? this.audioSource,
        loopMode: loopMode ?? this.loopMode,
        volume: volume ?? this.volume,
      );

  @override
  List<Object> get props => [path];
}

String removeFileExtension(String? path) {
  if (path == null || path.isEmpty) return 'Unknown';
  final audioExtensions = [
    'mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac', 'wma', 'opus'
  ];
  final fileName = path.split('/').last.split('\\').last;
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex > 0) {
    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    if (audioExtensions.contains(ext)) {
      return fileName.substring(0, dotIndex).replaceAll('_', ' ');
    }
  }
  return fileName.replaceAll('_', ' ');
}
