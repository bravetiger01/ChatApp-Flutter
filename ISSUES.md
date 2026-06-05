# Sampark — Known Issues, Bugs & Vulnerabilities

> Audit date: 2026-06-04  
> Severity legend: 🔴 Critical · 🟠 High · 🟡 Medium · 🔵 Low / Polish

---

## 🔴 Critical

### 1. Profile photo fetched on every screen rebuild
**File:** `home_screen.dart` (L252–291)

`getUserData()` is called inside `FutureBuilder` that lives inside a `StreamBuilder`. Every Firestore snapshot event (new message, last-time update, etc.) tears down and rebuilds every `FutureBuilder`, re-fetching the profile photo URL for each chat item via a fresh Firestore read. Since `FutureBuilder` has no built-in caching, this causes N reads per snapshot (N = number of chats).

**Same pattern in:** `chat_screens.dart` — the AppBar `StreamBuilder` re-downloads the profile image via `NetworkImage` on every user-document update.

**Fix:** Cache user data in a `Map<String, Map<String,String>>` at the widget-state level, or introduce a `UserProvider`/`InheritedWidget`. Use `cached_network_image` (already in pubspec) for the avatar itself.

---

### 2. Logout does not sign out from Firebase Auth
**Files:** `home_screen.dart` (L89–91), `your_profile_screen.dart` (L378–384)

In `home_screen.dart` the logout menu calls `FirebaseAuth.instance.signOut()` then navigates to `'/'`. However `YourProfileScreen`'s logout only navigates to `/login` **without calling** `FirebaseAuth.instance.signOut()`, so the user is still authenticated and `AuthGate` will immediately redirect them back to Home.

**Fix:** Call `await FirebaseAuth.instance.signOut()` before navigating in `_showLogoutDialog`.

---

### 3. Unread-count logic uses chat ID string-splitting instead of known UID
**File:** `chat_screens.dart` (L136–138)

```dart
'unreadCount_${chatId.split('_').firstWhere((id) => id != currentUser!.uid)}':
    FieldValue.increment(1),
```

This splits the chatId by `_` to guess the other user's UID. `firstWhere` will throw `StateError` if the UID is not found, and the pattern breaks entirely if the chat ID schema ever changes.

**Fix:** Pass `otherUserId` directly (already available in scope) instead of parsing the chat ID.

---

### 4. No Firestore Security Rules — any authenticated user can read/write anything
**Affected:** All Firestore collections

Any authenticated user can: read all user documents (including FCM tokens), read all messages in any chat, write to any user's contact list.

**Specific risks:**
- FCM tokens are in plain text in the `users` collection, readable by anyone → enables sending push notifications to arbitrary users.
- Message delete/edit is enforced only in the UI (`isMe` flag); any user can delete another user's messages via the Firestore API.

**Fix:** Add and commit `firestore.rules`. At minimum: a user document is only writable by its owner; messages are only deletable/editable by the sender; chats are only readable by their members.

---

## 🟠 High

### 5. `YourProfileScreen` is fully hardcoded — saves nothing to the database
**File:** `your_profile_screen.dart` (L24–27)

```dart
_nameController.text = 'Nitish kumar';
_aboutController.text = 'I am Great';
```

The profile page is initialized with hardcoded test data and `_saveProfile()` only calls `Future.delayed` — it never writes to Firestore or Firebase Auth.

**Fix:** Load from `FirebaseAuth.instance.currentUser` + Firestore in `initState`; persist changes on save.

---

### 6. `ProfileScreen` (contact view) is hardcoded with a developer's personal email
**File:** `profile_screens.dart` (L57–73)

The "View Profile" screen always shows `nitish838@gmail.com` / `Nitish Kumar` regardless of which contact is being viewed. It doesn't accept navigation arguments.

**Fix:** Accept a `userId` argument, load data from Firestore dynamically.

---

### 7. Profile photo upload button in edit mode is a no-op
**File:** `your_profile_screen.dart` (L98–119)

The camera icon appears in edit mode inside a `Positioned` widget with no `GestureDetector`. Tapping it does nothing.

**Fix:** Wrap in `GestureDetector`, implement `_pickAndUploadImage()` using `ImagePicker` + Firebase Storage (same pattern as `signup_screen.dart`).

