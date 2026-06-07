# Sampark — Known Issues, Bugs & Vulnerabilities

> Audit date: 2026-06-04 · Last updated: 2026-06-07  
> Severity legend: 🔴 Critical · 🟠 High · 🟡 Medium · 🔵 Low / Polish  
> Status legend: ✅ Fixed · 🔧 Open

---

## 🔴 Critical

### ~~1. Profile photo fetched on every screen rebuild~~ ✅ Fixed

> **Resolved 2026-06-05** — `_userCache: Map<String, Map<String, String>>` added to `_HomeScreenState`. `getUserData()` returns cached data on repeat calls, eliminating N Firestore reads per snapshot. `CachedNetworkImageProvider` (via `cached_network_image`) used in `ChatListItem` and `ChatScreen` AppBar so image bytes are never re-downloaded.

---

### ~~2. Logout does not sign out from Firebase Auth~~ ✅ Fixed

> **Resolved 2026-06-05** — Added `firebase_auth` import to `your_profile_screen.dart`. Logout button now calls `await FirebaseAuth.instance.signOut()` before navigating to `'/'` (AuthGate), with a `mounted` guard. Renamed dialog `context` parameter to `dialogContext` to eliminate shadowing.

---

### ~~3. Unread-count logic uses chat ID string-splitting instead of known UID~~ ✅ Fixed

> **Resolved 2026-06-05** — Added `String? _otherUserId` to `_ChatScreenState`, populated from nav args in `didChangeDependencies()`. Both `_sendMessage` and `_sendFile` now reference `_otherUserId` directly instead of `chatId.split('_').firstWhere(...)`.

---

### ~~4. No Firestore Security Rules — any authenticated user can read/write anything~~ ✅ Fixed

> **Resolved 2026-06-05** — Created `firestore.rules` with ownership-based rules: users can only write their own profile; chats are readable only by their members; messages can only be edited/deleted by their sender; the `members` array is validated on chat creation. Registered in `firebase.json` under the `"firestore"` key. Deploy with `firebase deploy --only firestore:rules`.

---

## 🟠 High

### ~~5. `YourProfileScreen` is fully hardcoded — saves nothing to the database~~ ✅ Fixed

> **Resolved 2026-06-06** — Complete rewrite of `your_profile_screen.dart`:
> - `_loadProfile()` fetches `name`, `about`, and `profilePic` from Firestore on `initState`.
> - Email shown as read-only from `FirebaseAuth.instance.currentUser?.email`.
> - `_saveProfile()` writes `name` and `about` (and optionally a new `profilePic` URL) to Firestore via `update()`.
> - Loading spinner shown while the initial Firestore fetch is in-flight.

---

### ~~6. `ProfileScreen` (contact view) is hardcoded with a developer's personal email~~ ✅ Fixed

> **Resolved 2026-06-06** — Complete rewrite of `profile_screens.dart`:
> - Accepts `{userId}` from `ModalRoute.settings.arguments`.
> - `FutureBuilder` loads `name`, `email`, `about`, `profilePic`, and `lastActive` from Firestore for that user.
> - Online status is computed from `lastActive` (< 5 min = online).
> - Avatar uses `CachedNetworkImage` with fallback icon.

---

### ~~7. Profile photo upload button in edit mode is a no-op~~ ✅ Fixed

> **Resolved 2026-06-06** — Camera icon in `YourProfileScreen` edit mode is now wrapped in a `GestureDetector`. Tapping it calls `_pickPhoto()` which uses `ImagePicker.gallery` with resize (500×500, 70% quality). A `FileImage` preview renders instantly. The upload happens on Save via `_uploadPhoto()` → Firebase Storage `profile_pics/{uid}.jpg` → Firestore `profilePic` field update.

---

### 8. Duplicate FCM listener — foreground notifications shown twice 🔧 Open
**Files:** `chat_screens.dart` (L40–44), `main.dart` (L74–77)

