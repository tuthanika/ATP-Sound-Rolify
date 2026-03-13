import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'audio.dart';

final colors = [
  Colors.redAccent[100]!,
  Colors.deepOrangeAccent[100]!,
  Colors.amberAccent[100]!,
  Colors.greenAccent[100]!,
  Colors.cyanAccent[100]!,
  Colors.blueAccent[100]!,
  Colors.deepPurpleAccent[100]!,
];

final colorTranslation = {
  'red': Colors.redAccent[100],
  'orange': Colors.deepOrangeAccent[100],
  'amber': Colors.amberAccent[100],
  'green': Colors.greenAccent[100],
  'cyan': Colors.cyanAccent[100],
  'blue': Colors.blueAccent[100],
  'purple': Colors.deepPurpleAccent[100],
};

final colorTranslationReverse = {
  Colors.redAccent[100]: 'red',
  Colors.deepOrangeAccent[100]: 'orange',
  Colors.amberAccent[100]: 'amber',
  Colors.greenAccent[100]: 'green',
  Colors.cyanAccent[100]: 'cyan',
  Colors.blueAccent[100]: 'blue',
  Colors.deepPurpleAccent[100]: 'purple',
};

class Playlist extends Equatable {
  final String name;
  final List<Audio> audios;
  final Color? color;

  const Playlist({
    required this.name,
    required this.audios,
    this.color,
  });

  Playlist.fromJson(Map json)
      : name = json['name']?.toString() ?? 'New Playlist',
        audios = _parseAudiosSafely(json['audios']),
        color = json['color'] != null ? colorTranslation[json['color']?.toString()] : null;

  static List<Audio> _parseAudiosSafely(dynamic audiosJson) {
    if (audiosJson == null) return <Audio>[];
    try {
      final List decodedList;
      if (audiosJson is String) {
        if (audiosJson.trim().isEmpty) return <Audio>[];
        decodedList = jsonDecode(audiosJson) as List;
      } else if (audiosJson is List) {
        decodedList = audiosJson;
      } else {
        return <Audio>[];
      }
      return decodedList
          .map((audio) => Audio.fromJson(audio as Map))
          .toList();
    } catch (e) {
      debugPrint('Error parsing audios in playlist: $e');
      return <Audio>[];
    }
  }

  toJson() => {
        'name': name,
        'audios': jsonEncode(audios.map((audio) => audio.toJson()).toList()),
        'color': colorTranslationReverse[color]
      };

  Playlist copyFrom({
    String? name,
    List<Audio>? audios,
    Color? color,
  }) =>
      Playlist(
          name: name ?? this.name,
          audios: audios ?? List.from(this.audios),
          color: color ?? this.color);

  @override
  List<Object> get props => [name, audios.length];
}