---

### 8. Duplicate FCM listener — foreground notifications shown twice
**Files:** `chat_screens.dart` (L40–44), `main.dart` (L74–77)

`FirebaseMessaging.onMessage` is subscribed in both `main.dart` and `ChatScreen.initState()`. When on the chat screen, notifications fire twice. The `ChatScreen` subscription is also never cancelled (no `StreamSubscription` stored for `dispose()`).

**Fix:** Remove the listener from `ChatScreen`; manage all foreground notifications in `main.dart`. Store and cancel `StreamSubscription`s in `dispose()`.

---

### 9. `_checkInitialMessage` calls Navigator inside `initState` — unsafe
**File:** `chat_screens.dart` (L67–85)

`Navigator.pushReplacementNamed` is called asynchronously from `initState`. This can throw `"Navigator operation requested with a context that does not include a Navigator"` or cause build-phase errors.

**Fix:** Wrap navigation in `WidgetsBinding.instance.addPostFrameCallback`, or handle initial messages at the app level in `AuthGate`.

---

### 10. `_generateChatId` method placed outside `_saveContact` but still inside the class — structural bug
**File:** `new_contact_screen.dart` (L403–408)

`_generateChatId` is placed after the closing brace of `_saveContact` and before `dispose()`. While it compiles correctly (still within the class), this is a misleading structure that suggests a scope error and confuses code readers/linters.

**Fix:** Move `_generateChatId` to a proper position as a class method.

---

## 🟡 Medium

### 11. Time format bug — 13:30 shown instead of 1:30 PM
**File:** `chat_screens.dart` (L753)

```dart
'${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}'
```

`time.hour` is 24-hour. 1:30 PM renders as `"13:30 PM"`.

**Fix:** Convert: `time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour)`.

---

### 12. `AnimatedButton` loading guard is always bypassed
**Files:** `login_screen.dart` (L175), `signup_screen.dart` (L382)

```dart
onPressed: () => _isLoading ? null : _signInWithEmail(),
```

The lambda always fires; the inner ternary just discards null. Users can tap multiple times and fire concurrent auth requests.

**Fix:** `onPressed: _isLoading ? null : _signInWithEmail`

---

### 13. Long-press options allow deleting another user's file messages
**File:** `chat_screens.dart` (L660–669)

```dart
if (isMe || fileUrl != null) {
  _showMessageOptions(...);
}
```

`fileUrl != null` shows the bottom sheet for the other user's file messages too, which includes a **Delete Message** option with no sender check.

**Fix:** Gate delete on `isMe`; show only a download option for others' files.

---

### 14. `lastMessage` initialized to `'New chat started'` — shown in chat list
**Files:** `new_contact_screen.dart` (L374), `home_screen.dart` (L354)

Misleading placeholder text shows in the chat list preview before any real message is sent.

**Fix:** Set `lastMessage: ''` and render a placeholder like *"Say hello 👋"* for empty last messages.

---

### 15. Download logic is duplicated in two files
**Files:** `chat_screens.dart` (L350–398), `message_bubble.dart` (L377–428)

`_downloadFile` is implemented identically in both files. Any change must be applied twice.

**Fix:** Extract into a shared `FileUtils.download()` helper.

---

### 16. Input validator accepts whitespace-only names
**File:** `new_contact_screen.dart` (L110)

`value.isEmpty` passes for `"   "` (spaces). The name is then `trim()`-ed to `''` and saved.

**Fix:** Validate `value.trim().isEmpty`.

---

### 17. Contacts tab never shows profile pictures
**File:** `home_screen.dart` (L327–331)

Contacts always show a static icon; the `profilePic` stored in Firestore is ignored.

**Fix:** Load and display profile pic using `cached_network_image`.

---

### 18. Notification ID can be `0` for all FCM messages without a message ID
**File:** `notification_service.dart` (L44–45)

`message.messageId` can be `null`; `null.hashCode == 0`, so every such notification overwrites the previous one.

**Fix:** Use `DateTime.now().millisecondsSinceEpoch % 100000` as the notification ID.

---

