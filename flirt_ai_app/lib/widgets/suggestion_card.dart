import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/app_state.dart';

class SuggestionCard extends StatelessWidget {
  final ConversationMessage message;

  const SuggestionCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getToneIcon(message.tone),
                const SizedBox(width: 8),
                Text(
                  _getToneName(message.tone),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(),
            Text(
              message.aiSuggestion,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.aiSuggestion));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copiado!')),
                    );
                  },
                  tooltip: 'Copiar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getToneIcon(String tone) {
    final icons = {
      'engraçado': '😄',
      'ousado': '🔥',
      'romântico': '❤️',
      'casual': '😎',
      'confiante': '💪',
    };
    return Text(icons[tone] ?? '😎', style: const TextStyle(fontSize: 24));
  }

  String _getToneName(String tone) {
    final names = {
      'engraçado': 'Engraçado',
      'ousado': 'Ousado',
      'romântico': 'Romântico',
      'casual': 'Casual',
      'confiante': 'Confiante',
    };
    return names[tone] ?? 'Casual';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inHours < 1) return '${diff.inMinutes}m atrás';
    if (diff.inDays < 1) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }
}
