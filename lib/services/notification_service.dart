import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for handling push notifications for trip assignments and updates
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Function(String?)? _onNotificationTap;

  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_isInitialized) return;

    _onNotificationTap = onNotificationTap;

    // Android initialization settings
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request permissions on iOS
    await _requestPermissions();

    _isInitialized = true;
    debugPrint('NotificationService: Initialized');
  }

  Future<void> _requestPermissions() async {
    // Request iOS permissions
    await _notifications
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

    // Request Android 13+ permissions
    await _notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('NotificationService: Notification tapped - ${response.payload}');
    _onNotificationTap?.call(response.payload);
  }

  /// Show a notification for a new trip assignment
  Future<void> showTripAssignedNotification({
    required String tripId,
    required String pickupAddress,
    required String pickupTime,
    String? memberName,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationService: Not initialized, skipping notification');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'trip_assignments',
      'Trip Assignments',
      channelDescription: 'Notifications for new trip assignments',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = 'New Trip Assigned';
    final body = memberName != null
      ? 'Pickup $memberName at $pickupTime\n$pickupAddress'
      : 'Pickup at $pickupTime\n$pickupAddress';

    await _notifications.show(
      tripId.hashCode, // Use tripId hash as notification ID
      title,
      body,
      details,
      payload: tripId,
    );

    debugPrint('NotificationService: Trip notification shown for $tripId');
  }

  /// Show a notification for trip status update
  Future<void> showTripUpdateNotification({
    required String tripId,
    required String title,
    required String message,
  }) async {
    if (!_isInitialized) return;

    final androidDetails = AndroidNotificationDetails(
      'trip_updates',
      'Trip Updates',
      channelDescription: 'Notifications for trip status updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      tripId.hashCode + 1000, // Different ID from assignment notification
      title,
      message,
      details,
      payload: tripId,
    );
  }

  /// Show a notification for trip cancellation
  Future<void> showTripCancelledNotification({
    required String tripId,
    String? pickupAddress,
    String? pickupTime,
  }) async {
    if (!_isInitialized) return;

    final androidDetails = AndroidNotificationDetails(
      'trip_cancellations',
      'Trip Cancellations',
      channelDescription: 'Notifications for cancelled trips',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      color: const Color.fromARGB(255, 239, 68, 68), // Red color
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = pickupAddress != null && pickupTime != null
      ? 'Trip to $pickupAddress at $pickupTime has been cancelled'
      : 'A scheduled trip has been cancelled';

    await _notifications.show(
      tripId.hashCode + 2000,
      'Trip Cancelled',
      body,
      details,
      payload: tripId,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(String tripId) async {
    await _notifications.cancel(tripId.hashCode);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }
}
