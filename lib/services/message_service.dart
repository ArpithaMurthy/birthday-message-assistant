import 'package:moments_remembered/models/occasion.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageService {
  String draft(Occasion occasion, MessageTone tone) {
    if (occasion.defaultMessage.trim().isNotEmpty) {
      return occasion.defaultMessage.trim();
    }
    final recipient = occasion.personName.trim().isEmpty ? '' : ', ${occasion.personName.trim().split(RegExp(r'\s+')).first}';
    final memory = occasion.notes.trim();
    final suffix = memory.isEmpty ? '' : ' $memory';
    final greeting = switch (occasion.type) {
      OccasionType.birthday => 'Happy birthday$recipient',
      OccasionType.anniversary => 'Happy anniversary$recipient',
      OccasionType.newYear => 'Happy New Year$recipient',
      OccasionType.holiday => 'Warm wishes for ${occasion.title}$recipient',
      OccasionType.custom => 'Thinking of you for ${occasion.title}$recipient',
    };
    return switch (tone) {
      MessageTone.warm => '$greeting! I hope this special occasion brings joy and many wonderful moments.$suffix',
      MessageTone.playful => '$greeting! 🎉 Hope it is filled with laughter, happiness, and plenty of reasons to celebrate.$suffix',
      MessageTone.short => '$greeting! Wishing you a wonderful day. ✨',
      MessageTone.formal => '$greeting. Wishing you happiness, good health, and every success.',
    };
  }

  Future<bool> openComposer(Occasion occasion, String message) async {
    if (occasion.channel == MessageChannel.share) {
      await SharePlus.instance.share(ShareParams(text: message));
      return true;
    }
    final phone = occasion.phoneNumber.replaceAll(RegExp(r'[^+\d]'), '');
    final encoded = Uri.encodeComponent(message);
    final candidates = switch (occasion.channel) {
      MessageChannel.share => <Uri>[],
      MessageChannel.sms => [Uri.parse(phone.isEmpty ? 'sms:?body=$encoded' : 'sms:$phone?body=$encoded')],
      MessageChannel.whatsapp => phone.isEmpty
          ? [Uri.parse('whatsapp://send?text=$encoded'), Uri.parse('https://wa.me/?text=$encoded')]
          : [
              Uri.parse('whatsapp://send?phone=$phone&text=$encoded'),
              Uri.parse('https://wa.me/$phone?text=$encoded'),
            ],
      MessageChannel.line => [Uri.parse('https://line.me/R/share?text=$encoded')],
    };

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    return false;
  }
}
