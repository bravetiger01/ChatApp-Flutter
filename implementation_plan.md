# Voice Call Feature using Agora Service

This document outlines the step-by-step plan to implement a fully functional voice call feature using Agora SDK for the audio transmission and Firebase for signaling (ringing the receiver).

## Goal Description
Transform the existing UI-only `call_screen.dart` into a working voice call system where users can call each other from a chat, receive incoming call alerts, and communicate using Agora's Real-Time Communication (RTC) network.

## User Review Required
> [!IMPORTANT]
> **Agora App ID Needed**
> To use Agora, you must create a free account at [Agora.io](https://www.agora.io/), create a new project, and get an **App ID**. We cannot proceed with the actual coding until we have an App ID to connect to their network.

## Open Questions
> [!WARNING]
> 1. **Do you already have an Agora account and App ID?** If not, please create one and let me know the App ID. 
> 2. **Incoming Calls in Background:** Do you want standard push notifications for incoming calls, or a full-screen "WhatsApp style" ringing interface even when the app is closed? (Full-screen ringing requires a package like `flutter_callkit_incoming` which requires extensive native Android/iOS setup. I recommend starting with standard Firebase notifications and in-app ringing for the first version).

---

## Proposed Implementation Steps

### Phase 1: Setup & Dependencies
1. Add the Agora Flutter SDK (`agora_rtc_engine`) to `pubspec.yaml`.
2. Add necessary permissions in `AndroidManifest.xml` (Microphone, Bluetooth, Network state) and iOS `Info.plist`.

### Phase 2: Firebase Signaling (The Ringing Mechanism)
1. **Firestore Collection**: Create a new `/calls` collection.
2. **Caller Action**: When User A calls User B, we create a document in `/calls/{callId}` with:
   - `callerId`, `callerName`, `callerPic`
   - `receiverId`
   - `status`: `'ringing'`
   - `channelId`: A unique string for Agora (usually the `chatId`).
3. **Receiver Action**: We set up a Firestore listener in `main.dart` or `home_screen.dart` that listens for documents in `/calls` where `receiverId == currentUser.uid` and `status == 'ringing'`.
4. **Incoming Call Screen**: When the listener detects a ringing call, it pops up an "Incoming Call" screen with Accept and Reject buttons.

### Phase 3: Agora Integration in Call Screen
1. **Update `call_screen.dart`**:
   - Initialize the Agora RTC Engine using your App ID.
   - Join the channel (`channelId`) when the call is accepted.
   - Bind the existing UI buttons (Mute, Speaker, End Call) to Agora's native functions (`muteLocalAudioStream`, `setEnableSpeakerphone`, `leaveChannel`).
2. **Handle Call States**:
   - Listen for when the other user joins or leaves the channel.
   - Update the UI from "Calling..." to the call duration timer once connected.
3. **Cleanup**: Properly destroy the Agora engine when the call ends or is rejected to free up device resources.

### Phase 4: Push Notifications (Optional MVP addition)
Update the existing `index.js` Cloud Function to also send a special FCM notification when a call document is created, ensuring the receiver gets a notification even if their app is in the background.

## Verification Plan
### Automated Tests
- None initially.

### Manual Verification
1. Call from Device A to Device B.
2. Verify Device B shows incoming call alert.
3. Verify accepting the call connects audio in both directions.
4. Verify mute and speaker buttons function correctly.
5. Verify call terminates correctly for both users when one hangs up.
