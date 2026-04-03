const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ═══════════════════════════════════════════════
// HELPER — Save to Firestore + Send FCM push
// ═══════════════════════════════════════════════
async function sendNotification({
  toUserId, title, body, type, priority, data,
}) {
  try {
    await db
      .collection("notifications")
      .doc(toUserId)
      .collection("items")
      .add({
        title,
        subtitle: body,
        type,
        priority,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data: data || {},
      });

    const userDoc = await db.collection("users").doc(toUserId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) {
      console.log(`⚠️ No FCM token for ${toUserId}`);
      return;
    }

    await messaging.send({
      token,
      notification: { title, body },
      // All keys in FCM data payload must be strings
      data: {
        type,
        ...Object.fromEntries(
          Object.entries(data || {}).map(([k, v]) => [k, String(v)])
        ),
      },
      android: {
        priority: priority === "high" ? "high" : "normal",
        notification: {
          channelId: "high_importance_channel",
          priority: priority === "high" ? "max" : "default",
          sound: "default",
        },
      },
    });

    console.log(`✅ Sent to ${toUserId}: ${title}`);
  } catch (err) {
    console.error(`❌ Error:`, err.message);
  }
}

// ═══════════════════════════════════════════════
// TRIGGER 1 — New Message Request
// Receiver gets notified when someone initiates a chat
// ═══════════════════════════════════════════════
exports.onMessageRequest = onDocumentCreated(
  "chats/{chatId}",
  async (event) => {
    const chat = event.data.data();
    const participants = chat.participants || [];
    if (participants.length < 2) return;

    const senderId = chat.sourceId;
    if (!senderId) return;

    const receiverId = participants.find((id) => id !== senderId);
    if (!receiverId) return;

    const senderName = chat.displayNames?.[receiverId] || "Someone";
    const chatId = event.params.chatId;

    await sendNotification({
      toUserId: receiverId,
      title: "New Message Request 💬",
      body: `${senderName} wants to connect with you`,
      type: "message_request",
      priority: "normal",
      data: {
        senderId,
        senderName,
        chatId,                    // ✅ needed for direct navigation
        otherUserId: senderId,     // ✅ alias for Flutter nav
      },
    });
  }
);

// ═══════════════════════════════════════════════
// TRIGGER 2 — Request Accepted
// Original sender gets notified when receiver accepts
// ═══════════════════════════════════════════════
exports.onRequestAccepted = onDocumentUpdated(
  "chats/{chatId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const acceptedBefore = before.acceptedBy || [];
    const acceptedAfter = after.acceptedBy || [];

    // Only fire when acceptedBy gains a new entry
    if (acceptedAfter.length <= acceptedBefore.length) return;

    const acceptorId = acceptedAfter.find(
      (id) => !acceptedBefore.includes(id)
    );
    if (!acceptorId) return;

    // sourceId is the original sender who initiated the chat
    const senderId = after.sourceId;
    if (!senderId || senderId === acceptorId) return;

    // The acceptor's name as seen by the sender
    const acceptorName = after.displayNames?.[senderId] || "Someone";
    const chatId = event.params.chatId;

    await sendNotification({
      toUserId: senderId,
      title: "Request Accepted! 🎉",
      body: `${acceptorName} accepted your message request`,
      type: "request_accepted",
      priority: "normal",
      data: {
        acceptedBy: acceptorId,
        acceptedByName: acceptorName,
        chatId,                    // ✅ needed for direct MessageScreen nav
        otherUserId: acceptorId,   // ✅ alias for Flutter nav
      },
    });
  }
);

// ═══════════════════════════════════════════════
// TRIGGER 3 — Instant Job Posted
// Within 50km → HIGH priority
// Beyond 50km → NORMAL priority
// ═══════════════════════════════════════════════
exports.onInstantJobPosted = onDocumentCreated(
  "jobs/{jobId}",
  async (event) => {
    const job = event.data.data();
    if (!job.isInstantJob) return;

    const jobLat = job.locationGeoPoint?.latitude;
    const jobLng = job.locationGeoPoint?.longitude;
    const jobTitle = job.title || "Job";
    const jobLocation = job.location || "Nearby";
    const jobId = event.params.jobId;
    const posterId = job.postedBy;

    if (!jobLat || !jobLng) {
      console.log("⚠️ No location on instant job — skipping");
      return;
    }

    const usersSnapshot = await db.collection("users").get();
    console.log(`⚡ Instant job — notifying ${usersSnapshot.size} users`);

    const promises = usersSnapshot.docs.map(async (userDoc) => {
      const userId = userDoc.id;
      const userData = userDoc.data();

      if (userId === posterId) return;

      const userGeo = userData.locationGeoPoint;
      if (!userGeo) return;

      const distance = getDistanceKm(
        jobLat, jobLng,
        userGeo.latitude, userGeo.longitude,
      );

      const isNearby = distance <= 50;

      await sendNotification({
        toUserId: userId,
        title: isNearby ? "⚡ Instant Job Nearby!" : "New Instant Job",
        body: isNearby
          ? `${jobTitle} needed NOW in ${jobLocation} — ${Math.round(distance)}km away`
          : `${jobTitle} posted in ${jobLocation} — ${Math.round(distance)}km away`,
        type: "instant_job",
        priority: isNearby ? "high" : "normal",
        data: {
          jobId,
          jobTitle,
          jobLocation,
          distance: String(Math.round(distance)),
        },
      });
    });

    await Promise.all(promises);
    console.log(`✅ Instant job notifications done for ${jobId}`);
  }
);

// ═══════════════════════════════════════════════
// TRIGGER 4 — Regular Job Posted
// Within 80km → NORMAL priority
// Beyond 80km → No notification
// ═══════════════════════════════════════════════
exports.onRegularJobPosted = onDocumentCreated(
  "jobs/{jobId}",
  async (event) => {
    const job = event.data.data();
    if (job.isInstantJob) return;

    const jobLat = job.locationGeoPoint?.latitude;
    const jobLng = job.locationGeoPoint?.longitude;
    const jobTitle = job.title || "Job";
    const jobLocation = job.location || "Unknown";
    const jobId = event.params.jobId;
    const posterId = job.postedBy;

    if (!jobLat || !jobLng) {
      console.log("⚠️ No location on regular job — skipping");
      return;
    }

    const usersSnapshot = await db.collection("users").get();
    console.log(`📋 Regular job — checking ${usersSnapshot.size} users`);

    const promises = usersSnapshot.docs.map(async (userDoc) => {
      const userId = userDoc.id;
      const userData = userDoc.data();

      if (userId === posterId) return;

      const userGeo = userData.locationGeoPoint;
      if (!userGeo) return;

      const distance = getDistanceKm(
        jobLat, jobLng,
        userGeo.latitude, userGeo.longitude,
      );

      if (distance > 80) return;

      await sendNotification({
        toUserId: userId,
        title: "New Job Posted 💼",
        body: `${jobTitle} available in ${jobLocation} — ${Math.round(distance)}km away`,
        type: "job_posted",
        priority: "normal",
        data: {
          jobId,
          jobTitle,
          jobLocation,
          distance: String(Math.round(distance)),
        },
      });
    });

    await Promise.all(promises);
    console.log(`✅ Regular job notifications done for ${jobId}`);
  }
);

// ═══════════════════════════════════════════════
// HAVERSINE DISTANCE
// ═══════════════════════════════════════════════
function getDistanceKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
    Math.cos(toRad(lat2)) *
    Math.sin(dLng / 2) *
    Math.sin(dLng / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRad(deg) {
  return (deg * Math.PI) / 180;
}
