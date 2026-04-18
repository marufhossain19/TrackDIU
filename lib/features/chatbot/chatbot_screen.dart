// ====================================================
// features/chatbot/chatbot_screen.dart — Rule-based chatbot
// ====================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../providers/app_providers.dart';
import '../../services/openrouter_service.dart';
import '../../widgets/animated_button.dart' show ChatBubble;

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _inputCtrl   = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _openRouterService = OpenRouterService();
  bool _isTyping     = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _getFallbackResponse(String input) {
    final lower = input.toLowerCase();
    for (final rule in kChatbotRules) {
      if (lower.contains(rule['trigger']!)) {
        return rule['response']!;
      }
    }
    return '🤔 I\'m not sure about that. Try asking:\n• "bus to mirpur"\n• "schedule"\n• "route"\n• "contact"';
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final historyMessages = ref.read(chatMessagesProvider);

    _inputCtrl.clear();

    // Add user message
    ref.read(chatMessagesProvider.notifier).update(
      (msgs) => [...msgs, ChatMessage(
        text: text, isUser: true, timestamp: DateTime.now())]);

    _scrollToBottom();

    // Show typing indicator
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 800));

    String response;
    try {
      response = await _openRouterService.askAssistant(
        prompt: text,
        history: historyMessages
            .take(8)
            .map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.text,
                })
            .toList(),
      );
    } catch (_) {
      response = _getFallbackResponse(text);
    }

    setState(() => _isTyping = false);

    ref.read(chatMessagesProvider.notifier).update(
      (msgs) => [...msgs, ChatMessage(
        text: response, isUser: false, timestamp: DateTime.now())]);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final quickReplyTextColor =
        isDark ? const Color(0xFFBFDBFE) : AppColors.primary;
    final quickReplyBg = isDark
        ? const Color(0xFF1E3A8A).withOpacity(0.35)
        : AppColors.primary.withOpacity(0.1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartBus Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear chat',
            onPressed: () => ref.read(chatMessagesProvider.notifier).state = [
              ChatMessage(
                text: '👋 Chat cleared! How can I help you?',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Chat Messages ─────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isTyping && i == messages.length) {
                  return const _TypingIndicator();
                }
                final msg = messages[i];
                return ChatBubble(
                  text     : msg.text,
                  isUser   : msg.isUser,
                  timestamp: msg.timestamp,
                );
              },
            ),
          ),
          // ── Quick Replies ─────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: ['Schedule', 'Routes', 'Mirpur', 'Dhanmondi',
                         'Uttara', 'Contact'].map((q) {
                return GestureDetector(
                  onTap: () {
                    _inputCtrl.text = q;
                    _sendMessage();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: quickReplyBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: quickReplyTextColor.withOpacity(0.35),
                      ),
                    ),
                    child: Text(q,
                        style: TextStyle(
                          color: quickReplyTextColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // ── Input Bar ────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask me about buses...',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46, height: 46,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated typing indicator — 3 bouncing dots
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft   : Radius.circular(18),
            topRight  : Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft : Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final t = (_pulseCtrl.value - (i * 0.2)) % 1.0;
                final scale = t < 0.5 ? (0.78 + (t * 0.8)) : (1.18 - ((t - 0.5) * 0.8));
                final alpha = t < 0.5 ? (0.42 + (t * 1.1)) : (0.97 - ((t - 0.5) * 0.9));
                final dotColor = isDark
                    ? Colors.white.withValues(alpha: alpha.clamp(0.35, 1))
                    : AppColors.primary.withValues(alpha: alpha.clamp(0.3, 1));
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 7.5 * scale,
                  height: 7.5 * scale,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
