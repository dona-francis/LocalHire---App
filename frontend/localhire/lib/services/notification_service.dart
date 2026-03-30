import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Single token-refresh listener guard ───────────────
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String? _currentUserId;

  // ════════════════════════════════════════════════════
  // INITIALIZE — call once at app start (before login)
  // ════════════════════════════════════════════════════
  static Future<void> initialize() async {
    await _requestPermissions();
    _setupFCMHandlers();
    // Token is only printed here; saving happens after login in saveTokenToFirestore()
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint("📱 FCM Token on init: $token");
  }

  static Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static void _setupFCMHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("🔔 Foreground: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("👆 Tapped: ${message.data}");
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint("🚀 Launched from notification: ${message.data}");
      }
    });
  }
  static Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null) {
        debugPrint("⚠️ FCM token is null for $userId — skipping save");
        return;
      }

      // FIX #1: set+merge never fails silently unlike update()
      await _db
          .collection("users")
          .doc(userId)
          .set({"fcmToken": token}, SetOptions(merge: true));

      debugPrint("✅ FCM token saved for $userId");

      // FIX #3: Cancel previous listener before registering a new one.
      // Without this, every login stacks a new listener → multiple simultaneous writes.
      if (_currentUserId != userId) {
        await _tokenRefreshSubscription?.cancel();
        _currentUserId = userId;

        _tokenRefreshSubscription =
            FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          try {
            await _db
                .collection("users")
                .doc(userId)
                .set({"fcmToken": newToken}, SetOptions(merge: true));
            debugPrint("🔄 FCM token refreshed for $userId");
          } catch (e) {
            debugPrint("❌ Error refreshing FCM token: $e");
          }
        });
      }
    } catch (e) {
      debugPrint("❌ Error saving FCM token: $e");
    }
  }

  // ════════════════════════════════════════════════════
  // CLEAR TOKEN ON LOGOUT — call when user logs out
  // ════════════════════════════════════════════════════
  static Future<void> clearTokenOnLogout(String userId) async {
    try {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      _currentUserId = null;

      await _db
          .collection("users")
          .doc(userId)
          .set({"fcmToken": FieldValue.delete()}, SetOptions(merge: true));

      debugPrint("🗑️ FCM token cleared for $userId");
    } catch (e) {
      debugPrint("❌ Error clearing FCM token: $e");
    }
  }

  // ════════════════════════════════════════════════════
  // SAVE NOTIFICATION TO FIRESTORE
  // ════════════════════════════════════════════════════
  static Future<void> saveNotification({
    required String toUserId,
    required String title,
    required String subtitle,
    required String type,
    required String priority,
    Map<String, dynamic>? data,
  }) async {
    try {
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
    } catch (e) {
      debugPrint("❌ Error saving notification for $toUserId: $e");
    }
  }

  // ════════════════════════════════════════════════════
  // SEND FCM PUSH TO A USER
  // ════════════════════════════════════════════════════
  static Future<void> sendPushNotification({
    required String toUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await _db.collection("users").doc(toUserId).get();
      final token = userDoc.data()?["fcmToken"];

      if (token == null) {
        debugPrint("⚠️ No FCM token for $toUserId — skipping push");
        return;
      }

      // NOTE: Direct FCM sends must go through your Cloud Functions / backend.
      // This logs intent; actual delivery is handled server-side.
      debugPrint("📤 Push queued → $toUserId | $title: $body");
    } catch (e) {
      debugPrint("❌ Error sending push to $toUserId: $e");
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
    const title = "New Message Request";
    final body = "$fromUserName wants to connect with you";

    await Future.wait([
      saveNotification(
        toUserId: toUserId,
        title: title,
        subtitle: body,
        type: "message_request",
        priority: "normal",
        data: {"senderId": fromUserId},
      ),
      sendPushNotification(
        toUserId: toUserId,
        title: title,
        body: body,
        data: {"type": "message_request", "senderId": fromUserId},
      ),
    ]);
  }

  // ════════════════════════════════════════════════════
  // 2) REQUEST ACCEPTED — receiver accepts → sender notified
  // ════════════════════════════════════════════════════
  static Future<void> sendRequestAcceptedNotification({
    required String toUserId,
    required String acceptedByName,
    required String acceptedByUserId,
  }) async {
    const title = "Request Accepted! 🎉";
    final body = "$acceptedByName accepted your message request";

    await Future.wait([
      saveNotification(
        toUserId: toUserId,
        title: title,
        subtitle: body,
        type: "request_accepted",
        priority: "normal",
        data: {"acceptedBy": acceptedByUserId},
      ),
      sendPushNotification(
        toUserId: toUserId,
        title: title,
        body: body,
        data: {"type": "request_accepted", "acceptedBy": acceptedByUserId},
      ),
    ]);
  }
  static Future<void> sendInstantJobNotifications({
    required String jobTitle,
    required String jobLocation,
    required String jobId,
    required double jobLat,
    required double jobLng,
  }) async {
    try {
      final usersSnapshot = await _db.collection("users").get();

      int sent = 0;
      int skipped = 0;

      // Process users in parallel for performance
      await Future.wait(usersSnapshot.docs.map((userDoc) async {
        final data = userDoc.data();
        final userId = userDoc.id;
        final geo = data["locationGeoPoint"];

        // Skip users with no location set
        if (geo == null || geo is! GeoPoint) {
          debugPrint("⏭️ Skipping $userId — no locationGeoPoint");
          skipped++;
          return;
        }
        final double distance = _calculateDistance(
          jobLat, jobLng,
          geo.latitude, geo.longitude,
        );

        final bool isNearby = distance <= 100;
        final String title = isNearby ? "⚡ Instant Job Nearby!" : "New Job Available";
        final String body = isNearby
            ? "$jobTitle needed now in $jobLocation"
            : "$jobTitle available in $jobLocation";

        
        await Future.wait([
          saveNotification(
            toUserId: userId,
            title: title,
            subtitle: body,
            type: "instant_job",
            priority: isNearby ? "high" : "normal",
            data: {
              "jobId": jobId,
              "distance": distance.round(),
              "isNearby": isNearby,
            },
          ),
          sendPushNotification(
            toUserId: userId,
            title: title,
            body: body,
            data: {
              "type": "instant_job",
              "jobId": jobId,
              "priority": isNearby ? "high" : "normal",
            },
          ),
        ]);

        sent++;
        debugPrint(
          "📍 $userId → ${distance.toStringAsFixed(1)}km "
          "${isNearby ? '[NEARBY - HIGH]' : '[NORMAL]'}",
        );
      }));

      debugPrint("✅ Instant job done — sent: $sent, skipped (no location): $skipped");
    } catch (e) {
      debugPrint("❌ Error in sendInstantJobNotifications: $e");
    }
  }

  // ════════════════════════════════════════════════════
  // HAVERSINE DISTANCE FORMULA (km)
  static double _calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const double earthRadius = 6371; // km

    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +           // sin²(Δlat/2)
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *    // cos(lat1)·cos(lat2)
        sin(dLng / 2) * sin(dLng / 2);             // sin²(Δlng/2)

    final double c = 2 * asin(sqrt(a));            // 2·asin(√a)

    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * pi / 180; // use dart:math pi constant
}
