import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'base_controller.dart';

class ChatController extends BaseController {
  final ChatService _service;

  ChatController(this._service);

  final List<ChatMessage> messages = <ChatMessage>[];

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(
      ChatMessage(text: text.trim(), isUser: true, timestamp: DateTime.now()),
    );
    notifyListeners();

    setLoading(true);
    clearMessages();

    final result = await _service.sendMessage(text.trim());

    setLoading(false);

    if (result.isSuccess) {
      messages.add(
        ChatMessage(
          text: result.data ?? 'No response received',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
      return;
    }

    setError(result.error ?? 'Chat service error');
  }
}
