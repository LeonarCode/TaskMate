import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../models/rating_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple600),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, isDark, user, auth),
          SliverToBoxAdapter(child: _buildBody(context, isDark, user, auth)),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext ctx, bool isDark, UserModel user, AuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: isDark ? AppColors.dark800 : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [AppColors.dark800, AppColors.dark700],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : LinearGradient(
                    colors: [
                      AppColors.purple600,
                      AppColors.pink500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withAlpha(40),
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.fullName.characters.first.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    GestureDetector(
                      onTap: () => _changePhoto(ctx, user),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 18, color: AppColors.purple600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(180),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RatingBarIndicator(
                      rating: user.averageRating,
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star_rounded, color: AppColors.amber400),
                      itemCount: 5,
                      itemSize: 20,
                      unratedColor: Colors.white.withAlpha(80),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${user.averageRating.toStringAsFixed(1)} (${user.ratingCount})',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(200),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.white : AppColors.gray700),
          onPressed: () => ctx.read<ThemeProvider>().toggleTheme(),
        ),
        IconButton(
          icon: Icon(Icons.logout_rounded,
              color: isDark ? Colors.white : AppColors.gray700),
          onPressed: () => _confirmSignOut(ctx, auth),
        ),
      ],
    );
  }

  Widget _buildBody(
      BuildContext ctx, bool isDark, UserModel user, AuthProvider auth) {
    final firestoreSvc = FirestoreService();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          _sectionTitle('Profile Info', isDark),
          const SizedBox(height: 10),
          _infoCard(isDark, [
            _InfoRow(
              icon: Icons.person_rounded,
              label: 'Full Name',
              value: user.fullName,
              color: AppColors.purple600,
            ),
            _InfoRow(
              icon: Icons.alternate_email_rounded,
              label: 'Username',
              value: '@${user.username}',
              color: AppColors.pink500,
            ),
            _InfoRow(
              icon: Icons.cake_rounded,
              label: 'Age',
              value: '${user.age} years old',
              color: AppColors.amber500,
            ),
            _InfoRow(
              icon: user.userType == UserType.student
                  ? Icons.school_rounded
                  : Icons.work_rounded,
              label: 'Type',
              value: user.userType == UserType.student
                  ? '🎓 Student'
                  : '💼 Employee',
              color: AppColors.green500,
            ),
            _InfoRow(
              icon: Icons.mail_rounded,
              label: 'Email',
              value: user.email,
              color: AppColors.purple400,
            ),
          ]),
          const SizedBox(height: 24),

          // Ratings received
          _sectionTitle('Ratings & Feedback', isDark),
          const SizedBox(height: 10),
          StreamBuilder<List<RatingModel>>(
            stream: firestoreSvc.userRatingsStream(user.uid),
            builder: (_, snap) {
              final ratings = snap.data ?? [];
              if (ratings.isEmpty) {
                return _emptySection(
                    'No ratings yet', Icons.star_border_rounded, isDark);
              }
              return Column(
                children: ratings
                    .take(5)
                    .map((r) => _RatingTile(rating: r, isDark: isDark))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Edit profile button
          GradientButton(
            label: 'Edit Profile',
            icon: Icons.edit_rounded,
            onTap: () => _showEditProfile(ctx, user, auth),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppColors.gray900,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _infoCard(bool isDark, List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: AppColors.dark600, width: 1)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 12,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final row = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: row.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(row.icon, color: row.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.gray500
                                : AppColors.gray400,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          row.value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppColors.gray800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color:
                      isDark ? AppColors.dark600 : AppColors.gray100,
                  indent: 64,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _emptySection(String msg, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: AppColors.dark600, width: 1)
            : null,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: isDark ? AppColors.gray600 : AppColors.gray300),
            const SizedBox(height: 8),
            Text(
              msg,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.gray500 : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePhoto(BuildContext ctx, UserModel user) async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file == null) return;
    // TODO: upload to Firebase Storage and update photoUrl
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Photo update coming soon!')),
      );
    }
  }

  void _confirmSignOut(BuildContext ctx, AuthProvider auth) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.red500),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(
      BuildContext ctx, UserModel user, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final ageCtrl = TextEditingController(text: '${user.age}');
    UserType userType = user.userType;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) {
        final isDark = Theme.of(bCtx).brightness == Brightness.dark;
        return StatefulBuilder(builder: (bCtx, setSheetState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24 + MediaQuery.of(bCtx).viewInsets.bottom),
            decoration: BoxDecoration(
              color: isDark ? AppColors.dark800 : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
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
                        color: isDark
                            ? AppColors.dark500
                            : AppColors.gray200,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge_rounded,
                        color: AppColors.purple600),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_rounded,
                        color: AppColors.amber500),
                  ),
                ),
                const SizedBox(height: 16),
                Text('User Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.gray200 : AppColors.gray700,
                    )),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setSheetState(() => userType = UserType.student),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: userType == UserType.student
                              ? AppColors.primaryGradient
                              : null,
                          color: userType == UserType.student
                              ? null
                              : (isDark
                                  ? AppColors.dark700
                                  : AppColors.gray50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: userType == UserType.student
                                ? AppColors.purple600
                                : (isDark
                                    ? AppColors.dark500
                                    : AppColors.gray200),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '🎓 Student',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: userType == UserType.student
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.gray400
                                      : AppColors.gray600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setSheetState(() => userType = UserType.employee),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: userType == UserType.employee
                              ? AppColors.primaryGradient
                              : null,
                          color: userType == UserType.employee
                              ? null
                              : (isDark
                                  ? AppColors.dark700
                                  : AppColors.gray50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: userType == UserType.employee
                                ? AppColors.purple600
                                : (isDark
                                    ? AppColors.dark500
                                    : AppColors.gray200),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '💼 Employee',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: userType == UserType.employee
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.gray400
                                      : AppColors.gray600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Save Changes',
                  icon: Icons.save_rounded,
                  onTap: () async {
                    final age = int.tryParse(ageCtrl.text.trim()) ?? user.age;
                    final name = nameCtrl.text.trim();
                    await FirestoreService().updateUser(user.uid, {
                      'age': age,
                      'fullName': name,
                      'userType': userType.name,
                    });
                    await auth.refreshUser();
                    if (bCtx.mounted) Navigator.pop(bCtx);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Profile updated!')),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _RatingTile extends StatelessWidget {
  final RatingModel rating;
  final bool isDark;

  const _RatingTile({required this.rating, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark800 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? Border.all(color: AppColors.dark600, width: 1)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rating.fromName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.gray900,
                  ),
                ),
              ),
              RatingBarIndicator(
                rating: rating.score,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star_rounded, color: AppColors.amber400),
                itemCount: 5,
                itemSize: 16,
                unratedColor:
                    isDark ? AppColors.dark500 : AppColors.gray200,
              ),
            ],
          ),
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${rating.comment}"',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.gray400 : AppColors.gray500,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'From ${rating.serverName}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.purple600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
