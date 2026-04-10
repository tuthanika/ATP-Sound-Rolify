import 'package:flutter/material.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/presentation_logic_holders/singletons/backup_service.dart';
import 'package:rolify/presentation_logic_holders/singletons/theme_mode_controller.dart';
import 'package:rolify/src/theme/texts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
          left: 24.0, right: 24.0, top: 16.0, bottom: 96.0),
      children: <Widget>[
        _buildSectionTitle(context, 'Phát'),
        const SizedBox(height: 8.0),
        _buildPlaybackSettings(context),
        const SizedBox(height: 24.0),
        _buildSectionTitle(context, 'Sao lưu và khôi phục'),
        const SizedBox(height: 8.0),
        _buildBackupRestoreSettings(context),
        const SizedBox(height: 32.0),
        const Divider(),
        const SizedBox(height: 16.0),
        _buildAboutSection(context),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return MyText.body(
      title,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildPlaybackSettings(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: ThemeModeController().stopInsteadOfPause,
          builder: (context, value, child) {
            return _buildSettingItem(
              context,
              title: "Dừng thay vì tạm dừng",
              subtitle: "Khi tạm dừng, âm thanh sẽ được dừng hoàn toàn và đặt lại vị trí.",
              trailing: Switch(
                value: value,
                onChanged: (val) => ThemeModeController().setStopInsteadOfPause(val),
              ),
              onTap: () => ThemeModeController().setStopInsteadOfPause(!value),
            );
          },
        ),
        const SizedBox(height: 8.0),
        ValueListenableBuilder<bool>(
          valueListenable: ThemeModeController().playInBackground,
          builder: (context, value, child) {
            return _buildSettingItem(
              context,
              title: "Phát trong nền",
              subtitle: "Tiếp tục phát âm thanh ngay cả khi đóng ứng dụng.",
              trailing: Switch(
                value: value,
                onChanged: (val) => ThemeModeController().setPlayInBackground(val),
              ),
              onTap: () => ThemeModeController().setPlayInBackground(!value),
            );
          },
        ),
        const SizedBox(height: 8.0),
        ValueListenableBuilder<bool>(
          valueListenable: ThemeModeController().autoPauseDuringCalls,
          builder: (context, value, child) {
            return _buildSettingItem(
              context,
              title: "Tạm dừng khi có cuộc gọi",
              subtitle: "Tự động tạm dừng âm thanh khi có cuộc gọi đến (yêu cầu quyền Truy cập điện thoại).",
              trailing: Switch(
                value: value,
                onChanged: (val) => _handleAutoPauseToggle(context, val),
              ),
              onTap: () => _handleAutoPauseToggle(context, !value),
            );
          },
        ),
        const SizedBox(height: 8.0),
        ValueListenableBuilder<int>(
          valueListenable: ThemeModeController().maxConcurrentAudios,
          builder: (context, value, child) {
            return _buildSettingItem(
              context,
              title: "Giới hạn âm thanh phát cùng lúc",
              subtitle: "Số luồng tối đa có thể phát đồng thời.",
              trailing: SizedBox(
                width: 60,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 16 * heightFactor,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: value.toString(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  onSubmitted: (newValue) {
                    final int? limit = int.tryParse(newValue);
                    if (limit != null && limit > 0) {
                      ThemeModeController().setMaxConcurrentAudios(limit);
                    }
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8.0),
        ValueListenableBuilder<bool>(
          valueListenable: ThemeModeController().enableMarqueeText,
          builder: (context, value, child) {
            return _buildSettingItem(
              context,
              title: "Chạy chữ tên âm thanh",
              subtitle: "Cuộn chữ khi tên quá dài. Tắt đi sẽ ép chữ nhỏ lại để tiết kiệm CPU.",
              trailing: Switch(
                value: value,
                onChanged: (val) => ThemeModeController().setEnableMarqueeText(val),
              ),
              onTap: () => ThemeModeController().setEnableMarqueeText(!value),
            );
          },
        ),
      ],
    );
  }



  Widget _buildBackupRestoreSettings(BuildContext context) {
    return Column(
      children: [
        _buildSettingItem(
          context,
          title: "Sao lưu",
          subtitle: "Lưu tất cả âm thanh và danh sách phát vào tệp JSON.",
          icon: Icons.backup,
          onTap: () => BackupService.backup(context),
        ),
        const SizedBox(height: 8.0),
        _buildSettingItem(
          context,
          title: "Khôi phục",
          subtitle: "Khôi phục dữ liệu từ tệp sao lưu JSON.",
          icon: Icons.restore,
          onTap: () => BackupService.restore(context),
        ),
        const SizedBox(height: 8.0),
        _buildSettingItem(
          context,
          title: "Liên kết lại",
          subtitle: "Sửa đường dẫn bị hỏng bằng cách tìm kiếm tệp trong thư mục đã chọn.",
          icon: Icons.link,
          onTap: () => BackupService.relink(context),
        ),
      ],
    );
  }

  Future<void> _handleAutoPauseToggle(BuildContext context, bool value) async {
    if (value) {
      final status = await Permission.phone.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần quyền Truy cập điện thoại để nhận diện cuộc gọi.')),
          );
        }
        return;
      }
    }
    ThemeModeController().setAutoPauseDuringCalls(value);
  }



  Widget _buildSettingItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        title: MyText.body(title, fontWeight: FontWeight.w600),
        subtitle: MyText.caption(subtitle, textType: TextType.secondary),
        leading: icon != null
            ? Icon(icon, color: Theme.of(context).colorScheme.primary)
            : null,
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              child: Image.asset(
                'assets/icons/me.jpg',
                height: 24.0,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 24.0),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: MyText.body(
                "Made for fun by “madciock”.",
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
        const SizedBox(height: 16.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: <Widget>[
            _ClickableText(
              onTap: _goToReddit,
              text: "Reddit",
            ),
            MyText.caption('•', textType: TextType.secondary),
            _ClickableText(
              onTap: _goToGithub,
              text: "Github",
            ),
            MyText.caption('•', textType: TextType.secondary),
            _ClickableText(
              onTap: _openPlayStore,
              text: "Review",
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _goToReddit() async {
    final url = Uri.parse('https://www.reddit.com/r/RolifySoundboardApp/');
    await launchUrl(url);
  }

  Future<void> _goToGithub() async {
    final url = Uri.parse('https://github.com/Ciock/rolify/tree/master');
    await launchUrl(url);
  }

  Future<void> _openPlayStore() async {
    final Uri url;
    if (Platform.isIOS) {
      url = Uri.parse('https://apps.apple.com/app/id1511308478');
    } else {
      url = Uri.parse('https://play.google.com/store/apps/details?id=com.tuthanika.rolify.plus');
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

class _ClickableText extends StatelessWidget {
  const _ClickableText({
    Key? key,
    this.onTap,
    required this.text,
  }) : super(key: key);

  final VoidCallback? onTap;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MyText.caption(
        text,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.primary,
        textDecoration: TextDecoration.underline,
      ),
    );
  }
}
