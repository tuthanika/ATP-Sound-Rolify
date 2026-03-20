import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

const basePath = 'assets/icons';

class IconTemplate extends StatelessWidget {
  final Color? color;
  final String path;

  const IconTemplate(this.path, {Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      '$basePath/$path',
      color: color,
    );
  }
}

class MyIcons {
  static Widget about({Color? color}) =>
      IconTemplate('about.svg', color: color);
  static Widget add({Color? color}) => IconTemplate('add.svg', color: color);
  static Widget back({Color? color}) => IconTemplate('back.svg', color: color);
  static Widget close({Color? color}) => IconTemplate(
        'close.svg',
        color: color,
      );
  static Widget delete({Color? color}) => IconTemplate('delete.svg', color: color);
  static Widget done({Color? color}) => IconTemplate('done.svg', color: color);
  static Widget edit({Color? color}) => IconTemplate('edit.svg', color: color);
  static Widget list({Color? color}) => IconTemplate('list.svg', color: color);
  static Widget loop({Color? color}) => IconTemplate(
        'loop.svg',
        color: color,
      );
  static Widget love({Color? color}) => IconTemplate('love.svg', color: color);
  static Widget pause({Color? color}) => IconTemplate('pause.svg', color: color);
  static Widget pauseBig({Color? color}) =>
      IconTemplate('pause_big.svg', color: color);
  static Widget play({Color? color}) => IconTemplate(
        'play.svg',
        color: color,
      );
  static Widget playBig({Color? color}) => IconTemplate(
        'play_big.svg',
        color: color,
      );
  static Widget playlist({Color? color}) =>
      IconTemplate('playlist.svg', color: color);
  static Widget playlistAdd({Color? color}) => IconTemplate('playlist_add.svg', color: color);
  static Widget playlistAdded({Color? color}) => IconTemplate('playlist_added.svg', color: color);
  static Widget playlistDelete({Color? color}) => IconTemplate(
    'playlist_delete.svg',
    color: color ?? Colors.red,
  );
  static Widget playlistList({Color? color}) => IconTemplate(
        'playlist_list.svg',
        color: color,
      );
  static Widget search({Color? color}) => IconTemplate(
        'search.svg',
        color: color,
      );
  static Widget star({Color? color}) => IconTemplate('star.svg', color: color);
  static Widget stop({Color? color}) => Center(
    child: Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
