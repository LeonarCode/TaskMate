import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/server_model.dart';

class ServerDetailScreen extends StatelessWidget {
  final ServerModel server;
  final String uid;

  const ServerDetailScreen({
    super.key,
    required this.server,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
      appBar: AppBar(
        title: Text(server.name),
        backgroundColor: isDark ? AppColors.dark900 : AppColors.gray50,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              server.iconEmoji ?? server.name.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to ${server.name}!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.gray900,
              ),
            ),
            if (server.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                server.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
