import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/server_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_button.dart';
import 'server_detail_screen.dart';

class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    final firestoreSvc = FirestoreService();

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
      appBar: AppBar(
        title: const Text('Servers'),
        backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.purple600,
          unselectedLabelColor: isDark ? AppColors.gray500 : AppColors.gray400,
          indicatorColor: AppColors.purple600,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: const [Tab(text: 'My Servers'), Tab(text: 'Discover')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateServer(context, uid, firestoreSvc),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _MyServersTab(
                  uid: uid,
                  search: _search,
                  firestoreSvc: firestoreSvc,
                ),
                _DiscoverTab(
                  uid: uid,
                  search: _search,
                  firestoreSvc: firestoreSvc,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _search = v.toLowerCase()),
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.gray900,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search servers...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.purple600,
          ),
          suffixIcon:
              _search.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                  )
                  : null,
        ),
      ),
    );
  }

  void _showCreateServer(BuildContext ctx, String uid, FirestoreService svc) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateServerSheet(uid: uid, firestoreSvc: svc),
    );
  }
}

// ── My Servers Tab ─────────────────────────────────────────────────────────────
class _MyServersTab extends StatelessWidget {
  final String uid;
  final String search;
  final FirestoreService firestoreSvc;

  const _MyServersTab({
    required this.uid,
    required this.search,
    required this.firestoreSvc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<ServerModel>>(
      stream: firestoreSvc.userServersStream(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple600),
            ),
          );
        }
        final servers =
            (snap.data ?? [])
                .where(
                  (s) =>
                      search.isEmpty || s.name.toLowerCase().contains(search),
                )
                .toList();
        if (servers.isEmpty) {
          return _EmptyServers(
            message:
                "You haven't joined any servers yet.\nTap + to create one!",
            isDark: isDark,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: servers.length,
          itemBuilder:
              (_, i) => _ServerListTile(
                server: servers[i],
                uid: uid,
                firestoreSvc: firestoreSvc,
              ),
        );
      },
    );
  }
}

// ── Discover Tab ───────────────────────────────────────────────────────────────
class _DiscoverTab extends StatelessWidget {
  final String uid;
  final String search;
  final FirestoreService firestoreSvc;

  const _DiscoverTab({
    required this.uid,
    required this.search,
    required this.firestoreSvc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<ServerModel>>(
      stream: firestoreSvc.publicServersStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple600),
            ),
          );
        }
        final servers =
            (snap.data ?? [])
                .where(
                  (s) =>
                      search.isEmpty || s.name.toLowerCase().contains(search),
                )
                .toList();
        if (servers.isEmpty) {
          return _EmptyServers(
            message: 'No servers available yet.\nBe the first to create one!',
            isDark: isDark,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: servers.length,
          itemBuilder:
              (_, i) => _ServerListTile(
                server: servers[i],
                uid: uid,
                firestoreSvc: firestoreSvc,
              ),
        );
      },
    );
  }
}

// ── Server List Tile ───────────────────────────────────────────────────────────
class _ServerListTile extends StatelessWidget {
  final ServerModel server;
  final String uid;
  final FirestoreService firestoreSvc;

  const _ServerListTile({
    required this.server,
    required this.uid,
    required this.firestoreSvc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMember = server.memberIds.contains(uid);
    final color = Color(server.iconColorValue);

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServerDetailScreen(server: server, uid: uid),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              isDark ? Border.all(color: AppColors.dark600, width: 1) : null,
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withAlpha(80), width: 1.5),
              ),
              child: Center(
                child: Text(
                  server.iconEmoji ??
                      server.name.characters.first.toUpperCase(),
                  style: TextStyle(
                    fontSize: server.iconEmoji != null ? 26 : 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.gray900,
                    ),
                  ),
                  if (server.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      server.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.gray400 : AppColors.gray500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 13,
                        color: isDark ? AppColors.gray500 : AppColors.gray400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${server.memberCount} member${server.memberCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.gray500 : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isMember)
              GestureDetector(
                onTap: () async {
                  await firestoreSvc.joinServer(server.id, uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Joined ${server.name}!')),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Join',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.gray500 : AppColors.gray400,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyServers extends StatelessWidget {
  final String message;
  final bool isDark;

  const _EmptyServers({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.purple600.withAlpha(15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.dns_rounded,
                size: 40,
                color: AppColors.purple600.withAlpha(150),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.gray400 : AppColors.gray500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Server Sheet ────────────────────────────────────────────────────────
class _CreateServerSheet extends StatefulWidget {
  final String uid;
  final FirestoreService firestoreSvc;

  const _CreateServerSheet({required this.uid, required this.firestoreSvc});

  @override
  State<_CreateServerSheet> createState() => _CreateServerSheetState();
}

class _CreateServerSheetState extends State<_CreateServerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _colorValue = 0xFF7C3AED;
  String _emoji = '🌐';
  bool _saving = false;

  final _colors = [
    0xFF7C3AED,
    0xFFEC4899,
    0xFF22C55E,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF3B82F6,
  ];
  final _emojis = ['🌐', '📚', '💻', '🎯', '🚀', '🎨', '📊', '🔬', '🏆', '💡'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final server = ServerModel(
      id: '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      ownerId: widget.uid,
      memberIds: [widget.uid],
      iconColorValue: _colorValue,
      iconEmoji: _emoji,
      createdAt: DateTime.now(),
      memberCount: 1,
    );

    await widget.firestoreSvc.createServer(server);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark800 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.dark500 : AppColors.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Create Server 🌐',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.gray900,
                ),
              ),
              const SizedBox(height: 20),
              // Name
              _fieldLabel('Server Name', isDark),
              const SizedBox(height: 7),
              TextFormField(
                controller: _nameCtrl,
                validator:
                    (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                decoration: const InputDecoration(
                  hintText: 'My Awesome Server',
                  prefixIcon: Icon(
                    Icons.dns_rounded,
                    color: AppColors.purple600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Description (optional)', isDark),
              const SizedBox(height: 7),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'What is this server about?',
                  prefixIcon: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.gray400,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Pick Color', isDark),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children:
                    _colors.map((c) {
                      final selected = _colorValue == c;
                      return GestureDetector(
                        onTap: () => setState(() => _colorValue = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  selected ? Colors.white : Colors.transparent,
                              width: selected ? 3 : 0,
                            ),
                            boxShadow:
                                selected
                                    ? [
                                      BoxShadow(
                                        color: Color(c).withAlpha(100),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                    : null,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Pick Emoji', isDark),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _emojis.map((e) {
                      final selected = _emoji == e;
                      return GestureDetector(
                        onTap: () => setState(() => _emoji = e),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? AppColors.purple600.withAlpha(20)
                                    : (isDark
                                        ? AppColors.dark700
                                        : AppColors.gray50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  selected
                                      ? AppColors.purple600
                                      : (isDark
                                          ? AppColors.dark500
                                          : AppColors.gray200),
                              width: selected ? 2 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: _saving ? 'Creating...' : 'Create Server',
                icon: Icons.rocket_launch_rounded,
                onTap: _saving ? null : _create,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, bool isDark) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.gray200 : AppColors.gray700,
    ),
  );
}
