import 'package:moments_remembered/models/birthday.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageService {
  String draft(Birthday birthday, MessageTone tone) {
    final firstName = birthday.name.trim().split(RegExp(r'\s+')).first;
    final memory = birthday.notes.trim();
    final suffix = memory.isEmpty ? '' : ' $memory';
    return switch (tone) {
      MessageTone.warm => 'Happy birthday, $firstName! I hope your day is full of joy and that the year ahead brings you many wonderful moments.$suffix',
      MessageTone.playful => 'Happy birthday, $firstName! 🎉 Wishing you plenty of cake, laughter, and reasons to celebrate today.$suffix',
      MessageTone.short => 'Happy birthday, $firstName! Wishing you a wonderful day and a happy year ahead. 🎂',
      MessageTone.formal => 'Wishing you a very happy birthday, $firstName. May the coming year bring you happiness, good health, and success.',
    };
  }

  Future<bool> openComposer(Birthday birthday, String message) async {
    if (birthday.channel == MessageChannel.share) {
      await SharePlus.instance.share(ShareParams(text: message));
      return true;
    }
    final phone = birthday.phoneNumber.replaceAll(RegExp(r'[^+\d]'), '');
    final encoded = Uri.encodeComponent(message);
    final candidates = switch (birthday.channel) {
      MessageChannel.sms => [Uri.parse('sms:$phone?body=$encoded')],
      MessageChannel.whatsapp => [
          Uri.parse('whatsapp://send?phone=$phone&text=$encoded'),
          Uri.parse('https://wa.me/$phone?text=$encoded'),
        ],
      MessageChannel.share => <Uri>[],
    };

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    return false;
  }
}
