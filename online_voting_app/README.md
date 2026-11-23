# Online Voting App

A secure online voting app built with **Flutter** and **Firebase**. Users sign in, vote once per poll, and watch results update live. Admins create and manage polls from a built-in admin panel.

## Demo

> Add your demo video link or GIF here.

## Screenshots

| Login | Polls | Voting | Admin |
|---|---|---|---|
| _add image_ | _add image_ | _add image_ | _add image_ |

Put your images in a `screenshots/` folder and link them here, for example `![Login](screenshots/login.png)`.

## Features

**For users**
- Register and sign in with email and password (Firebase Authentication)
- Browse all polls with colored status badges: Open, Upcoming, Ended, Closed
- Vote once per poll (a second vote is blocked)
- See live results with a bar and percentage for each option

**For admins**
- Create polls with a title, description, options, start time and duration
- Choose result visibility: live, after voting ends, or admins only
- Close a poll early or delete it
- View an activity log of logins, logouts, registrations and votes

## Tech Stack

- **Flutter** and **Dart**
- **Firebase Authentication** for login
- **Cloud Firestore** for real-time data
- **intl** for date formatting

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.3 or newer)
- A Firebase account
- An Android emulator or a physical device

### 1. Clone the project
```bash
git clone https://github.com/<your-username>/online_voting_app.git
cd online_voting_app
flutter pub get
```

### 2. Set up Firebase
1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Add an Android app with the package name `com.example.online_voting_app`.
3. Download `google-services.json` and place it in `android/app/`.
4. Go to **Authentication → Sign-in method** and enable **Email/Password**.
5. Go to **Firestore Database** and click **Create database**.

### 3. Firestore rules (development only)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
These rules are for testing. Tighten them before a real release, for example by letting only admins write to `polls`.

### 4. Run the app
```bash
flutter run
```

### 5. Make yourself an admin
1. Register an account in the app.
2. In Firestore, open `users/<your-uid>`.
3. Change the `role` field from `user` to `admin`.
4. The admin icon appears in the top bar.

## Firestore Data Model

| Collection | Document ID | Main fields |
|---|---|---|
| `users` | user UID | `email`, `role`, `createdAt` |
| `polls` | auto ID | `title`, `description`, `options`, `counts`, `startAt`, `endAt`, `visibility`, `closed`, `createdBy`, `createdAt` |
| `votes` | `<pollId>_<uid>` | `pollId`, `uid`, `option`, `at` |
| `activity` | auto ID | `uid`, `email`, `action`, `pollId`, `at` |

One vote per user is enforced by the vote document ID (`pollId_uid`) and a Firestore transaction.

## Project Structure

```
lib/
  main.dart      # app, login, polls, voting, results and admin panel
android/
  app/google-services.json   # not committed, add your own
```

## Security Notes

- Do not commit `google-services.json` or other private keys to a public repository. Add it to `.gitignore`.
- Use stricter Firestore rules in production.

## Future Improvements

- Dark mode
- Custom fonts and animated result bars
- Admin-only write rules and server-side vote counting
- Push notifications when a poll opens or closes
- Email verification

## Author

**Your Name**
[LinkedIn](https://linkedin.com/in/your-profile) · [GitHub](https://github.com/your-username)
