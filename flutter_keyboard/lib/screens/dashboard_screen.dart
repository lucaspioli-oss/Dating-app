import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/conversation.dart';
import '../services/conversation_service.dart';
import '../services/freemium_service.dart';
import '../services/subscription_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;

  // Aggregated stats
  int _totalSuggestions = 0;
  int _totalAiMessages = 0;
  int _totalCustomMessages = 0;
  int _totalMessages = 0;
  int _weeklyMessages = 0;
  List<_TopConversation> _topConversations = [];

  // Freemium
  int _dailyUsed = 0;
  bool _isSubscriber = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversationService =
          ConversationService(baseUrl: AppConfig.backendUrl);
      final freemiumService = FreemiumService();
      final subscriptionService = SubscriptionService();

      // Fetch all data in parallel
      final results = await Future.wait([
        conversationService.listConversations(),
        freemiumService.getDailyUsageCount(),
        subscriptionService.subscriptionStatusStream.first,
      ]);

      final conversations = results[0] as List<ConversationListItem>;
      final dailyUsed = results[1] as int;
      final subStatus = results[2] as SubscriptionStatus;

      // To get analytics we need to fetch full conversations
      int totalSuggestions = 0;
      int totalAi = 0;
      int totalCustom = 0;
      int totalMsgs = 0;
      int weeklyMsgs = 0;
      final List<_TopConversation> topConvos = [];

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      // Fetch full conversation details for analytics
      final fullConversations = <Conversation>[];
      for (final conv in conversations) {
        try {
          final full =
              await conversationService.getConversation(conv.id);
          fullConversations.add(full);
        } catch (_) {
          // Skip conversations that fail to load
        }
      }

      for (final conv in fullConversations) {
        final analytics = conv.avatar.analytics;
        totalSuggestions += analytics.aiSuggestionsUsed;
        totalAi += analytics.aiSuggestionsUsed;
        totalCustom += analytics.customMessagesUsed;
        totalMsgs += analytics.totalMessages;

        // Count weekly messages
        for (final msg in conv.messages) {
          if (msg.timestamp.isAfter(weekAgo)) {
            weeklyMsgs++;
          }
        }

        topConvos.add(_TopConversation(
          name: conv.avatar.matchName,
          platform: conversations
              .firstWhere((c) => c.id == conv.id,
                  orElse: () => conversations.first)
              .platform,
          faceImageUrl: conv.avatar.faceImageUrl,
          totalMessages: analytics.totalMessages,
        ));
      }

      // Sort by total messages descending, take top 3
      topConvos.sort((a, b) => b.totalMessages.compareTo(a.totalMessages));

      if (mounted) {
        setState(() {
          _totalSuggestions = totalSuggestions;
          _totalAiMessages = totalAi;
          _totalCustomMessages = totalCustom;
          _totalMessages = totalMsgs;
          _weeklyMessages = weeklyMsgs;
          _topConversations = topConvos.take(3).toList();
          _dailyUsed = dailyUsed;
          _isSubscriber = subStatus == SubscriptionStatus.active;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const GradientText(
          text: 'Stats',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      _buildUsageRatioCard(),
                      const SizedBox(height: 16),
                      if (!_isSubscriber) ...[
                        _buildFreeUsesCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildWeeklyActivityCard(),
                      const SizedBox(height: 16),
                      if (_topConversations.isNotEmpty)
                        _buildTopConversationsCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Tentar novamente',
              icon: Icons.refresh,
              onPressed: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // 1. Header card - total AI suggestions generated
  // --------------------------------------------------
  Widget _buildHeaderCard() {
    return GradientBorderCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_totalSuggestions',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'sugestoes geradas',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // 2. Usage ratio - AI vs custom messages bar
  // --------------------------------------------------
  Widget _buildUsageRatioCard() {
    final total = _totalAiMessages + _totalCustomMessages;
    final aiRatio = total > 0 ? _totalAiMessages / total : 0.0;
    final customRatio = total > 0 ? _totalCustomMessages / total : 0.0;
    final aiPercent = (aiRatio * 100).round();
    final customPercent = (customRatio * 100).round();

    return GradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de mensagens',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: total > 0
                  ? CustomPaint(
                      size: const Size(double.infinity, 24),
                      painter: _UsageBarPainter(aiRatio: aiRatio),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.elevatedDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              _legendDot(AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'IA: $_totalAiMessages ($aiPercent%)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 20),
              _legendDot(AppColors.info),
              const SizedBox(width: 6),
              Text(
                'Proprias: $_totalCustomMessages ($customPercent%)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // --------------------------------------------------
  // 3. Free uses remaining (non-subscribers only)
  // --------------------------------------------------
  Widget _buildFreeUsesCard() {
    final remaining = FreemiumService.maxFreeUsesPerDay - _dailyUsed;
    final clampedRemaining = remaining < 0 ? 0 : remaining;
    final progress = _dailyUsed / FreemiumService.maxFreeUsesPerDay;

    return GradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Sugestoes gratis hoje',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$clampedRemaining/${FreemiumService.maxFreeUsesPerDay}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.elevatedDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                clampedRemaining > 0 ? AppColors.warning : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            clampedRemaining > 0
                ? '$_dailyUsed de ${FreemiumService.maxFreeUsesPerDay} usadas'
                : 'Limite diario atingido',
            style: TextStyle(
              fontSize: 12,
              color: clampedRemaining > 0
                  ? AppColors.textTertiary
                  : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // 4. Weekly activity
  // --------------------------------------------------
  Widget _buildWeeklyActivityCard() {
    return GradientBorderCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.elevatedDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: AppColors.info,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta semana',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_weeklyMessages mensagens',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_totalMessages total',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // 5. Top conversations by message count
  // --------------------------------------------------
  Widget _buildTopConversationsCard() {
    return GradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conversas mais ativas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_topConversations.length, (index) {
            final conv = _topConversations[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _topConversations.length - 1 ? 10 : 0,
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${index + 1}.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: index == 0
                            ? AppColors.primaryCoral
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar
                  _buildAvatar(conv),
                  const SizedBox(width: 12),
                  // Name + platform
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv.name.isNotEmpty ? conv.name : 'Sem nome',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          conv.platform,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Message count
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${conv.totalMessages} msgs',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAvatar(_TopConversation conv) {
    if (conv.faceImageUrl != null && conv.faceImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(conv.faceImageUrl!),
        backgroundColor: AppColors.elevatedDark,
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.elevatedDark,
      child: Text(
        conv.name.isNotEmpty ? conv.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// --------------------------------------------------
// Helper model
// --------------------------------------------------
class _TopConversation {
  final String name;
  final String platform;
  final String? faceImageUrl;
  final int totalMessages;

  _TopConversation({
    required this.name,
    required this.platform,
    this.faceImageUrl,
    required this.totalMessages,
  });
}

// --------------------------------------------------
// CustomPainter for the AI vs Custom usage bar
// --------------------------------------------------
class _UsageBarPainter extends CustomPainter {
  final double aiRatio;

  _UsageBarPainter({required this.aiRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(8);

    // AI portion (left)
    final aiWidth = size.width * aiRatio;
    if (aiWidth > 0) {
      final aiPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.primaryCoral, AppColors.primaryPink],
        ).createShader(Rect.fromLTWH(0, 0, aiWidth, size.height));

      final aiRect = RRect.fromLTRBAndCorners(
        0,
        0,
        aiWidth,
        size.height,
        topLeft: radius,
        bottomLeft: radius,
        topRight: aiRatio >= 1.0 ? radius : Radius.zero,
        bottomRight: aiRatio >= 1.0 ? radius : Radius.zero,
      );
      canvas.drawRRect(aiRect, aiPaint);
    }

    // Custom portion (right)
    final customWidth = size.width - aiWidth;
    if (customWidth > 0) {
      final customPaint = Paint()..color = AppColors.info;

      final customRect = RRect.fromLTRBAndCorners(
        aiWidth,
        0,
        size.width,
        size.height,
        topLeft: aiRatio <= 0.0 ? radius : Radius.zero,
        bottomLeft: aiRatio <= 0.0 ? radius : Radius.zero,
        topRight: radius,
        bottomRight: radius,
      );
      canvas.drawRRect(customRect, customPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _UsageBarPainter oldDelegate) {
    return oldDelegate.aiRatio != aiRatio;
  }
}
