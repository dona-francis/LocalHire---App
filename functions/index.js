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
      data: { type, ...data },
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

    const senderName = chat.displayNames?.[senderId] || "Someone";

    await sendNotification({
      toUserId: receiverId,
      title: "New Message Request 💬",
      body: `${senderName} wants to connect with you`,
      type: "message_request",
      priority: "normal",
      data: {
        senderId,
        senderName,
        chatId: event.params.chatId,
      },
    });
  }
);

// ═══════════════════════════════════════════════
// TRIGGER 2 — Request Accepted
// ═══════════════════════════════════════════════
exports.onRequestAccepted = onDocumentUpdated(
  "chats/{chatId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const acceptedBefore = before.acceptedBy || [];
    const acceptedAfter = after.acceptedBy || [];

    if (acceptedAfter.length <= acceptedBefore.length) return;

    const acceptorId = acceptedAfter.find(
      (id) => !acceptedBefore.includes(id)
    );
    if (!acceptorId) return;

    const senderId = after.sourceId;
    if (!senderId || senderId === acceptorId) return;

    const acceptorName = after.displayNames?.[acceptorId] || "Someone";

    await sendNotification({
      toUserId: senderId,
      title: "Request Accepted! 🎉",
      body: `${acceptorName} accepted your message request`,
      type: "request_accepted",
      priority: "normal",
      data: {
        acceptedBy: acceptorId,
        acceptedByName: acceptorName,
        chatId: event.params.chatId,
      },
    });
  }
);

// ═══════════════════════════════════════════════
// TRIGGER 3 — Instant Job Posted
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
      console.log("⚠️ No location on job");
      return;
    }

    const usersSnapshot = await db.collection("users").get();
    console.log(`📢 Notifying ${usersSnapshot.size} users`);

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

      const isNearby = distance <= 100;

      await sendNotification({
        toUserId: userId,
        title: isNearby ? "⚡ Instant Job Nearby!" : "New Job Available",
        body: isNearby
          ? `${jobTitle} needed now in ${jobLocation}`
          : `${jobTitle} available in ${jobLocation}`,
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
    console.log(`✅ Done for job ${jobId}`);
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