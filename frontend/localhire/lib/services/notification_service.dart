import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    await _requestPermissions();
    await _setupFCMHandlers();
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint(" FCM Token: $token");
  }

  static Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _setupFCMHandlers() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(" Foreground: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(" Tapped: ${message.data}");
    });

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(" Launched from notification");
    }
  }

  // ── SAVE FCM TOKEN TO USER DOC ─────────────────────────
  static Future<void> saveTokenToFirestore(String userId) async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .update({"fcmToken": token});
      debugPrint("FCM token saved for $userId");
    }

    // Auto-update token if it refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .update({"fcmToken": newToken});
      debugPrint(" FCM token refreshed for $userId");
    });
  } catch (e) {
    debugPrint("❌ Error saving FCM token: $e");
  }
}

  // ── SAVE NOTIFICATION TO FIRESTORE ────────────────────
  static Future<void> saveNotification({
    required String toUserId,
    required String title,
    required String subtitle,
    required String type,
    required String priority, // "high" or "normal"
    Map<String, dynamic>? data,
  }) async {
    await _db
        .collection("notifications")
        .doc(toUserId)
        .collection("items")
        .add({
      "title": title,
      "subtitle": subtitle,
      "type": type,
      "priority": priority,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
      "data": data ?? {},
    });
  }

  // ── SEND FCM PUSH TO A USER ───────────────────────────
  static Future<void> sendPushNotification({
    required String toUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get recipient's FCM token
      final userDoc = await _db.collection("users").doc(toUserId).get();
      final token = userDoc.data()?["fcmToken"];
      if (token == null) return;

      // Save to Firestore for in-app display
      // (actual FCM push should be sent from your backend/Cloud Function)
      debugPrint("📤 Would send FCM to token: $token");
      debugPrint("📤 Title: $title | Body: $body");

    } catch (e) {
      debugPrint("❌ Error sending notification: $e");
    }
  }

  // ════════════════════════════════════════════════════
  // 1) MESSAGE REQUEST — sender → receiver
  // ════════════════════════════════════════════════════
  static Future<void> sendMessageRequestNotification({
    required String toUserId,
    required String fromUserName,
    required String fromUserId,
  }) async {
    await saveNotification(
      toUserId: toUserId,
      title: "New Message Request",
      subtitle: "$fromUserName wants to connect with you",
      type: "message_request",
      priority: "normal",
      data: {"senderId": fromUserId},
    );
    await sendPushNotification(
      toUserId: toUserId,
      title: "New Message Request",
      body: "$fromUserName wants to connect with you",
      data: {"type": "message_request", "senderId": fromUserId},
    );
  }

  // ════════════════════════════════════════════════════
  // 2) REQUEST ACCEPTED — receiver accepts → sender gets notified
  // ════════════════════════════════════════════════════
  static Future<void> sendRequestAcceptedNotification({
    required String toUserId,
    required String acceptedByName,
    required String acceptedByUserId,
  }) async {
    await saveNotification(
      toUserId: toUserId,
      title: "Request Accepted! 🎉",
      subtitle: "$acceptedByName accepted your message request",
      type: "request_accepted",
      priority: "normal",
      data: {"acceptedBy": acceptedByUserId},
    );
    await sendPushNotification(
      toUserId: toUserId,
      title: "Request Accepted! 🎉",
      body: "$acceptedByName accepted your message request",
      data: {"type": "request_accepted"},
    );
  }

  // ════════════════════════════════════════════════════
  // 3) INSTANT JOB — notify users within 100km (HIGH)
  //                  notify rest (NORMAL)
  // ════════════════════════════════════════════════════
  static Future<void> sendInstantJobNotifications({
    required String jobTitle,
    required String jobLocation,
    required String jobId,
    required double jobLat,
    required double jobLng,
  }) async {
    // Get all users with FCM tokens
    final usersSnapshot = await _db.collection("users").get();

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      final userId = userDoc.id;
      final geo = data["locationGeoPoint"];

      if (geo == null || geo is! GeoPoint) continue;

      // Calculate distance
      final double distance = _calculateDistance(
        jobLat, jobLng,
        geo.latitude, geo.longitude,
      );

      final bool isNearby = distance <= 100; // within 100km

      await saveNotification(
        toUserId: userId,
        title: isNearby
            ? "⚡ Instant Job Nearby!"
            : "New Job Available",
        subtitle: isNearby
            ? "$jobTitle needed now in $jobLocation"
            : "$jobTitle available in $jobLocation",
        type: "instant_job",
        priority: isNearby ? "high" : "normal",
        data: {"jobId": jobId, "distance": distance.round()},
      );
    }

    debugPrint("✅ Instant job notifications sent");
  }

  // ── HAVERSINE DISTANCE FORMULA (km) ──────────────────
  static double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);
    final double a = (dLat / 2) * (dLat / 2) +
        _toRad(lat1) * _toRad(lat2) * (dLng / 2) * (dLng / 2);
    final double c = 2 * (a < 1 ? a : 1);
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * 3.141592653589793 / 180;
}