`FirebaseMessaging.onMessage` is subscribed in both `main.dart` and `ChatScreen.initState()`. When on the chat screen, notifications fire twice. The `ChatScreen` subscription is also never cancelled (no `StreamSubscription` stored for `dispose()`).

**Fix:** Remove the listener from `ChatScreen`; manage all foreground notifications in `main.dart`. Store and cancel `StreamSubscription`s in `dispose()`.

---

### 9. `_checkInitialMessage` calls Navigator inside `initState` — unsafe 🔧 Open
**File:** `chat_screens.dart` (L67–85)

`Navigator.pushReplacementNamed` is called asynchronously from `initState`. This can throw `"Navigator operation requested with a context that does not include a Navigator"` or cause build-phase errors.

**Fix:** Wrap navigation in `WidgetsBinding.instance.addPostFrameCallback`, or handle initial messages at the app level in `AuthGate`.

---

### 10. `_generateChatId` method placed outside `_saveContact` — structural bug 🔧 Open
**File:** `new_contact_screen.dart` (L403–408)

`_generateChatId` is placed after the closing brace of `_saveContact` and before `dispose()`. While it compiles correctly (still within the class), this is a misleading structure that suggests a scope error and confuses code readers/linters.

**Fix:** Move `_generateChatId` to a proper position as a class method.

---

## 🟡 Medium

### 11. Time format bug — 13:30 shown instead of 1:30 PM 🔧 Open
**File:** `chat_screens.dart` (L753)

```dart
'${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}'
```

`time.hour` is 24-hour. 1:30 PM renders as `"13:30 PM"`.

**Fix:** Convert: `time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour)`.

---

### 12. `AnimatedButton` loading guard is always bypassed 🔧 Open
**Files:** `login_screen.dart` (L175), `signup_screen.dart` (L382)

```dart
onPressed: () => _isLoading ? null : _signInWithEmail(),
```

The lambda always fires; the inner ternary just discards null. Users can tap multiple times and fire concurrent auth requests.

**Fix:** `onPressed: _isLoading ? null : _signInWithEmail`

---

### 13. Long-press options allow deleting another user's file messages 🔧 Open
**File:** `chat_screens.dart` (L660–669)

```dart
if (isMe || fileUrl != null) {
  _showMessageOptions(...);
}
```

`fileUrl != null` shows the bottom sheet for the other user's file messages too, which includes a **Delete Message** option with no sender check.

**Fix:** Gate delete on `isMe`; show only a download option for others' files.

---

### 14. `lastMessage` initialized to `'New chat started'` — shown in chat list 🔧 Open
**Files:** `new_contact_screen.dart` (L374), `home_screen.dart` (L354)

Misleading placeholder text shows in the chat list preview before any real message is sent.

**Fix:** Set `lastMessage: ''` and render a placeholder like *"Say hello 👋"* for empty last messages.

---

### 15. Download logic is duplicated in two files 🔧 Open
**Files:** `chat_screens.dart` (L350–398), `message_bubble.dart` (L377–428)

`_downloadFile` is implemented identically in both files. Any change must be applied twice.

**Fix:** Extract into a shared `FileUtils.download()` helper.

---

### 16. Input validator accepts whitespace-only names 🔧 Open
**File:** `new_contact_screen.dart` (L110)

`value.isEmpty` passes for `"   "` (spaces). The name is then `trim()`-ed to `''` and saved.

**Fix:** Validate `value.trim().isEmpty`.

---

### 17. Contacts tab never shows profile pictures 🔧 Open
**File:** `home_screen.dart` (L327–331)

Contacts always show a static icon; the `profilePic` stored in Firestore is ignored.

**Fix:** Load and display profile pic using `cached_network_image`.

---

### 18. Notification ID can be `0` for all FCM messages without a message ID 🔧 Open
**File:** `notification_service.dart` (L44–45)

`message.messageId` can be `null`; `null.hashCode == 0`, so every such notification overwrites the previous one.

**Fix:** Use `DateTime.now().millisecondsSinceEpoch % 100000` as the notification ID.

---