### 19. Call screen / buttons are non-functional stubs with no indicator
**Files:** `home_screen.dart` (L376–378), `call_screen.dart`

Video and audio call buttons navigate to an empty screen. No "coming soon" feedback is given.

**Fix:** Disable buttons and show a dialog, or implement the feature.

---

## 🔵 Low / Polish

### 20. `print()` statements leak UIDs, tokens, and file URLs in release builds
All files contain `print()` calls logging sensitive data readable via `adb logcat` on any device.

**Fix:** Use a conditional logger or remove all `print` calls from release code.

---

### 21. Password field uses a different `InputDecoration` style from email field
**File:** `login_screen.dart` (L156–159)

Email field uses the global theme; password field explicitly sets `border: OutlineInputBorder()`, causing visual inconsistency.

---

### 22. `BottomNavigationBar` `currentIndex` is hardcoded to `0`
**File:** `home_screen.dart` (L164)

The active tab indicator never moves when tapping nav bar items.

**Fix:** Track `_currentNavIndex` in state.

---

### 23. Bottom nav bar and top tab bar duplicate and contradict each other
**File:** `home_screen.dart`

"Contacts" on the bottom nav goes to `/new-contact` (add contact); "Contacts" on the top tab shows the contacts list. Both claim to be the same feature.

---

### 24. Camera icon in `NewContactScreen` is a decorative dead-end
**File:** `new_contact_screen.dart` (L77–99)

Camera overlay has no gesture handler. No contact photo feature is implemented despite the UI affordance.

---

### 25. `MessageType` enum defined but never used
**File:** `chat_model.dart` (L45–50)

`enum MessageType { text, image, audio, video }` is dead code.

---

### 26. `AuthService` is bypassed in `signup_screen.dart`
**File:** `auth_service.dart` vs `signup_screen.dart`

`AuthService.signUp` saves `{uid, email, name, createdAt}`. `signup_screen.dart` saves `{name, email, profilePic, lastActive}` directly. The two Firestore schemas are inconsistent — `uid` is missing from the signup path; `profilePic` and `lastActive` are missing from the service.

---

## Summary Table

| # | Severity | Category | File(s) |
|---|---|---|---|
| 1 | 🔴 | Performance | `home_screen.dart`, `chat_screens.dart` |
| 2 | 🔴 | Auth / Security | `your_profile_screen.dart` |
| 3 | 🔴 | Logic Bug | `chat_screens.dart` |
| 4 | 🔴 | Security | Firestore Rules (missing) |
| 5 | 🟠 | Functionality | `your_profile_screen.dart` |
| 6 | 🟠 | Functionality | `profile_screens.dart` |
| 7 | 🟠 | Functionality | `your_profile_screen.dart` |
| 8 | 🟠 | Memory Leak | `chat_screens.dart`, `main.dart` |
| 9 | 🟠 | Crash Risk | `chat_screens.dart` |
| 10 | 🟠 | Code Structure | `new_contact_screen.dart` |
| 11 | 🟡 | Display Bug | `chat_screens.dart` |
| 12 | 🟡 | UX / Logic | `login_screen.dart`, `signup_screen.dart` |
| 13 | 🟡 | Logic Bug | `chat_screens.dart` |
| 14 | 🟡 | UX | `new_contact_screen.dart`, `home_screen.dart` |
| 15 | 🟡 | Maintainability | `chat_screens.dart`, `message_bubble.dart` |
| 16 | 🟡 | Validation | `new_contact_screen.dart` |
| 17 | 🟡 | UI | `home_screen.dart` |
| 18 | 🟡 | Crash Risk | `notification_service.dart` |
| 19 | 🟡 | UX | `home_screen.dart`, `call_screen.dart` |
| 20 | 🔵 | Security | All files |
| 21 | 🔵 | UI Consistency | `login_screen.dart` |
| 22 | 🔵 | UI | `home_screen.dart` |
| 23 | 🔵 | UX | `home_screen.dart` |
| 24 | 🔵 | UX | `new_contact_screen.dart` |
| 25 | 🔵 | Code Quality | `chat_model.dart` |
| 26 | 🔵 | Architecture | `auth_service.dart`, `signup_screen.dart` |
