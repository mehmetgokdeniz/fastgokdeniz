import 'package:url_launcher/url_launcher.dart';
import '../../core/enums/message_type.dart';
import '../models/message_model.dart';

class MessageService {
  Future<void> sendMessage(MessageModel message) async {
    String phone = message.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    String url;

    switch (message.type) {
      case MessageType.whatsapp:
        url = 'https://api.whatsapp.com/send?phone=$phone';
        break;
      case MessageType.instagram:
        url = 'https://instagram.com/$phone';
        break;
      case MessageType.x:
        url = 'https://twitter.com/$phone';
        break;
      case MessageType.discord:
        url = 'https://discordapp.com/users/$phone';
        break;
      case MessageType.email:
        url = 'mailto:$phone';
        break;
      case MessageType.sms:
        url = message.message != null && message.message!.isNotEmpty
            ? 'sms:$phone?body=${Uri.encodeComponent(message.message!)}'
            : 'sms:$phone';
        break;
      case MessageType.facebook:
        url = 'https://www.facebook.com/$phone';
        break;
      case MessageType.youtube:
        url = 'https://www.youtube.com/$phone';
        break;
      case MessageType.telegram:
        url = 'https://t.me/$phone';
        break;
      case MessageType.github:
        url = 'https://github.com/$phone';
        break;
      case MessageType.linkedin:
        url = 'https://linkedin.com/in/$phone';
        break;
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}