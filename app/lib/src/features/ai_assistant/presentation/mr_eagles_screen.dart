import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';

class MrEaglesScreen extends ConsumerStatefulWidget {
  const MrEaglesScreen({super.key});

  @override
  ConsumerState<MrEaglesScreen> createState() => _MrEaglesScreenState();
}

class _MrEaglesScreenState extends ConsumerState<MrEaglesScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_MessageData> _messages = [
    const _MessageData(
      isUser: false,
      text: 'Hello! I am Mr. EaglEs, your AI Sales & Real Estate Assistant for Ethiopia. How can I help you find available units, analyze top CRM leads, or project sales revenue today?',
    ),
  ];
  bool _isLoading = false;

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final userText = text.trim();
    _controller.clear();

    setState(() {
      _messages.add(_MessageData(isUser: true, text: userText));
      _isLoading = true;
    });
    _scrollToBottom();

    // Simulate AI smart response processing (incorporating backend logic)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final lower = userText.toLowerCase();
      String replyText = '';
      List<_AiCardData>? cards;

      if (lower.contains('unit') || lower.contains('2br') || lower.contains('1br') || lower.contains('price') || lower.contains('available')) {
        replyText = 'I analyzed your active inventory in Addis Ababa. Here are the top featured units available for immediate reservation:';
        cards = const [
          _AiCardData(
            id: 'e-101',
            title: 'Unit A-101 (2BR)',
            subtitle: 'Eagle Heights • Bole, Addis Ababa',
            priceTag: 'ETB 4,200,000',
            status: 'Available',
            unitId: 'e-101',
            leadId: 'lead-1',
          ),
          _AiCardData(
            id: 'e-201',
            title: 'Unit A-201 (3BR Luxury)',
            subtitle: 'Eagle Heights • Bole, Addis Ababa',
            priceTag: 'ETB 6,300,000',
            status: 'Available',
            unitId: 'e-201',
            leadId: 'lead-2',
          ),
        ];
      } else if (lower.contains('lead') || lower.contains('client') || lower.contains('marta') || lower.contains('crm')) {
        replyText = 'Here are your top qualified prospects with high intent scores ready for follow-up:';
        cards = const [
          _AiCardData(
            id: 'lead-1',
            title: 'Marta Bekele',
            subtitle: 'Score: 88 • Budget: ETB 4.5M • Stage: Reservation',
            priceTag: 'Assigned: Dawit',
            status: 'Qualified',
            unitId: 'e-102',
            leadId: 'lead-1',
          ),
        ];
      } else {
        replyText = 'I have recorded your request. I am continuously syncing project analytics across all Ethiopian regional cities. Feel free to ask about available units, active leads, or sales forecasts!';
      }

      setState(() {
        _isLoading = false;
        _messages.add(_MessageData(isUser: false, text: replyText, cards: cards));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Mr. EaglEs AI Assistant',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Autonomous Real Estate & Construction Intelligence Agent',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.home_outlined, size: 16),
                  label: const Text('Available 2BR Units'),
                  onPressed: () => _sendMessage('Show available 2BR units'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.people_outline, size: 16),
                  label: const Text('Top Qualified Leads'),
                  onPressed: () => _sendMessage('Show top CRM leads'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.analytics_outlined, size: 16),
                  label: const Text('Sales Forecast'),
                  onPressed: () => _sendMessage('Give me sales revenue forecast'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _isLoading) {
                              return const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Mr. EaglEs is thinking...'),
                                  ],
                                ),
                              );
                            }
                            final msg = _messages[index];
                            return _ChatBubble(data: msg, ref: ref);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onSubmitted: _sendMessage,
                              decoration: InputDecoration(
                                hintText: 'Ask Mr. EaglEs anything...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filled(
                            onPressed: () => _sendMessage(_controller.text),
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageData {
  final bool isUser;
  final String text;
  final List<_AiCardData>? cards;

  const _MessageData({required this.isUser, required this.text, this.cards});
}

class _AiCardData {
  final String id;
  final String title;
  final String subtitle;
  final String priceTag;
  final String status;
  final String unitId;
  final String leadId;

  const _AiCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceTag,
    required this.status,
    required this.unitId,
    required this.leadId,
  });
}

class _ChatBubble extends StatelessWidget {
  final _MessageData data;
  final WidgetRef ref;

  const _ChatBubble({required this.data, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: data.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: data.isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.text,
              style: TextStyle(
                color: data.isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            if (data.cards != null && data.cards!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                children: data.cards!.map((card) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.apartment, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(card.subtitle, style: theme.textTheme.bodySmall),
                              Text(card.priceTag, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final repo = ref.read(propertyRepositoryProvider);
                            final activeTenant = ref.read(activeTenantProvider);
                            repo.reserveUnit(
                              tenantId: activeTenant,
                              leadId: card.leadId,
                              unitId: card.unitId,
                            );
                            ref.read(refreshTokenProvider.notifier).state++;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Unit ${card.title} reserved successfully!')),
                            );
                          },
                          child: const Text('Reserve'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

