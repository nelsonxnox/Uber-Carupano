const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 1. NOTIFICACIÓN A TODOS LOS CHOFERES AL ENTRAR UN VIAJE NUEVO
 * Se dispara automáticamente cuando un pasajero solicita una carrera en 'rides/{rideId}'.
 * Despierta el teléfono del chofer aunque tenga la aplicación cerrada o bloqueada.
 */
exports.notifyDriversNewRide = functions.firestore
  .document("rides/{rideId}")
  .onCreate(async (snap, context) => {
    const ride = snap.data();
    if (!ride) return null;

    const passengerName = ride.passengerName || "Pasajero";
    const pickupAddress = ride.pickupAddress || "Carúpano";
    const dropoffAddress = ride.dropoffAddress || "Destino";
    const price = ride.offeredPrice ? `$${Number(ride.offeredPrice).toFixed(2)}` : "$2.50";
    const vehicleType = (ride.vehicleType || "moto").toUpperCase();

    try {
      // 1. Obtener todos los choferes registrados que tengan un Device Token (FCM)
      const driversSnap = await admin.firestore().collection("drivers").get();
      const tokens = [];

      driversSnap.forEach((doc) => {
        const data = doc.data();
        if (data.fcmToken && typeof data.fcmToken === "string") {
          tokens.push(data.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("No hay choferes con FCM Token registrado para notificar.");
        return null;
      }

      // 2. Construir el paquete de Notificación Push con Prioridad Alta
      const payload = {
        notification: {
          title: `🛵 ¡Nuevo Viaje Disponible en Radar! (${price})`,
          body: `${passengerName} solicita ${vehicleType}: ${pickupAddress} ➔ ${dropoffAddress}`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "NEW_RIDE",
          rideId: context.params.rideId,
          price: String(ride.offeredPrice || 2.5),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "carupano_rides_channel",
            sound: "default",
            priority: "max",
            defaultVibrateTimings: true,
            defaultSound: true,
          },
        },
      };

      // 3. Enviar a todos los choferes vía Firebase Cloud Messaging
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...payload,
      });

      console.log(`✅ Notificaciones enviadas: ${response.successCount} exitosas, ${response.failureCount} fallidas.`);
      return null;
    } catch (error) {
      console.error("Error enviando notificaciones push a choferes:", error);
      return null;
    }
  });

/**
 * 2. NOTIFICACIÓN DE NUEVO MENSAJE DE CHAT
 * Se dispara cuando una de las partes escribe en 'rides/{rideId}/messages/{messageId}'.
 * Hace sonar el teléfono del destinatario aunque tenga la app cerrada.
 */
exports.notifyNewChatMessage = functions.firestore
  .document("rides/{rideId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const msg = snap.data();
    if (!msg) return null;

    const rideId = context.params.rideId;
    const senderName = msg.senderName || "Usuario";
    const text = msg.text || "Nuevo mensaje";
    const isDriverSender = msg.isDriver === true;

    try {
      const rideDoc = await admin.firestore().collection("rides").doc(rideId).get();
      if (!rideDoc.exists) return null;
      const rideData = rideDoc.data();

      let targetToken = null;

      if (isDriverSender) {
        // El chofer escribió -> Notificar al pasajero
        // Buscamos el token del pasajero en su ficha
        const passengerPhone = rideData.passengerPhone;
        if (passengerPhone) {
          const userDoc = await admin.firestore().collection("users").doc(passengerPhone).get();
          if (userDoc.exists) targetToken = userDoc.data()?.fcmToken;
        }
      } else {
        // El pasajero escribió -> Notificar al chofer asignado
        const driverId = rideData.acceptedOffer?.id;
        if (driverId) {
          const driverDoc = await admin.firestore().collection("drivers").doc(driverId).get();
          if (driverDoc.exists) targetToken = driverDoc.data()?.fcmToken;
        }
      }

      if (!targetToken) {
        console.log("No se encontró token para el destinatario del mensaje.");
        return null;
      }

      const messagePayload = {
        token: targetToken,
        notification: {
          title: `💬 Mensaje de ${senderName}`,
          body: text,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "CHAT_MESSAGE",
          rideId: rideId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_messages_channel",
            sound: "default",
          },
        },
      };

      await admin.messaging().send(messagePayload);
      console.log(`✅ Push de chat enviada a destinatario.`);
      return null;
    } catch (error) {
      console.error("Error enviando push de mensaje de chat:", error);
      return null;
    }
  });
