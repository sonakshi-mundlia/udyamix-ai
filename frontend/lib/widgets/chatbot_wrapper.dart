import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/language_provider.dart';

/// 🧠 MESSAGE MODEL
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatbotWrapper extends StatefulWidget {
  final Widget child;

  /// 🔥 CONTROL MODES
  final bool openByDefault;
  final bool showFloatingButton; // 👈 for dashboard
  final Widget? customButton; // 👈 for help screen

  const ChatbotWrapper({
    super.key,
    required this.child,
    this.openByDefault = false,
    this.showFloatingButton = true,
    this.customButton,
  });

  @override
  ChatbotWrapperState createState() => ChatbotWrapperState();
}

class ChatbotWrapperState extends State<ChatbotWrapper> {
  bool isOpen = false;
  bool isListening = false;
  late stt.SpeechToText _speech;
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> messages = [];
  bool showMenuButtons = false;
  bool isLoggedIn = false;
  bool _greetingAdded = false; // guard to avoid adding greeting multiple times

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    if (widget.openByDefault) isOpen = true;

    _checkLogin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize greeting after Provider is available
    final langProvider = context.watch<LanguageProvider>();
    if (!_greetingAdded) {
      messages.add(ChatMessage(
        text: langProvider.translate('chatbot.greeting'),
        isUser: false,
      ));
      _greetingAdded = true;
    }
  }

  Future<void> _checkLogin() async {
    isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn) _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await ApiService.getChatHistory();
    if (!mounted) return;
    setState(() {
      messages = history
          .map((msg) => ChatMessage(text: msg["text"], isUser: msg["isUser"]))
          .toList();
    });
  }

  Future<void> _deleteHistory() async {
    await ApiService.deleteChatHistory();
    if (!mounted) return;
    setState(() {
      messages = [];
      showMenuButtons = false;
    });
  }

  void openChat() {
    if (!mounted) return;
    setState(() => isOpen = true);
  }

  void toggleChat() {
    if (!mounted) return;
    setState(() => isOpen = !isOpen);
  }

  Future<void> startListening() async {
    if (!isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => isListening = true);
        _speech.listen(onResult: (result) {
          if (!mounted) return;
          controller.text = result.recognizedWords;
          if (result.finalResult) stopListening(send: true);
        });
      }
    } else {
      stopListening();
    }
  }

  void stopListening({bool send = false}) {
    _speech.stop();
    if (!mounted) return;
    setState(() => isListening = false);
    if (send && controller.text.trim().isNotEmpty) sendMessage();
  }

  Future<void> sendMessage() async {
    String message = controller.text.trim();
    if (message.isEmpty) return;

    final langProvider = context.read<LanguageProvider>();

    setState(() {
      messages.add(ChatMessage(text: message, isUser: true));
    });
    controller.clear();
    _scrollToBottom();

    try {
      Map<String, dynamic>? response;
      if (isLoggedIn) {
        response = await ApiService.sendBusinessChat(message: message, lang: "en");
      } else {
        response = await ApiService.sendGuestChat(message: message, lang: "en");
      }
      if (!mounted) return;

      setState(() {
        messages.add(ChatMessage(
          text: response?["answer"] ?? langProvider.translate('chatbot.error'),
          isUser: false,
        ));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(
          text: langProvider.translate('chatbot.server_error'),
          isUser: false,
        ));
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final t = langProvider.translate;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        widget.child,

        /// 💬 CHAT BOX
        if (isOpen)
          Positioned(
            bottom: 80,
            right: 20,
            child: Container(
              width: screenWidth < 600 ? screenWidth * 0.9 : 400,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  /// HEADER WITH INLINE MENU
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t('chatbot.title'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Row(
                              children: [
                                if (isLoggedIn)
                                  IconButton(
                                    icon:
                                    const Icon(Icons.menu, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        showMenuButtons = !showMenuButtons;
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon:
                                  const Icon(Icons.close, color: Colors.white),
                                  onPressed: toggleChat,
                                ),
                              ],
                            ),
                          ],
                        ),

                        /// INLINE MENU BUTTONS
                        if (showMenuButtons)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.history),
                                  label: Text(t('chatbot.view_history')),
                                  onPressed: () {
                                    // optionally scroll to top/history
                                  },
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.delete),
                                  label: Text(t('chatbot.delete_history')),
                                  onPressed: _deleteHistory,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      showMenuButtons = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  /// MESSAGES
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        return Align(
                          alignment: msg.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                color: msg.isUser ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  /// INPUT
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: t('chatbot.type'),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            color: isListening ? Colors.red : Colors.blue,
                          ),
                          onPressed: startListening,
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        /// 🔘 FLOATING ICON (Dashboard)
        if (widget.showFloatingButton)
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: toggleChat,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.smart_toy, color: Colors.white),
              ),
            ),
          ),

        /// 🔘 CUSTOM BUTTON (Help Screen)
        if (widget.customButton != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: toggleChat,
              child: widget.customButton!,
            ),
          ),
      ],
    );
  }
}

