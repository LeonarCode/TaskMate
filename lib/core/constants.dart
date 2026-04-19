// App-wide constants
class AppStrings {
  AppStrings._();

  static const appName = 'TaskMate';
  static const tagline = 'Your smart productivity mate 🚀';

  // Routes
  static const routeSplash = '/';
  static const routeAuth = '/auth';
  static const routeProfile = '/profile-setup';
  static const routeHome = '/home';
  static const routeTasks = '/tasks';
  static const routeAddTask = '/tasks/add';
  static const routeServers = '/servers';
  static const routeServerDetail = '/servers/:id';
  static const routeChats = '/chats';
  static const routeChatDetail = '/chats/:id';
  static const routeNotifications = '/notifications';
  static const routeMyProfile = '/my-profile';

  // Firestore collections
  static const colUsers = 'users';
  static const colTasks = 'tasks';
  static const colServers = 'servers';
  static const colMessages = 'messages';
  static const colServerTasks = 'server_tasks';
  static const colDMs = 'dms';
  static const colRatings = 'ratings';
  static const colNotifications = 'notifications';

  // SQLite
  static const dbName = 'taskmate.db';
  static const tablePersonalTasks = 'personal_tasks';

  // Shared prefs keys
  static const prefThemeMode = 'theme_mode';
  static const prefOnboarded = 'onboarded';
}

class AppDurations {
  AppDurations._();
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 600);
  static const splash = Duration(seconds: 2);
}

enum UserType { student, employee }

enum TaskPriority { low, medium, high }

enum NotifType { message, taskDeadline, serverActivity, taskReminder }