### 19. Call screen / buttons are non-functional stubs with no indicator 🔧 Open
**Files:** `home_screen.dart` (L376–378), `call_screen.dart`

Video and audio call buttons navigate to an empty screen. No "coming soon" feedback is given.

**Fix:** Disable buttons and show a dialog, or implement the feature.

---

## 🔵 Low / Polish

### 20. `print()` statements leak UIDs, tokens, and file URLs in release builds 🔧 Open
All files contain `print()` calls logging sensitive data readable via `adb logcat` on any device.

**Fix:** Use a conditional logger or remove all `print` calls from release code.

---

### 21. Password field uses a different `InputDecoration` style from email field 🔧 Open
**File:** `login_screen.dart` (L156–159)

Email field uses the global theme; password field explicitly sets `border: OutlineInputBorder()`, causing visual inconsistency.

---

### 22. `BottomNavigationBar` `currentIndex` is hardcoded to `0` 🔧 Open
**File:** `home_screen.dart` (L164)

The active tab indicator never moves when tapping nav bar items.

**Fix:** Track `_currentNavIndex` in state.

---

### 23. Bottom nav bar and top tab bar duplicate and contradict each other 🔧 Open
**File:** `home_screen.dart`

"Contacts" on the bottom nav goes to `/new-contact` (add contact); "Contacts" on the top tab shows the contacts list. Both claim to be the same feature.

---

### 24. Camera icon in `NewContactScreen` is a decorative dead-end 🔧 Open
**File:** `new_contact_screen.dart` (L77–99)

Camera overlay has no gesture handler. No contact photo feature is implemented despite the UI affordance.

---

### 25. `MessageType` enum defined but never used 🔧 Open
**File:** `chat_model.dart` (L45–50)

`enum MessageType { text, image, audio, video }` is dead code.

---

### 26. `AuthService` is bypassed in `signup_screen.dart` 🔧 Open
**File:** `auth_service.dart` vs `signup_screen.dart`

`AuthService.signUp` saves `{uid, email, name, createdAt}`. `signup_screen.dart` saves `{name, email, profilePic, lastActive}` directly. The two Firestore schemas are inconsistent — `uid` is missing from the signup path; `profilePic` and `lastActive` are missing from the service.

---

## ➕ Additional Fix (not in original audit)

### ~~A. Message send/receive delay (~4 seconds)~~ ✅ Fixed

> **Resolved 2026-06-05** — Implemented optimistic UI in `_sendMessage`:
> 1. Text field cleared immediately on tap.
> 2. Message added to `_pendingMessages` map and rendered instantly (75% opacity + clock icon).
> 3. Firestore `add()` runs in the background; the metadata `update()` (lastMessage/unreadCount) is now fire-and-forget (no `await`), eliminating the second sequential round-trip.
> 4. Pending bubble removed when the live stream confirms the real document.
>
> Also added `MessageCache` prefetch service: last 30 messages per chat are fetched in the background when the home screen loads, so `ChatScreen` opens instantly from cache.

---

## 🟠 High — New Contact Screen Audit (2026-06-07)

### 27. Contact name & about are saved from the form, not from the real user's profile 🔧 Open
**File:** `new_contact_screen.dart` (L358–361)

When you add a contact, `name` and `about` written to `users/{currentUid}/contacts/{otherUserId}` come from whatever the adding user typed into the form — not from the actual user's Firestore profile. This means:
- A contact can be saved with a completely wrong name.
- The `about` field saved here is never read by any screen (chat list and profile screen both read from `users/{otherUserId}/about` directly).
- The form's `About` field is a data-entry dead-end.

**Fix:** After the email lookup succeeds, read `name`, `about`, and `profilePic` from `otherUser.data()` and use those values instead of form inputs. Remove the `Name` and `About` fields from the form entirely — the email lookup is sufficient.

---

### 28. Contact creation is one-directional — the other user gets no record 🔧 Open
**File:** `new_contact_screen.dart` (L351–362)

