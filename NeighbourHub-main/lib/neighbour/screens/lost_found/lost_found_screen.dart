// lib/screens/lost_found/lost_found_screen.dart
//
// Lost & Found section with Lost and Found tabs.
// Full claim/tip workflow using the existing notification system.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import '../../models/lost_found_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

// ─── Status colors & labels ────────────────────────────────────────────────────
Color _statusColor(String status) {
  switch (status) {
    case 'Active':       return AppTheme.successColor;
    case 'ClaimPending': return AppTheme.warningColor;
    case 'Matched':      return AppTheme.infoColor;
    case 'Returned':     return AppTheme.primaryColor;
    case 'Closed':       return AppTheme.grey600;
    default:             return AppTheme.grey600;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'Active':       return 'ACTIVE';
    case 'ClaimPending': return 'CLAIM PENDING';
    case 'Matched':      return 'MATCHED';
    case 'Returned':     return 'RETURNED ✓';
    case 'Closed':       return 'CLOSED';
    default:             return status.toUpperCase();
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showReportItemDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReportItemSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search_off_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Lost'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.find_in_page_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Found'),
                ],
              ),
            ),
          ],
          labelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.grey600,
        ),
      ),
      body: StreamBuilder<List<LostFoundModel>>(
        stream: context.read<FirestoreService>().getLostFoundItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          final lostItems = all.where((i) => i.type == 'lost').toList();
          final foundItems = all.where((i) => i.type == 'found').toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _LostFoundList(items: lostItems, type: 'lost'),
              _LostFoundList(items: foundItems, type: 'found'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Report Item'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Item List ─────────────────────────────────────────────────────────────────
class _LostFoundList extends StatelessWidget {
  final List<LostFoundModel> items;
  final String type;

  const _LostFoundList({required this.items, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLost = type == 'lost';
    final badgeColor = isLost ? AppTheme.errorColor : AppTheme.successColor;
    final badgeLabel = isLost ? '🔴 LOST' : '🟢 FOUND';

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLost ? Icons.search_off : Icons.find_in_page,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              isLost ? 'No lost items reported' : 'No found items posted',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _LostFoundCard(item: item, badgeColor: badgeColor, badgeLabel: badgeLabel)
            .animate()
            .fadeIn(delay: (index * 60).ms)
            .slideY(begin: 0.08, end: 0);
      },
    );
  }
}

// ─── Item Card ─────────────────────────────────────────────────────────────────
class _LostFoundCard extends StatelessWidget {
  final LostFoundModel item;
  final Color badgeColor;
  final String badgeLabel;

  const _LostFoundCard({
    required this.item,
    required this.badgeColor,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';
    final isOwner = item.postedById == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _LostFoundDetailScreen(item: item)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ───────────────────────────────────────────────
              Row(
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(item.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(item.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(item.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeago.format(item.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Title & category ─────────────────────────────────────────
              Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: item.isResolved ? TextDecoration.lineThrough : null,
                ),
              ),
              if (item.category.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // ── Location / poster ────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.grey600),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      item.location,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.grey600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.grey600),
                  const SizedBox(width: 3),
                  Text(
                    'By ${item.postedBy}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.grey600),
                  ),
                ],
              ),
              // ── Action button ────────────────────────────────────────────
              if (!item.isResolved && item.status != 'ClaimPending') ...[
                const SizedBox(height: 12),
                if (isOwner)
                  // Owner sees pending claims button
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => _LostFoundDetailScreen(item: item)),
                    ),
                    icon: const Icon(Icons.inbox_outlined, size: 16),
                    label: const Text('View Claims'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _showClaimSheet(context, item),
                    icon: Icon(
                      item.type == 'found' ? Icons.assignment_outlined : Icons.location_on_outlined,
                      size: 16,
                    ),
                    label: Text(item.type == 'found' ? 'Claim This Item' : 'I Found This'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: badgeColor,
                      side: BorderSide(color: badgeColor),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showClaimSheet(BuildContext context, LostFoundModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClaimSheet(item: item),
    );
  }
}

// ─── Report Item Bottom Sheet ─────────────────────────────────────────────────
class _ReportItemSheet extends StatefulWidget {
  const _ReportItemSheet();

  @override
  State<_ReportItemSheet> createState() => _ReportItemSheetState();
}

class _ReportItemSheetState extends State<_ReportItemSheet> {
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String _itemType = 'lost';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    final user = context.read<AuthService>().currentUser;
    final item = LostFoundModel(
      id: const Uuid().v4(),
      type: _itemType,
      title: _titleCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      postedBy: user?.displayName ?? 'Neighbour',
      postedById: user?.uid ?? '',
      createdAt: DateTime.now(),
      status: 'Active',
    );
    try {
      await context.read<FirestoreService>().createLostFoundItem(item);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${_itemType == "lost" ? "Lost" : "Found"} item reported!'),
        backgroundColor: AppTheme.successColor,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.grey400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Report a Lost or Found Item',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            // Type selector
            Row(children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('🔴  Lost'),
                  selected: _itemType == 'lost',
                  selectedColor: AppTheme.errorColor.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.errorColor,
                  onSelected: (_) => setState(() => _itemType = 'lost'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('🟢  Found'),
                  selected: _itemType == 'found',
                  selectedColor: AppTheme.successColor.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.successColor,
                  onSelected: (_) => setState(() => _itemType = 'found'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Item name *', hintText: 'e.g. Black Wallet'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category', hintText: 'e.g. Wallet, Keys, Phone'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Colour, brand, identifying features'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                labelText: _itemType == 'lost' ? 'Location lost' : 'Location found',
                hintText: 'e.g. Block A Parking',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dateCtrl,
              decoration: InputDecoration(
                labelText: _itemType == 'lost' ? 'Date lost' : 'Date found',
                hintText: 'e.g. 3 Oct 2026',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_itemType == 'lost' ? 'Report Lost Item' : 'Post Found Item'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Claim / Found-Tip Bottom Sheet ───────────────────────────────────────────
class _ClaimSheet extends StatefulWidget {
  final LostFoundModel item;
  const _ClaimSheet({required this.item});

  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_locationCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final user = context.read<AuthService>().currentUser;
    final isFoundItem = widget.item.type == 'found';
    try {
      await context.read<FirestoreService>().submitClaim(
        itemId: widget.item.id,
        itemTitle: widget.item.title,
        itemOwnerId: widget.item.postedById,
        claimantId: user?.uid ?? '',
        claimantName: user?.displayName ?? 'Neighbour',
        claimLocation: _locationCtrl.text.trim(),
        claimDescription: _descCtrl.text.trim(),
        claimType: isFoundItem ? 'claim' : 'found_tip',
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isFoundItem
            ? '✅ Claim submitted! The finder has been notified.'
            : '✅ Tip submitted! The owner has been notified.'),
        backgroundColor: AppTheme.successColor,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFoundItem = widget.item.type == 'found';
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.grey400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFoundItem ? 'Claim This Item' : 'I Found This',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '"${widget.item.title}"',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.warningColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFoundItem
                          ? 'To verify ownership, provide a private identifying detail. This will NOT be shown publicly.'
                          : 'Share where and when you found the item. The owner will be notified.',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.warningColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                labelText: isFoundItem ? 'Where did you lose this item? *' : 'Where did you find it? *',
                hintText: isFoundItem ? 'e.g. Block A Parking, near gate' : 'e.g. Near the park bench',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isFoundItem
                    ? 'Private identifying detail about the item *'
                    : 'Description of the item you found *',
                hintText: isFoundItem
                    ? 'e.g. Has a sticker on the back, contains a specific card'
                    : 'e.g. Black leather wallet, worn corners',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _extraCtrl,
              decoration: const InputDecoration(
                labelText: 'Additional information (optional)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isFoundItem ? 'Submit Claim' : 'Submit Tip'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Item Detail Screen ────────────────────────────────────────────────────────
class _LostFoundDetailScreen extends StatelessWidget {
  final LostFoundModel item;
  const _LostFoundDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';
    final isOwner = item.postedById == currentUserId;
    final isLost = item.type == 'lost';
    final badgeColor = isLost ? AppTheme.errorColor : AppTheme.successColor;

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chips
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLost ? '🔴 LOST' : '🟢 FOUND',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: badgeColor),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(item.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(item.status),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(item.status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(item.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (item.category.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.category, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor)),
            ],
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.description_outlined, label: 'Description', value: item.description),
            _DetailRow(icon: Icons.location_on_outlined, label: isLost ? 'Lost at' : 'Found at', value: item.location),
            if (item.date.isNotEmpty)
              _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date', value: item.date),
            _DetailRow(icon: Icons.person_outline, label: 'Posted by', value: item.postedBy),
            _DetailRow(icon: Icons.access_time_outlined, label: 'Reported', value: timeago.format(item.createdAt)),
            const SizedBox(height: 24),

            // Action buttons
            if (!item.isResolved) ...[
              if (!isOwner && item.status != 'ClaimPending') ...[
                ElevatedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: theme.colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => _ClaimSheet(item: item),
                  ),
                  icon: Icon(isLost ? Icons.location_on_outlined : Icons.assignment_outlined),
                  label: Text(isLost ? 'I Found This' : 'Claim This Item'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: badgeColor,
                  ),
                ),
              ],

              // Owner sees pending claims
              if (isOwner) ...[
                Text('PENDING CLAIMS', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: context.read<FirestoreService>().getClaimsForItem(item.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final claims = snapshot.data ?? [];
                    if (claims.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No pending claims yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: claims.map((claim) => _ClaimCard(
                        claim: claim,
                        item: item,
                      )).toList(),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.grey600),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.grey600)),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClaimCard extends StatefulWidget {
  final Map<String, dynamic> claim;
  final LostFoundModel item;
  const _ClaimCard({required this.claim, required this.item});

  @override
  State<_ClaimCard> createState() => _ClaimCardState();
}

class _ClaimCardState extends State<_ClaimCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await context.read<FirestoreService>().acceptClaim(
        claimId: widget.claim['id'] as String,
        itemId: widget.item.id,
        itemTitle: widget.item.title,
        claimantId: widget.claim['claimantId'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Claim accepted! Item marked as Returned.'), backgroundColor: AppTheme.successColor),
        );
        Navigator.pop(context); // Close detail screen
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    try {
      await context.read<FirestoreService>().rejectClaim(
        claimId: widget.claim['id'] as String,
        itemId: widget.item.id,
        itemTitle: widget.item.title,
        claimantId: widget.claim['claimantId'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim rejected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.claim['claimantName'] as String? ?? 'Unknown',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('📍 ${widget.claim['claimLocation'] ?? '—'}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            Text('📝 ${widget.claim['claimDescription'] ?? '—'}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reject,
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor, side: const BorderSide(color: AppTheme.errorColor)),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _accept,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
