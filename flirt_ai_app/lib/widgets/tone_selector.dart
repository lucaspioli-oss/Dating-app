import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ToneSelector extends StatelessWidget {
  const ToneSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha o Tom',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ToneChip(
                  label: '😄 Engraçado',
                  value: 'engraçado',
                  selected: appState.selectedTone == 'engraçado',
                  onSelected: () => appState.setSelectedTone('engraçado'),
                ),
                _ToneChip(
                  label: '🔥 Ousado',
                  value: 'ousado',
                  selected: appState.selectedTone == 'ousado',
                  onSelected: () => appState.setSelectedTone('ousado'),
                ),
                _ToneChip(
                  label: '❤️ Romântico',
                  value: 'romântico',
                  selected: appState.selectedTone == 'romântico',
                  onSelected: () => appState.setSelectedTone('romântico'),
                ),
                _ToneChip(
                  label: '😎 Casual',
                  value: 'casual',
                  selected: appState.selectedTone == 'casual',
                  onSelected: () => appState.setSelectedTone('casual'),
                ),
                _ToneChip(
                  label: '💪 Confiante',
                  value: 'confiante',
                  selected: appState.selectedTone == 'confiante',
                  onSelected: () => appState.setSelectedTone('confiante'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ToneChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onSelected;

  const _ToneChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }
}
