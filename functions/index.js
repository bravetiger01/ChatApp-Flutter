const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {RtcTokenBuilder, RtcRole} = require("agora-token");

const {onCall} = require("firebase-functions/v2/https");


initializeApp();


exports.generateAgoraToken = onCall({region: "asia-south1"}, (request) => {
  const channelName = request.data.channelName;
  // Read from functions/.env file — never hardcoded
  const APP_ID = process.env.AGORA_APP_ID;
  const APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE;
  if (!APP_ID || !APP_CERTIFICATE) {
    throw new Error("Agora credentials not configured in environment.");
  }
  const uid = 0;
  const role = RtcRole.PUBLISHER;
  const tokenExpiry = Math.floor(Date.now() / 1000) + 3600; // 1 hour
  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID, APP_CERTIFICATE, channelName, uid, role, tokenExpiry, tokenExpiry,
  );
  return {token: token};
});


exports.sendChatNotification = onDocumentCreated(
  {
    document: "chats/{chatId}/messages/{messageId}",
    region: "asia-south1",
  },
  async (event) => {
    const messageData = event.data.data();
    const chatId = event.params.chatId;
    const senderId = messageData.senderId;
    const messageText = messageData.text;

    try {
      // Fetch chat document
      const chatDoc = await getFirestore().collection("chats").doc(chatId).get();
      if (!chatDoc.exists) {
        console.error(`Chat document does not exist: ${chatId}`);
        return null;
      }
      const chatData = chatDoc.data();
      const members = chatData.members;
      const recipientId = members.find((id) => id !== senderId);
      if (!recipientId) {
        console.error(`No recipient found in chat: ${chatId}`);
        return null;
      }
      console.log(`Recipient ID: ${recipientId}`);

      // Fetch sender document
      const senderDoc = await getFirestore().collection("users").doc(senderId).get();
      if (!senderDoc.exists) {
        console.error(`Sender document does not exist: ${senderId}`);
        return null;
      }
      const senderName = senderDoc.data().name || "Unknown";

      // Fetch recipient document
      const recipientDoc = await getFirestore().collection("users").doc(recipientId).get();
      if (!recipientDoc.exists || !recipientDoc.data().fcmTokens) {
        console.error(`Recipient document or FCM tokens not found: ${recipientId}`);
        return null;
      }
      const recipientTokens = recipientDoc.data().fcmTokens;

      // Send notification to all recipient tokens
      const payload = {
        notification: {
          title: `New Message from ${senderName}`,
          body: messageText,
        },
        data: {
          chatId: chatId,
          senderId: senderId,
          otherUserId: senderId,
          otherUserName: senderName,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      const sendPromises = recipientTokens.map(async (token) => {
        try {
          await getMessaging().send({...payload, token});
          console.log(`Notification sent to token: ${token}`);
        } catch (error) {
          console.error(`Failed to send to token ${token}: ${error.message}`);
          if (error.code === "messaging/registration-token-not-registered") {
            // Remove invalid token
            await getFirestore()
              .collection("users")
              .doc(recipientId)
              .update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(token),
              });
            console.log(`Removed invalid token: ${token}`);
          }
        }
      });
      await Promise.all(sendPromises);
      console.log(`Notifications sent to ${recipientId} for message in ${chatId}`);
    } catch (error) {
      console.error(`Error sending notification: ${error.message}, Stack: ${error.stack}`);
    }
    return null;
  },
);


exports.onCallCreated = onDocumentCreated(
  {document: "calls/{callId}", region: "asia-south1"},
  async (event) => {
    const callData = event.data.data();
    const receiverId = callData.receiverId;
    const callerName = callData.callerName || "Unknown";
    const callId = event.params.callId; // Agora channelID

    if (!receiverId) {
      console.log("No receiverId in call document, skipping.");
      return null;
    }

    // Get receiver's FCM tokens
    const receiverDoc = await getFirestore().collection("users").doc(receiverId).get();

    if (!receiverDoc.exists || !receiverDoc.data().fcmTokens) {
      console.log(`No FCM tokens found for receiver: ${receiverId}`);
      return null;
    }

    const fcmTokens = receiverDoc.data().fcmTokens;

    // Build message payload
    const payload = {
      notification: {
        title: `${callerName} is Calling`,
        body: "Tap to answer or decline",
      },
      data: {
        type: "incoming_call",
        callerId: callData.callerId || "",
        callerName: callerName,
        channelId: callId,
        callerPhoto: callData.callerPhoto || "",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "call_channel",
          priority: "max",
          defaultVibrateTimings: true,
          sound: "default",
        },
      },
      apns: {
        headers: {"apns-priority": "10"},
        payload: {aps: {sound: "default"}},
      },
    };


    // send to all the receiver's devices
    const sendPromises = fcmTokens.map(async (token) => {
      try {
        await getMessaging().send({...payload, token});
        console.log(`Call notification sent to token: ${token}`);
      } catch (error) {
        console.error(`Failed to send call notification: ${error.message}`);
        if (error.code === "messaging/registration-token-not-registered") {
          // Remove stale token
          await getFirestore()
            .collection("users")
            .doc(receiverId)
            .update({
              fcmTokens: admin.firestore.FieldValue.arrayRemove(token),
            });
        }
      }
    });

    await Promise.all(sendPromises);
    return null;
  },
);
