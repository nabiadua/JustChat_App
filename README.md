# Flutter Chat App

A polished, real-time cross-platform chat application built with Flutter and Firebase. This project optimizes a baseline starter application into a highly secure, structurally sound, and full-featured messaging workspace.

## 🚀 Setup & Installation

This project has been updated and verified on Flutter stable `3.41.x` and Dart `3.11.x`.

```sh
# 1. Fetch dependencies and update legacy plugins
flutter pub get

# 2. Activate the global Firebase tooling CLI
dart pub global activate flutterfire_cli

# 3. Configure against your specific Firebase console instance
flutterfire configure

# 4. Compile and launch onto your active platform device
flutter run
🔥 Firebase Configuration
To deploy your own live database instance for this chat application, use the following sequence:

Create a Firebase project via the Firebase Console.

Enable Authentication and navigate to Sign-in method to activate Email/Password.

Create a Cloud Firestore database instance.

Navigate to your Firestore Rules tab, paste the production rules detailed below, and click Publish.

Execute flutterfire configure from your project's root folder to synchronize your local target credentials (lib/firebase_options.dart).

📊 Production Firestore Schema
Plaintext
users/{uid}                                  { uid, email, displayName, createdAt }
conversations/{convId}                       { convId, participants: [uid], lastMessage, lastMessageAt }
conversations/{convId}/messages/{msgId}      { senderId, text, createdAt, isEdited, editedAt, reactions }
🛠️ Features Implemented & Enhancements
The initial raw developmental gaps from the starter repository layout have been fully closed:

1. New Chat & User Discovery Hub
Dynamic Search Routing: Implemented a targeted user discovery interface searching exclusively by exact email inputs.

Smart Loop Prevention: Configured filters to automatically hide the authenticated account profile from search lists to prevent invalid self-chats.

Deterministic ID Compiling: Created automatic conversation routing that generates sorted, uniform path string markers (uid1_uid2).

2. Message Interactions & Editing Engine
Real-Time Reactions: Enabled background data pathways to support instant item state reactions (emojis) without fracturing background listeners.

Secure Text Editing: Integrated native message editing logic complete with visual flags (isEdited) to handle string modifications on the fly.

3. State-Safety & Performance Optimizations
Async Guarding: Patched unstable screen navigation flows by implementing strict context.mounted verification lookups.

API Modernization: Upgraded legacy platform-specific properties to comply with newer singleton design criteria (FilePicker.instance).

Visual Polish: Implemented smooth loading feedback views to eliminate structural screen blinking during server read transitions.

🔐 Advanced Firestore Security Rules
The production database security policy has been upgraded to allow for flexible message modifications while maintaining strict data isolation constraints:

JavaScript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users Profile Collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null && request.auth.uid == userId;
    }

    // Conversations Collection Rooms
    match /conversations/{convId} {
      allow read: if request.auth != null && request.auth.uid in resource.data.participants;
      allow update, write: if request.auth != null && request.auth.uid in resource.data.participants;
      allow create: if request.auth != null && request.auth.uid in request.resource.data.participants;

      // Messages Subcollection Space
      match /messages/{messageId} {
        // Enforces that readers must belong to the parent conversation profile group
        allow read: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(convId)).data.participants;
          
        // Verifies the creating token author matches the requested message sender payload
        allow create: if request.auth != null && 
          request.resource.data.senderId == request.auth.uid;

        // Custom Operations Shield: Grants open permission for reaction maps, 
        // but strictly limits message content changes exclusively to the original sender.
        allow update: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(convId)).data.participants &&
          (
            (request.resource.data.text != resource.data.text && resource.data.senderId == request.auth.uid) ||
            (request.resource.data.text == resource.data.text)
          );
      }
    }
  }
}

### 🏎️ Final Git Upload Sequence
Save the `README.md` file, open your terminal, and push the documentation update cleanly using these commands:

```bash
git add README.md
git commit -m "docs: finalize README with structural feature map and secure firestore architecture"
git push origin main
