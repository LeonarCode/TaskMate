import 'package:flutter/material.dart';
import '../../core/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: isDark ? AppColors.gray600 : AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'No new notifications',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.gray400 : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
