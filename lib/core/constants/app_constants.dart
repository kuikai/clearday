/// App-wide names and free-tier limits for ClearDay.
class AppConstants {
  AppConstants._();

  static const String appName = 'ClearDay';
  static const String appTagline = 'Tasks and chores, kept simple.';
  static const String defaultGroupName = 'Home';

  static const int freeActiveTaskLimit = 25;
  static const int freeGroupLimit = 2;
  static const int freeSubgroupLimit = 3;
  static const int defaultReminderHour = 9;
  static const int defaultEveryNDays = 5;

  static const String defaultProPrice = r'$1.99';
  static const String oneTimePurchaseCopy =
      'One-time purchase • No subscription';
}