When User A adds User B, only `users/A/contacts/B` is created. User B gets no corresponding `users/B/contacts/A` entry. The chat document is shared (both are in `members[]`), so the chat appears on both sides — but the contacts list for User B has no entry for User A, which is an inconsistent state.

**Fix:** After saving `users/A/contacts/B`, also write `users/B/contacts/A` in the same batch so both sides are symmetrical.

---

### 29. Email lookup is case-sensitive — registration vs. search case mismatch silently fails 🔧 Open
**File:** `new_contact_screen.dart` (L295–299)

Firebase Auth normalizes emails to lowercase on sign-up. However, the email stored in Firestore's `users` collection is written directly from the signup form with no normalization guarantee. The contact-search query uses `isEqualTo: email` (exact match). If the user types `User@Gmail.com` but it was stored as `user@gmail.com`, the query returns empty and shows "No user found" even though the user exists.

**Fix:** Normalize the search email with `.toLowerCase()` before the Firestore query: `final email = _emailController.text.trim().toLowerCase();`. Also normalize on signup.

---


| # | Severity | Category | File(s) | Status |
|---|---|---|---|---|
| 1 | 🔴 | Performance | `home_screen.dart`, `chat_screens.dart` | ✅ Fixed |
| 2 | 🔴 | Auth / Security | `your_profile_screen.dart` | ✅ Fixed |
| 3 | 🔴 | Logic Bug | `chat_screens.dart` | ✅ Fixed |
| 4 | 🔴 | Security | Firestore Rules | ✅ Fixed |
| 5 | 🟠 | Functionality | `your_profile_screen.dart` | ✅ Fixed |
| 6 | 🟠 | Functionality | `profile_screens.dart` | ✅ Fixed |
| 7 | 🟠 | Functionality | `your_profile_screen.dart` | ✅ Fixed |
| A | ➕ | Performance / UX | `chat_screens.dart`, `message_cache.dart` | ✅ Fixed |
| 8 | 🟠 | Memory Leak | `chat_screens.dart`, `main.dart` | 🔧 Open |
| 9 | 🟠 | Crash Risk | `chat_screens.dart` | 🔧 Open |
| 10 | 🟠 | Code Structure | `new_contact_screen.dart` | 🔧 Open |
| 11 | 🟡 | Display Bug | `chat_screens.dart` | 🔧 Open |
| 12 | 🟡 | UX / Logic | `login_screen.dart`, `signup_screen.dart` | 🔧 Open |
| 13 | 🟡 | Logic Bug | `chat_screens.dart` | 🔧 Open |
| 14 | 🟡 | UX | `new_contact_screen.dart`, `home_screen.dart` | 🔧 Open |
| 15 | 🟡 | Maintainability | `chat_screens.dart`, `message_bubble.dart` | 🔧 Open |
| 16 | 🟡 | Validation | `new_contact_screen.dart` | 🔧 Open |
| 17 | 🟡 | UI | `home_screen.dart` | 🔧 Open |
| 18 | 🟡 | Crash Risk | `notification_service.dart` | 🔧 Open |
| 19 | 🟡 | UX | `home_screen.dart`, `call_screen.dart` | 🔧 Open |
| 20 | 🔵 | Security | All files | 🔧 Open |
| 21 | 🔵 | UI Consistency | `login_screen.dart` | 🔧 Open |
| 22 | 🔵 | UI | `home_screen.dart` | 🔧 Open |
| 23 | 🔵 | UX | `home_screen.dart` | 🔧 Open |
| 24 | 🔵 | UX | `new_contact_screen.dart` | 🔧 Open |
| 25 | 🔵 | Code Quality | `chat_model.dart` | 🔧 Open |
| 26 | 🔵 | Architecture | `auth_service.dart`, `signup_screen.dart` | 🔧 Open |
| 27 | 🟠 | Data Integrity | `new_contact_screen.dart` | 🔧 Open |
| 28 | 🟠 | Data Integrity | `new_contact_screen.dart` | 🔧 Open |
| 29 | 🟡 | Logic Bug | `new_contact_screen.dart` | 🔧 Open |
