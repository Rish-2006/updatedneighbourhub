// lib/screens/neighbours/neighbours_screen.dart
//
// Premium Neighbours Dashboard — modern apartment community directory.
// Displays ALL community members with their connection status.
// Full connection request flow using existing Firebase streams.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/connection_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'connection_requests_screen.dart';
import 'my_neighbours_screen.dart';
import 'neighbour_profile_screen.dart';

class NeighboursScreen extends StatefulWidget {
  const NeighboursScreen({super.key});

  @override
  State<NeighboursScreen> createState() => _NeighboursScreenState();
}

class _NeighboursScreenState extends State<NeighboursScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All'; // All | Connected | Pending | Available

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (_searchCtrl.text != _query) {
        setState(() => _query = _searchCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getAllUsersStream(),
        builder: (context, userSnap) {
          return StreamBuilder<List<String>>(
            stream: firestoreService.getConnectedUserIdsStream(currentUserId),
            builder: (context, connectedSnap) {
              return StreamBuilder<List<ConnectionRequestModel>>(
                stream: firestoreService.getSentRequestsStream(currentUserId),
                builder: (context, sentSnap) {
                  return StreamBuilder<List<ConnectionRequestModel>>(
                    stream: firestoreService.getPendingRequestsStream(currentUserId),
                    builder: (context, pendingSnap) {
                      final allUsers = userSnap.data ?? [];
                      final connectedIds = connectedSnap.data ?? [];
                      final sentRequests = sentSnap.data ?? [];
                      final pendingRequests = pendingSnap.data ?? [];

                      // Exclude the current user — they can't connect to themselves
                      final others = allUsers
                          .where((u) => u.id != currentUserId)
                          .toList();
                      final me = allUsers
                          .where((u) => u.id == currentUserId)
                          .firstOrNull;

                      final isFirstLoad =
                          userSnap.connectionState == ConnectionState.waiting &&
                          !userSnap.hasData;
                      final hasError = userSnap.hasError;

                      if (isFirstLoad) {
                        return const _LoadingState();
                      }
                      if (hasError) {
                        return _ErrorState(onRetry: () => setState(() {}));
                      }

                      return _NeighboursPageBody(
                        allUsers: allUsers,
                        others: others,
                        me: me,
                        currentUserId: currentUserId,
                        connectedIds: connectedIds,
                        sentRequests: sentRequests,
                        pendingRequests: pendingRequests,
                        firestoreService: firestoreService,
                        query: _query,
                        filter: _filter,
                        searchController: _searchCtrl,
                        onFilterChanged: (f) => setState(() => _filter = f),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Full Page Body (single CustomScrollView) ─────────────────────────────────
class _NeighboursPageBody extends StatelessWidget {
  final List<UserModel> allUsers;
  final List<UserModel> others;
  final UserModel? me;
  final String currentUserId;
  final List<String> connectedIds;
  final List<ConnectionRequestModel> sentRequests;
  final List<ConnectionRequestModel> pendingRequests;
  final FirestoreService firestoreService;
  final String query;
  final String filter;
  final TextEditingController searchController;
  final ValueChanged<String> onFilterChanged;

  const _NeighboursPageBody({
    required this.allUsers,
    required this.others,
    required this.me,
    required this.currentUserId,
    required this.connectedIds,
    required this.sentRequests,
    required this.pendingRequests,
    required this.firestoreService,
    required this.query,
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
  });

  String _status(UserModel user) {
    if (connectedIds.contains(user.id)) return 'connected';
    if (sentRequests.any((r) => r.receiverId == user.id)) return 'sent';
    if (pendingRequests.any((r) => r.senderId == user.id)) return 'pending';
    return 'none';
  }

  List<UserModel> get _filtered {
    List<UserModel> list = others;

    // Search
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((u) =>
              u.name.toLowerCase().contains(q) ||
              u.apartment.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q))
          .toList();
    }

    // Filter chip
    switch (filter) {
      case 'Connected':
        list = list.where((u) => connectedIds.contains(u.id)).toList();
        break;
      case 'Pending':
        list = list
            .where((u) =>
                sentRequests.any((r) => r.receiverId == u.id) ||
                pendingRequests.any((r) => r.senderId == u.id))
            .toList();
        break;
      case 'Available':
        list = list.where((u) => _status(u) == 'none').toList();
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final pendingCount = pendingRequests.length;

    return CustomScrollView(
      slivers: [
        // ── App Bar ──────────────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: AppTheme.darkBg,
          surfaceTintColor: Colors.transparent,
          pinned: true,
          floating: false,
          expandedHeight: 200,
          actions: [
            // Notification bell with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConnectionRequestsScreen()),
                  ),
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          pendingCount > 9 ? '9+' : '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _buildHeader(context, pendingCount),
          ),
        ),

        // ── Search Bar (sticky) ────────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _SearchBarDelegate(
            child: Container(
              color: AppTheme.darkBg,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search members by name or flat number…',
                  hintStyle: const TextStyle(color: AppTheme.darkSubtext),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.primaryColor),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppTheme.darkSubtext),
                          onPressed: () => searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),

        // ── Filter Chips ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              scrollDirection: Axis.horizontal,
              children: _buildFilterChips(context),
            ),
          ),
        ),

        // ── Pending requests inline banner ────────────────────────────────
        if (pendingRequests.isNotEmpty)
          SliverToBoxAdapter(
            child: _PendingBanner(
              requests: pendingRequests,
              firestoreService: firestoreService,
            ),
          ),

        // ── Section header: ALL MEMBERS count ─────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  filter == 'All' ? 'ALL MEMBERS' : filter.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppTheme.darkSubtext,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Empty state ───────────────────────────────────────────────────
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyState(filter: filter, query: query),
          ),

        // ── Member cards (all members with status) ────────────────────────
        if (filtered.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final user = filtered[i];
                  final status = _status(user);
                  return _MemberCard(
                    key: ValueKey(user.id),
                    user: user,
                    connectionStatus: status,
                    pendingRequest: pendingRequests
                        .where((r) => r.senderId == user.id)
                        .firstOrNull,
                    sentRequest: sentRequests
                        .where((r) => r.receiverId == user.id)
                        .firstOrNull,
                    currentUser: me,
                    firestoreService: firestoreService,
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildFilterChips(BuildContext context) {
    const labels = ['All', 'Connected', 'Pending', 'Available'];
    return labels.map((label) {
      final isSelected = filter == label;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : AppTheme.darkSubtext,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onFilterChanged(label),
          backgroundColor: AppTheme.darkCard,
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: Colors.black,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.darkBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      );
    }).toList();
  }

  Widget _buildHeader(BuildContext context, int pendingCount) {
    final total = allUsers.length;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1600), Color(0xFF111111)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Neighbours',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Connect with people in your community',
                style: TextStyle(fontSize: 13, color: AppTheme.darkSubtext),
              ),
              const SizedBox(height: 14),
              // 2×2 stats grid
              Row(
                children: [
                  _StatCard(
                    icon: Icons.people_outline_rounded,
                    label: 'Total Members',
                    value: '$total',
                    color: AppTheme.primaryColor,
                    onTap: null,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.handshake_outlined,
                    label: 'Connected',
                    value: '${connectedIds.length}',
                    color: AppTheme.successColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyNeighboursScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.mark_email_unread_outlined,
                    label: 'Requests',
                    value: '$pendingCount',
                    color: pendingCount > 0
                        ? AppTheme.warningColor
                        : AppTheme.darkSubtext,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConnectionRequestsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.darkSubtext,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Persistent Search Bar Delegate ───────────────────────────────────────────
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _SearchBarDelegate({required this.child});

  @override
  double get minExtent => 62;
  @override
  double get maxExtent => 62;
  @override
  Widget build(context, shrinkOffset, overlapsContent) => child;
  @override
  bool shouldRebuild(_SearchBarDelegate old) => old.child != child;
}

// ─── Pending Requests Banner ──────────────────────────────────────────────────
class _PendingBanner extends StatelessWidget {
  final List<ConnectionRequestModel> requests;
  final FirestoreService firestoreService;

  const _PendingBanner({
    required this.requests,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  color: AppTheme.warningColor, size: 15),
              const SizedBox(width: 8),
              Text(
                '${requests.length} incoming connection request${requests.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...requests.take(2).map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _TinyAvatar(name: req.senderName),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${req.senderName} wants to connect',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TinyBtn(
                      label: 'Accept',
                      color: AppTheme.successColor,
                      onTap: () async {
                        await firestoreService.acceptConnectionRequest(req);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('Connected with ${req.senderName}! 🎉'),
                            backgroundColor: AppTheme.successColor,
                          ));
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    _TinyBtn(
                      label: 'Decline',
                      color: AppTheme.errorColor,
                      outlined: true,
                      onTap: () async {
                        await firestoreService.rejectConnectionRequest(req.id);
                      },
                    ),
                  ],
                ),
              )),
          if (requests.length > 2)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ConnectionRequestsScreen()),
              ),
              child: Text(
                'View all ${requests.length} requests →',
                style: const TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TinyAvatar extends StatelessWidget {
  final String name;
  const _TinyAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TinyBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _TinyBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Member Card ──────────────────────────────────────────────────────────────
class _MemberCard extends StatefulWidget {
  final UserModel user;
  final String connectionStatus;
  final ConnectionRequestModel? pendingRequest;
  final ConnectionRequestModel? sentRequest;
  final UserModel? currentUser;
  final FirestoreService firestoreService;

  const _MemberCard({
    super.key,
    required this.user,
    required this.connectionStatus,
    required this.currentUser,
    required this.firestoreService,
    this.pendingRequest,
    this.sentRequest,
  });

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _isActing = false;

  String get _initials {
    final parts = widget.user.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.user.name.isNotEmpty
        ? widget.user.name[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final status = widget.connectionStatus;
    final hasPhoto = user.photoUrl.isNotEmpty;

    // Border color by status
    Color borderColor;
    switch (status) {
      case 'connected':
        borderColor = AppTheme.successColor.withValues(alpha: 0.35);
        break;
      case 'pending':
        borderColor = AppTheme.warningColor.withValues(alpha: 0.35);
        break;
      default:
        borderColor = AppTheme.darkBorder;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openProfile(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Avatar ───────────────────────────────────────────────
                _buildAvatar(hasPhoto, status),
                const SizedBox(width: 14),

                // ── Name + Flat + Status badge ────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.apartment.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_outlined,
                                size: 12, color: AppTheme.darkSubtext),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.apartment,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.darkSubtext,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 5),
                      _StatusBadge(status: status),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // ── Action ────────────────────────────────────────────────
                _buildAction(context, status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool hasPhoto, String status) {
    Color avatarBg;
    Color avatarBorder;
    switch (status) {
      case 'connected':
        avatarBg = AppTheme.successColor.withValues(alpha: 0.12);
        avatarBorder = AppTheme.successColor.withValues(alpha: 0.35);
        break;
      case 'pending':
        avatarBg = AppTheme.warningColor.withValues(alpha: 0.12);
        avatarBorder = AppTheme.warningColor.withValues(alpha: 0.35);
        break;
      default:
        avatarBg = AppTheme.primaryColor.withValues(alpha: 0.12);
        avatarBorder = AppTheme.primaryColor.withValues(alpha: 0.3);
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: avatarBg,
        shape: BoxShape.circle,
        border: Border.all(color: avatarBorder),
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.network(
                widget.user.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildInitials(status),
              ),
            )
          : _buildInitials(status),
    );
  }

  Widget _buildInitials(String status) {
    Color textColor;
    switch (status) {
      case 'connected':
        textColor = AppTheme.successColor;
        break;
      case 'pending':
        textColor = AppTheme.warningColor;
        break;
      default:
        textColor = AppTheme.primaryColor;
    }
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, String status) {
    if (_isActing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            color: AppTheme.primaryColor, strokeWidth: 2),
      );
    }
    switch (status) {
      case 'connected':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Chip(
              label: '✓ Connected',
              color: AppTheme.successColor,
              filled: false,
              onTap: () => _openProfile(context),
            ),
            const SizedBox(height: 5),
            _Chip(
              label: 'Disconnect',
              color: AppTheme.errorColor,
              filled: false,
              onTap: () => _disconnect(context),
            ),
          ],
        );
      case 'sent':
        return _Chip(
          label: 'Sent',
          color: AppTheme.darkSubtext,
          filled: false,
          onTap: null,
        );
      case 'pending':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Chip(
              label: 'Accept',
              color: AppTheme.successColor,
              filled: true,
              onTap: () => _accept(context),
            ),
            const SizedBox(height: 5),
            _Chip(
              label: 'Decline',
              color: AppTheme.errorColor,
              filled: false,
              onTap: _decline,
            ),
          ],
        );
      default:
        return _Chip(
          label: '+ Connect',
          color: AppTheme.primaryColor,
          filled: true,
          onTap: () => _sendRequest(context),
        );
    }
  }

  Future<void> _sendRequest(BuildContext context) async {
    if (widget.currentUser == null) return;
    setState(() => _isActing = true);
    try {
      await widget.firestoreService
          .sendConnectionRequest(widget.currentUser!, widget.user);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Connection request sent to ${widget.user.name} 📨'),
          backgroundColor: AppTheme.darkCard,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _accept(BuildContext context) async {
    if (widget.pendingRequest == null) return;
    setState(() => _isActing = true);
    try {
      await widget.firestoreService
          .acceptConnectionRequest(widget.pendingRequest!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Connected with ${widget.user.name}! 🎉'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _decline() async {
    if (widget.pendingRequest == null) return;
    setState(() => _isActing = true);
    try {
      await widget.firestoreService
          .rejectConnectionRequest(widget.pendingRequest!.id);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _disconnect(BuildContext context) async {
    final currentUserId = widget.currentUser?.id;
    if (currentUserId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.darkBorder),
        ),
        title: Text(
          'Disconnect from ${widget.user.name}?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'You will no longer be connected with this neighbour.',
          style: TextStyle(color: AppTheme.darkSubtext, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.darkSubtext,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Disconnect',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActing = true);
    try {
      await widget.firestoreService.disconnectUser(
        currentUserId,
        widget.user.id,
      );
      // The Firestore stream automatically updates the UI.
      // Show snackbar feedback.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Disconnected from ${widget.user.name}'),
          backgroundColor: AppTheme.darkCard,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NeighbourProfileScreen(
          neighbour: widget.user,
          connectionStatus: widget.connectionStatus,
          pendingRequest: widget.pendingRequest,
          currentUser: widget.currentUser,
          firestoreService: widget.firestoreService,
        ),
      ),
    );
  }
}

// ─── Action Chip ──────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _Chip({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.14) : Colors.transparent,
          border: Border.all(
              color: onTap == null
                  ? color.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap == null ? color.withValues(alpha: 0.5) : color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'connected':
        color = AppTheme.successColor;
        label = 'Connected';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'sent':
        color = AppTheme.darkSubtext;
        label = 'Request Sent';
        icon = Icons.schedule_rounded;
        break;
      case 'pending':
        color = AppTheme.warningColor;
        label = 'Wants to Connect';
        icon = Icons.person_add_outlined;
        break;
      default:
        color = AppTheme.infoColor;
        label = 'Available';
        icon = Icons.radio_button_off_rounded;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Loading State ────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
        itemCount: 6,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.darkBorder),
          ),
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppTheme.darkSubtext),
            const SizedBox(height: 16),
            const Text(
              'Unable to load neighbours.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              style: TextStyle(color: AppTheme.darkSubtext, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppTheme.primaryColor),
              label: const Text('Try Again',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  final String query;
  const _EmptyState({required this.filter, required this.query});

  @override
  Widget build(BuildContext context) {
    final isSearch = query.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size: 64,
            color: AppTheme.darkSubtext.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? 'No results for "$query"'
                : _emptyTitle(filter),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Try searching with another name or flat number.'
                : _emptySub(filter),
            style: const TextStyle(
                color: AppTheme.darkSubtext, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _emptyTitle(String f) {
    switch (f) {
      case 'Connected': return 'No connections yet';
      case 'Pending': return 'No pending requests';
      case 'Available': return 'No available neighbours';
      default: return 'No neighbours found';
    }
  }

  String _emptySub(String f) {
    switch (f) {
      case 'Connected': return 'Connect with neighbours in your community.';
      case 'Pending': return "You're all caught up!";
      default: return 'Try searching with another name or email.';
    }
  }
}
