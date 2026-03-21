import 'package:flutter/material.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/presentation_logic_holders/singletons/backup_service.dart';
import 'package:rolify/presentation_logic_holders/singletons/theme_mode_controller.dart';
import 'package:rolify/src/theme/texts.dart';
import 'package:launch_review/launch_review.dart';
import 'package:url_launcher/url_launcher.dart';

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
              subtitle: "Tự động tạm dừng âm thanh khi có cuộc gọi đến hoặc tiêu điểm âm thanh bị mất.",
              trailing: Switch(
                value: value,
                onChanged: (val) => ThemeModeController().setAutoPauseDuringCalls(val),
              ),
              onTap: () => ThemeModeController().setAutoPauseDuringCalls(!value),
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
        color: Theme.of(context).cardColor.withOpacity(0.5),
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

  void _openPlayStore() {
    LaunchReview.launch(iOSAppId: '1511308478');
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
