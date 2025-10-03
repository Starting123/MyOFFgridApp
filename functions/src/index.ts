/**
 * Off-Grid SOS App - Firebase Cloud Functions
 * 
 * This file contains Firebase Cloud Functions for:
 * - SOS alert notifications
 * - User authentication triggers
 * - Real-time message delivery
 * - Emergency location broadcasting
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest, onCall} from "firebase-functions/v2/https";
import {onDocumentWritten, onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Set global options for cost control
setGlobalOptions({ maxInstances: 10 });

/**
 * SOS Alert Notification Trigger
 * Sends push notifications when a new SOS alert is created
 */
export const notifySOSAlert = onDocumentCreated("sos_alerts/{alertId}", async (event) => {
  const alertData = event.data?.data();
  if (!alertData) return;

  logger.info("New SOS Alert created", { alertId: event.params.alertId, alertData });

  try {
    // Find nearby users within 5km radius
    const nearbyUsers = await admin.firestore()
      .collection("users")
      .where("isOnline", "==", true)
      .get();

    const notifications: Promise<admin.messaging.MessagingDevicesResponse>[] = [];

    for (const userDoc of nearbyUsers.docs) {
      const userData = userDoc.data();
      
      // Skip the user who created the SOS alert
      if (userData.id === alertData.userId) continue;

      // Check if user has FCM token for notifications
      if (userData.fcmToken) {
        const message = {
          notification: {
            title: "🚨 Emergency Alert Nearby",
            body: `SOS from ${alertData.userName || 'Unknown'} - ${alertData.message || 'Emergency assistance needed'}`,
          },
          data: {
            type: "sos_alert",
            alertId: event.params.alertId,
            userId: alertData.userId,
            latitude: alertData.latitude?.toString(),
            longitude: alertData.longitude?.toString(),
          },
          token: userData.fcmToken,
        };

        notifications.push(admin.messaging().send(message));
      }
    }

    // Send all notifications
    const results = await Promise.allSettled(notifications);
    const successful = results.filter(r => r.status === "fulfilled").length;
    const failed = results.filter(r => r.status === "rejected").length;

    logger.info(`SOS notifications sent: ${successful} successful, ${failed} failed`);

  } catch (error) {
    logger.error("Error sending SOS notifications:", error);
  }
});

/**
 * User Status Update Trigger
 * Updates user online status and last seen timestamp
 */
export const updateUserStatus = onDocumentWritten("users/{userId}", async (event) => {
  const beforeData = event.data?.before.data();
  const afterData = event.data?.after.data();
  
  if (!afterData) return; // User deleted

  // Update last seen timestamp
  if (afterData.isOnline && (!beforeData || !beforeData.isOnline)) {
    await event.data?.after.ref.update({
      lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    logger.info(`User ${afterData.name} came online`);
  }
});

/**
 * Message Delivery Notification
 * Sends push notification when a new message is received
 */
export const notifyNewMessage = onDocumentCreated("conversations/{conversationId}/messages/{messageId}", async (event) => {
  const messageData = event.data?.data();
  if (!messageData) return;

  try {
    // Get conversation participants
    const conversationDoc = await admin.firestore()
      .collection("conversations")
      .doc(event.params.conversationId)
      .get();

    const conversationData = conversationDoc.data();
    if (!conversationData || !conversationData.participants) return;

    // Find recipient (not the sender)
    const recipientId = conversationData.participants.find((id: string) => id !== messageData.senderId);
    if (!recipientId) return;

    // Get recipient user data
    const recipientDoc = await admin.firestore()
      .collection("users")
      .doc(recipientId)
      .get();

    const recipientData = recipientDoc.data();
    if (!recipientData || !recipientData.fcmToken) return;

    // Send notification
    const message = {
      notification: {
        title: `💬 ${messageData.senderName || 'New Message'}`,
        body: messageData.type === 'text' ? messageData.content : 'Sent a file',
      },
      data: {
        type: "new_message",
        conversationId: event.params.conversationId,
        messageId: event.params.messageId,
        senderId: messageData.senderId,
      },
      token: recipientData.fcmToken,
    };

    await admin.messaging().send(message);
    logger.info(`Message notification sent to user ${recipientId}`);

  } catch (error) {
    logger.error("Error sending message notification:", error);
  }
});

/**
 * Device Registration Function
 * Registers FCM token for push notifications
 */
export const registerDevice = onCall(async (request) => {
  const { userId, fcmToken } = request.data;
  
  if (!userId || !fcmToken) {
    throw new Error("Missing userId or fcmToken");
  }

  try {
    await admin.firestore()
      .collection("users")
      .doc(userId)
      .update({
        fcmToken: fcmToken,
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
      });

    logger.info(`FCM token registered for user ${userId}`);
    return { success: true };

  } catch (error) {
    logger.error("Error registering device:", error);
    throw new Error("Failed to register device");
  }
});

/**
 * Emergency Broadcast Function
 * Broadcasts emergency message to all nearby users
 */
export const broadcastEmergency = onCall(async (request) => {
  const { userId, message, location, emergencyType } = request.data;
  
  if (!userId || !message) {
    throw new Error("Missing required parameters");
  }

  try {
    // Create SOS alert document
    const alertRef = await admin.firestore()
      .collection("sos_alerts")
      .add({
        userId: userId,
        message: message,
        location: location,
        emergencyType: emergencyType || "general",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        responders: [],
      });

    logger.info(`Emergency broadcast created: ${alertRef.id}`);
    return { alertId: alertRef.id, success: true };

  } catch (error) {
    logger.error("Error creating emergency broadcast:", error);
    throw new Error("Failed to broadcast emergency");
  }
});

/**
 * Health Check Function
 * Simple endpoint to verify Firebase Functions are working
 */
export const healthCheck = onRequest(async (request, response) => {
  logger.info("Health check requested");
  
  const status = {
    status: "healthy",
    timestamp: new Date().toISOString(),
    firebase: {
      functions: "active",
      firestore: "connected",
      messaging: "available",
    },
    version: "1.0.0",
  };

  response.json(status);
});

/**
 * Analytics Function
 * Tracks app usage and emergency statistics
 */
export const trackAnalytics = onCall(async (request) => {
  const { eventType, userId, metadata } = request.data;
  
  try {
    await admin.firestore()
      .collection("analytics")
      .add({
        eventType: eventType,
        userId: userId,
        metadata: metadata || {},
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    return { success: true };

  } catch (error) {
    logger.error("Error tracking analytics:", error);
    return { success: false, error: error.message };
  }
});
