import 'package:flutter/material.dart';
import '../models/training_feedback_model.dart';
import '../services/training_feedback_service.dart';
import '../config/app_theme.dart';

class TrainingFeedbackScreen extends StatefulWidget {
  const TrainingFeedbackScreen({super.key});

  @override
  State<TrainingFeedbackScreen> createState() => _TrainingFeedbackScreenState();
}

class _TrainingFeedbackScreenState extends State<TrainingFeedbackScreen> {
  List<TrainingFeedback> _feedbacks = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    final feedbacks = await TrainingFeedbackService.getAll();
    setState(() {
      _feedbacks = feedbacks;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddFeedbackDialog(
        onSaved: () {
          _loadFeedbacks();
        },
      ),
    );
  }

  void _showEditDialog(TrainingFeedback feedback) {
    showDialog(
      context: context,
      builder: (context) => _EditFeedbackDialog(
        feedback: feedback,
        onSaved: () {
          _loadFeedbacks();
        },
        onDeleted: () {
          _loadFeedbacks();
        },
      ),
    );
  }

  List<TrainingFeedback> get _filteredFeedbacks {
    if (_selectedCategory == null) return _feedbacks;
    return _feedbacks.where((f) => f.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Treinamento IA'),
        backgroundColor: AppColors.surfaceDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedbacks,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFeedbacks.isEmpty
                    ? _buildEmptyState()
                    : _buildFeedbackList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nova Instrucao'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(null, 'Todos'),
            ...TrainingFeedback.categories.map((cat) =>
              _buildFilterChip(cat, TrainingFeedback.categoryLabel(cat))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primary.withAlpha(77),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: AppColors.textPrimary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma instrucao de treinamento',
            style: TextStyle(color: AppColors.textPrimary.withOpacity(0.54), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione instrucoes para melhorar a IA',
            style: TextStyle(color: AppColors.textPrimary.withOpacity(0.38), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList() {
    // Agrupa por categoria
    final grouped = <String, List<TrainingFeedback>>{};
    for (final f in _filteredFeedbacks) {
      grouped.putIfAbsent(f.category, () => []).add(f);
    }

    if (_selectedCategory != null) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredFeedbacks.length,
        itemBuilder: (context, index) {
          return _buildFeedbackCard(_filteredFeedbacks[index]);
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                TrainingFeedback.categoryLabel(entry.key),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...entry.value.map(_buildFeedbackCard),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFeedbackCard(TrainingFeedback feedback) {
    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          feedback.instruction,
          style: TextStyle(
            color: feedback.isActive ? AppColors.textPrimary : AppColors.textPrimary.withOpacity(0.38),
            decoration: feedback.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feedback.examples.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ex: ${feedback.examples.first}',
                  style: TextStyle(color: AppColors.textPrimary.withOpacity(0.54), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  TrainingFeedback.priorityLabel(feedback.priority),
                  style: TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 8),
                Text(
                  'Usado ${feedback.usageCount}x',
                  style: TextStyle(color: AppColors.textPrimary.withOpacity(0.38), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textPrimary.withOpacity(0.38),
        ),
        onTap: () => _showEditDialog(feedback),
      ),
    );
  }
}

class _AddFeedbackDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _AddFeedbackDialog({required this.onSaved});

  @override
  State<_AddFeedbackDialog> createState() => _AddFeedbackDialogState();
}

class _AddFeedbackDialogState extends State<_AddFeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _instructionController = TextEditingController();
  final _examplesController = TextEditingController();
  String _selectedCategory = 'general';
  String _selectedPriority = 'medium';
  bool _isSaving = false;

  @override
  void dispose() {
    _instructionController.dispose();
    _examplesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final examples = _examplesController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final result = await TrainingFeedbackService.create(
      category: _selectedCategory,
      instruction: _instructionController.text.trim(),
      examples: examples.isNotEmpty ? examples : null,
      priority: _selectedPriority,
    );

    setState(() => _isSaving = false);

    if (result != null) {
      Navigator.of(context).pop();
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instrucao salva com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar instrucao')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Nova Instrucao de Treinamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Categoria
                const Text('Categoria', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: AppColors.surfaceDark,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: TrainingFeedback.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        TrainingFeedback.categoryLabel(cat),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Instrucao
                const Text('Instrucao', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _instructionController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ex: Use humor sutil ao invés de elogios diretos',
                    hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.38)),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Instrucao é obrigatória';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Exemplos
                const Text('Exemplos (um por linha, opcional)',
                    style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _examplesController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ex: "quer roubar meu moletom?"\n"to no mercado, quer algo?"',
                    hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.38)),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Prioridade
                const Text('Prioridade', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  dropdownColor: AppColors.surfaceDark,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: TrainingFeedback.priorities.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        TrainingFeedback.priorityLabel(p),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPriority = value!);
                  },
                ),
                const SizedBox(height: 24),

                // Botoes
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditFeedbackDialog extends StatefulWidget {
  final TrainingFeedback feedback;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  const _EditFeedbackDialog({
    required this.feedback,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  State<_EditFeedbackDialog> createState() => _EditFeedbackDialogState();
}

class _EditFeedbackDialogState extends State<_EditFeedbackDialog> {
  late final TextEditingController _instructionController;
  late final TextEditingController _examplesController;
  late String _selectedPriority;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _instructionController = TextEditingController(text: widget.feedback.instruction);
    _examplesController = TextEditingController(
      text: widget.feedback.examples.join('\n'),
    );
    _selectedPriority = widget.feedback.priority;
    _isActive = widget.feedback.isActive;
  }

  @override
  void dispose() {
    _instructionController.dispose();
    _examplesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final examples = _examplesController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final result = await TrainingFeedbackService.update(
      id: widget.feedback.id,
      instruction: _instructionController.text.trim(),
      examples: examples,
      priority: _selectedPriority,
      isActive: _isActive,
    );

    setState(() => _isSaving = false);

    if (result != null) {
      Navigator.of(context).pop();
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instrucao atualizada!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Confirmar exclusao', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Tem certeza que deseja excluir esta instrucao?',
          style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await TrainingFeedbackService.delete(widget.feedback.id);
      if (success) {
        Navigator.of(context).pop();
        widget.onDeleted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instrucao excluída')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Editar Instrucao',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: _delete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                TrainingFeedback.categoryLabel(widget.feedback.category),
                style: TextStyle(color: AppColors.textPrimary.withOpacity(0.54)),
              ),
              const SizedBox(height: 24),

              // Instrucao
              const Text('Instrucao', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instructionController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Exemplos
              const Text('Exemplos (um por linha)',
                  style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _examplesController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Prioridade
              const Text('Prioridade', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                dropdownColor: AppColors.surfaceDark,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: TrainingFeedback.priorities.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(
                      TrainingFeedback.priorityLabel(p),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPriority = value!);
                },
              ),
              const SizedBox(height: 16),

              // Ativo
              SwitchListTile(
                title: const Text('Ativo', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(
                  _isActive
                      ? 'Esta instrucao sera usada nos prompts'
                      : 'Esta instrucao está desativada',
                  style: TextStyle(color: AppColors.textPrimary.withOpacity(0.54), fontSize: 12),
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
                activeTrackColor: AppColors.primary,
              ),
              const SizedBox(height: 16),

              // Stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${widget.feedback.usageCount}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Usos',
                          style: TextStyle(color: AppColors.textPrimary.withOpacity(0.54), fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          _formatDate(widget.feedback.createdAt),
                          style: const TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Criado em',
                          style: TextStyle(color: AppColors.textPrimary.withOpacity(0.54), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botoes
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
