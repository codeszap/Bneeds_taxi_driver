// Firebase v2 முறைப்படி மாற்றப்பட்ட புதிய குறியீடு
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {log, error} = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Firestore-ல் 'trips' collection-ல் ஒரு ஆவணம் புதுப்பிக்கப்படும்போது இந்த Function இயங்கும்.
 * இது Firebase Functions v2-க்கான புதிய தொடரியல் (syntax).
 */
exports.tripStatusNotifications = onDocumentUpdated("trips/{bookingId}", async (event) => {
    // நிகழ்விலிருந்து புதிய மற்றும் பழைய தரவைப் பெறுதல்
    const snapshot = event.data;
    if (!snapshot) {
        log("No data associated with the event");
        return;
    }
    const newData = snapshot.after.data();
    const oldData = snapshot.before.data();
    const bookingId = event.params.bookingId;

    // trip_status மாறவில்லை என்றால், எதையும் செய்ய வேண்டாம்.
    if (newData.trip_status === oldData.trip_status) {
        log(`Status not changed for bookingId: ${bookingId}. Skipping.`);
        return;
    }

    const customerToken = newData.customer_fcm_token;
    if (!customerToken) {
        log(`Customer FCM token not found for bookingId: ${bookingId}.`);
        return;
    }

    let title = "";
    let body = "";

    // புதிய trip_status-ஐப் பொறுத்து, சரியான தலைப்பு மற்றும் செய்தியைத் தேர்ந்தெடுக்கவும்
    switch (newData.trip_status) {
        case "ACCEPTED":
            title = "Ride Accepted ✅";
            body = "Your ride request has been accepted by the driver.";
            break;

        case "ARRIVED":
            title = "Driver Arrived 🚕";
            body = "Your driver has arrived at the pickup location.";
            break;

        case "ON_TRIP":
            title = "Trip Started 🚖";
            body = "Your trip has started. Enjoy your ride!";
            break;

        case "COMPLETED":
            let fare = newData.final_fare ?? newData.fare ?? 0;
            title = "Ride Completed ✅";
            body = `Your trip is completed. The final fare is ₹${fare}.`;
            break;

        default:
            // மற்ற நிலைகளுக்கு Notification தேவையில்லை.
            log(`No notificatio n for status: ${newData.trip_status}`);
            return;
    }

    // Notification அனுப்பத் தயாராக உள்ளது
    const payload = {
        notification: {
            title: title,
            body: body,
        },
        token: customerToken,
        data: {
            bookingId: bookingId,
            status: newData.trip_status,
        },
        android: {
            priority: "high",
        },
    };

    try {
        log(`Sending notification to token: ${customerToken} for status: ${newData.trip_status}`);
        await admin.messaging().send(payload);
        log("✅ Successfully sent notification.");
    } catch (e) {
        error("❌ Error sending notification:", e);
    }
});
