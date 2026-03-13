import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/conversation.dart';

/// Collapsible card that displays AI-detected conversation patterns.
class CalibrationCard extends StatefulWidget {
  final DetectedPatterns patterns;

  const CalibrationCard({
    super.key,
    required this.patterns,
  });

  @override
  State<CalibrationCard> createState() => _CalibrationCardState();
}

class _CalibrationCardState extends State<CalibrationCard> {
  bool _isExpanded = false;

  String _responseLengthLabel(String value) {
    switch (value) {
      case 'short':
        return 'Curto';
      case 'long':
        return 'Longo';
      default:
        return 'Medio';
    }
  }

  String _emotionalToneLabel(String value) {
    switch (value) {
      case 'warm':
        return 'Quente';
      case 'cold':
        return 'Frio';
      default:
        return 'Neutro';
    }
  }

  String _flirtLevelLabel(String value) {
    switch (value) {
      case 'high':
        return 'Alto';
      case 'low':
        return 'Baixo';
      default:
        return 'Medio';
    }
  }

  String _timeAgoText(DateTime lastUpdated) {
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);

    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'ha ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'ha ${diff.inHours}h';
    return 'ha ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - always visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    '\u{1F9E0} Calibragem IA',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 4 mini-cards in a row
                        Row(
                          children: [
                            _MiniCard(
                              emoji: widget.patterns.responseLengthEmoji,
                              label: 'Tamanho',
                              value: _responseLengthLabel(
                                  widget.patterns.responseLength),
                            ),
                            const SizedBox(width: 8),
                            _MiniCard(
                              emoji: widget.patterns.emotionalToneEmoji,
                              label: 'Tom',
                              value: _emotionalToneLabel(
                                  widget.patterns.emotionalTone),
                            ),
                            const SizedBox(width: 8),
                            _MiniCard(
                              emoji: widget.patterns.flirtLevelEmoji,
                              label: 'Flerte',
                              value: _flirtLevelLabel(
                                  widget.patterns.flirtLevel),
                            ),
                            const SizedBox(width: 8),
                            _MiniCard(
                              emoji: widget.patterns.useEmojis
                                  ? '\u{1F60A}'
                                  : '\u{1F645}',
                              label: 'Emojis',
                              value:
                                  widget.patterns.useEmojis ? 'Sim' : 'Nao',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Last updated
                        Text(
                          'Atualizado: ${_timeAgoText(widget.patterns.lastUpdated)}',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// A small card showing an emoji icon and a labeled value.
class _MiniCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _MiniCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.elevatedDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
