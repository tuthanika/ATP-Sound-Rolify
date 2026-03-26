import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:rolify/entities/audio.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_event.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_state.dart';
import 'package:rolify/presentation_logic_holders/audio_service_commands.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/text_field.dart';

// Import thêm các thư viện cần thiết để xử lý đổi Path
import 'package:rolify/data/audios.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_event.dart';
import 'package:rolify/presentation_logic_holders/audio_download_manager.dart';

import 'add_sound_to_playlist.dart';

class SoundEdit extends StatelessWidget {
  final controller = TextEditingController();
  
  // Thêm kênh giao tiếp để mở trình duyệt file
  static const platform = MethodChannel('rolify/file_picker'); 

  SoundEdit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioEditBloc, AudioEditState>(
        builder: (context, state) {
      controller.text = state.audio?.name ?? '';
      return Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(16.0)),
            ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: MyTextField(
                      controller: controller,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  MyButton(
                      icon: MyIcons.done(),
                      onTap: () => saveAudioName(context, state.audio)),
                ],
              ),
              const SizedBox(height: 16.0),
              if (state.audio != null)
                Row(
                  children: <Widget>[
                    MyButton(
                        icon: MyIcons.close(),
                        onTap: () => BlocProvider.of<AudioEditBloc>(context)
                            .add(CancelEditing(context, state.audio))),
                    const SizedBox(width: 16.0),
                    MyButton(
                      icon: MyIcons.playlistAdd(),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddSoundToPlaylist(
                                    audio: state.audio!,
                                  ))),
                    ),
                    const SizedBox(width: 16.0),
                    // --- NÚT MỚI: ĐỔI PATH / NGUỒN ÂM THANH ---
                    MyButton(
                      icon: Icon(
                        Icons.link_rounded, 
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                      ),
                      onTap: () => _showChangePathDialog(context, state.audio!),
                    ),
                    // ------------------------------------------
                    Expanded(
                      child: Container(),
                    ),
                    MyButton(
                        icon: MyIcons.delete(),
                        onTap: () => deleteAudio(context, state.audio!)),
                  ],
                )
            ],
          ),
        ),
      );
    });
  }

  // --- HÀM LOGIC ĐỔI PATH ---
  void _showChangePathDialog(BuildContext context, Audio currentAudio) {
    final pathController = TextEditingController(text: currentAudio.path);
    bool saveOffline = currentAudio.isOfflineMode;

    showDialog(
      context: context,
      builder: (contextDialog) => StatefulBuilder(
        builder: (contextDialog, setStateDialog) {
          return AlertDialog(
            backgroundColor: Theme.of(contextDialog).colorScheme.surface,
            title: const Text('Đổi nguồn âm thanh', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pathController,
                  decoration: const InputDecoration(hintText: 'Nhập URL / Path mới...'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Lưu Offline', style: TextStyle(fontSize: 14)),
                  value: saveOffline,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    setStateDialog(() => saveOffline = val ?? true);
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final List<dynamic>? result = await platform.invokeMethod('pickAudioFiles');
                        if (result != null && result.isNotEmpty) {
                          final item = result.first as Map;
                          pathController.text = item['path']?.toString() ?? '';
                          // Thêm dòng này để tự động bỏ Tích Offline trên UI
                          setStateDialog(() => saveOffline = false);
                        }
                      } catch (e) {
                        debugPrint("Lỗi chọn file: $e");
                      }
                    },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Chọn file từ máy'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(contextDialog),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  if (pathController.text.isNotEmpty && pathController.text != currentAudio.path) {
                    Navigator.pop(contextDialog); 
                    AudioServiceCommands.stop(currentAudio);
                    
                    // BẢO VỆ DỮ LIỆU: Nếu path CŨ là dạng URL thì mới gọi lệnh dọn rác Cache
                    // Tuyệt đối không chạm vào file nếu path cũ là file từ máy người dùng
                    if (currentAudio.path.startsWith('http')) {
                       await AudioFileManager.deleteLocalFile(currentAudio.name);
                    }

                    // Lấy đường dẫn GỐC mới do người dùng nhập (hoặc chọn từ máy)
                    String newPath = pathController.text;

                    // Nếu đường dẫn mới là URL -> Gọi Manager để tải Data về Cache/Offline
                    if (newPath.startsWith('http')) {
                       // Hàm này sẽ tự động phân loại lưu Cache tạm hay Offline dựa vào biến saveOffline
                       final processResult = await AudioFileManager.processPath(
                           newPath, currentAudio.name, saveOffline
                       );
                       if (processResult == null) {
                         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi tải file mới!')));
                         return; 
                       }
                    }

                    // BẮT ĐẦU LƯU VÀO DATABASE
                    final allAudios = await AudioData.getAllAudios();
                    final index = allAudios.indexWhere((a) => a.path == currentAudio.path);
                    if (index != -1) {
                      final updatedAudio = allAudios[index].copyFrom(
                        path: newPath, // LUÔN GHI ĐÈ PATH GỐC (URL mới hoặc Local mới)
                        isOfflineMode: saveOffline,
                        audioSource: LocalAudioSource.file // Ép mác file để tránh lỗi just_audio
                      );
                      allAudios[index] = updatedAudio;
                      
                      await AudioData.saveAllAudios(context, allAudios);
                      
                      if (context.mounted) {
                        BlocProvider.of<AudioListBloc>(context).add(AudioListUpdate(allAudios));
                        BlocProvider.of<AudioEditBloc>(context).add(CancelEditing(context, updatedAudio));
                      }
                      
                      AudioServiceCommands.play(updatedAudio);
                    }
                  } else {
                    Navigator.pop(contextDialog);
                  }
                },
                child: const Text('Lưu & Phát'),
              ),
            ],
          );
        }
      ),
    );
  }

  saveAudioName(BuildContext context, Audio? audio) {
    if (audio != null) {
      audio = audio.copyFrom(name: controller.text);
    }
    BlocProvider.of<AudioEditBloc>(context).add(ConfirmEditing(context, audio));
  }

  deleteAudio(BuildContext context, Audio audio) async {
    stop(audio);
    if (audio.path.startsWith('http')) {
      await AudioFileManager.deleteLocalFile(audio.name);
    }
    if (audio.audioSource == LocalAudioSource.assets) {
      showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text(
            'This cannot be reverted!',
          ),
          content: const Text(
            'You will be able to reload this audio only downloading the app again removing so your current audios already uploaded, continue?',
          ),
          actions: [
            CupertinoDialogAction(
                isDefaultAction: false,
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'No',
                )),
            CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Yes',
                )),
          ],
        ),
      ).then((value) async {
        if (value == true) {
          BlocProvider.of<AudioEditBloc>(context)
              .add(DeleteAudio(context, audio));
        }
      });
    } else {
      BlocProvider.of<AudioEditBloc>(context).add(DeleteAudio(context, audio));
    }
  }

  void stop(Audio audio) {
    AudioServiceCommands.stop(audio);
  }
}