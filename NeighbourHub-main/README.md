# NeighbourHub

> **Your neighbourhood, connected.**

A Flutter mobile application that brings residents of an apartment community together — making it easy to communicate, stay informed, help each other, and manage shared concerns.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Objectives](#objectives)
3. [Key Features](#key-features)
4. [User Features](#user-features)
5. [Admin Features](#admin-features)
6. [Technology Stack](#technology-stack)
7. [Application Architecture](#application-architecture)
8. [Project Structure](#project-structure)
9. [Firebase Configuration](#firebase-configuration)
10. [Requirements](#requirements)
11. [Installation](#installation)
12. [Running the Application](#running-the-application)
13. [User Flow](#user-flow)
14. [Admin Flow](#admin-flow)
15. [Database Structure](#database-structure)
16. [Screenshots](#screenshots)
17. [Security](#security)
18. [Future Enhancements](#future-enhancements)
19. [Limitations](#limitations)
20. [Project Information](#project-information)
21. [License](#license)

---

## Project Overview

**NeighbourHub** is a community management mobile application built with Flutter and Firebase. It is designed for residents of an apartment complex or residential society to stay connected, communicate, and coordinate with each other and with their community administrator.

### The Problem It Solves

In most apartment communities, residents face challenges such as:
- No easy way to reach out to neighbours or the management committee.
- Difficulty reporting maintenance or community issues.
- No centralised platform for community events, announcements, or lost-and-found items.
- Lack of a way to request help from neighbours in emergencies.

### How It Helps

NeighbourHub provides a single, unified platform where:
- Residents can **connect** with their neighbours.
- Community **issues** can be reported and tracked.
- **Announcements** and **events** from the management are accessible to everyone.
- Residents can post **community posts** and interact with each other.
- **Help requests** can be sent to neighbours.
- **Emergency alerts** can be broadcast to the entire community.
- **Lost and found** items can be listed and claimed.
- The **admin** can manage users, verify flat assignments, handle issue reports, create announcements, and organise events.

---

## Objectives

- Build a mobile platform that connects residents of an apartment community.
- Allow users to register/login using email or Google Sign-In.
- Enable residents to post community updates, share help requests, and communicate.
- Provide a way to report maintenance and community issues to the admin.
- Allow residents to send and manage emergency community alerts.
- Allow the admin to manage users, issues, events, announcements, and flat verification.
- Implement a secure role-based system (admin vs regular user) using Firebase.
- Provide real-time data synchronisation using Cloud Firestore.

---

## Key Features

### Authentication
- **Email and Password Login/Registration** — Users can create an account and log in with their email and password.
- **Google Sign-In** — One-tap login using a Google account.
- **Forgot Password** — Password reset via email is supported.
- **Auth State Management** — The app automatically navigates to the correct screen based on login state.

### Community Posts
- Users can create posts in the community feed with a title, description, and category (General, Help Request, Recommendation, Announcement, Safety, Lost and Found).
- Posts appear in a real-time feed visible to all community members.
- Users can **like** and **comment** on posts.
- Users can view their own posts from their profile.

### Neighbours and Connections
- Browse all registered community members.
- Send, accept, or decline **connection requests**.
- View a list of all connected neighbours.
- View a neighbour's profile.
- Remove a connection (disconnect).
- Filter the neighbours list by connection status (All, Connected, Pending, Available).
- Search for neighbours by name.

### Help Requests
- Post a help request asking neighbours for assistance (e.g., "Looking for an electrician").
- Browse open help requests from the community.

### Emergency Community Alert
- Send a **community-wide emergency alert** with a single button press.
- The alert is broadcast to all registered users as an in-app notification.
- Recipients can view alert details (sender name and apartment) from the Notifications screen.
- A confirmation dialog prevents accidental alerts.

> **Disclaimer:** The emergency alert feature is a community notification tool only. It does **not** replace official emergency services (100 - Police, 108 - Ambulance, 101 - Fire).

### Issue Reporting
- Report a community issue with a title, description, and category (Maintenance, Electrical, Plumbing, Lift, Security, Parking, Cleaning, Noise, Amenities, Other).
- Track the status of submitted issues (Pending, In Progress, Resolved).
- View a detailed timeline for each issue from the profile.

### Community Events
- View upcoming community events with details (title, description, date, time, venue).
- Join an event (registers the user as a participant).
- Events are created and managed by the admin.

### Community Announcements
- View the latest community announcements posted by the admin.
- Full announcements list available in the Community section.

### Lost and Found
- Post a **lost** or **found** item with title, category, description, and location.
- Browse the community lost and found board.
- Submit a **claim** on a found item or provide a tip on a lost item.
- Item owner can accept or reject claims.
- Item status progresses: Active, ClaimPending, Returned, Closed.
- Notifications are sent to the item owner when a claim is submitted.

### Flat Number and Verification
- Users can request a flat number from their profile.
- The request is submitted to the admin for approval.
- Once approved, the flat number appears on their profile.
- Prevents duplicate flat assignments (one flat per account).

### Service Providers
- Browse community-recommended service providers (e.g., plumbers, electricians) by category.
- Service providers are managed by the admin through Firestore.

### Notifications
- Real-time in-app notifications for: emergency alerts, issue status updates, flat verification results, lost and found claim updates, and general notifications.
- Mark individual or all notifications as read.
- Emergency notifications open a detailed view on tap.

### User Profile
- View and edit profile information (name, bio, neighbourhood, apartment).
- View own posts and reported issues.
- Request and display verified flat number.
- Access app settings.

### Settings
- Toggle between **light and dark mode** (preference is saved locally).
- View app information (About NeighbourHub).
- Access Help and Support contact information.
- Logout.

---

## User Features

A standard (non-admin) user can:

| Feature | Description |
|---|---|
| Register / Login | Sign up with email or Google account |
| Community Feed | View, create, like, and comment on community posts |
| Neighbours | Browse, search, connect/disconnect from neighbours |
| Connection Requests | Send, accept, and decline connection requests |
| View Neighbour Profile | See another resident's name, bio, and flat number |
| Help Requests | Post a help request and browse others' requests |
| Emergency Alert | Send a community-wide alert in urgent situations |
| Report Issue | Submit a maintenance or community issue report |
| Track My Issues | View the status of personally submitted issue reports |
| Community Events | View upcoming events and join them |
| Announcements | Read community announcements from the admin |
| Lost and Found | Post, browse, and claim lost or found items |
| Service Providers | Browse recommended service providers |
| Notifications | Receive and manage real-time in-app notifications |
| Profile | View and edit personal profile |
| Flat Verification | Request a flat number assignment from the admin |
| Settings | Toggle dark/light mode, logout |

---

## Admin Features

The administrator has access to a dedicated **Admin Dashboard** with 5 management tabs. Admin access is determined by a specific email address configured in Firestore Security Rules.

| Feature | Description |
|---|---|
| Reports Management | View all submitted issue reports, filter by status (Pending / In Progress / Resolved) |
| Update Report Status | Change a report status to Pending, In Progress, or Resolved; user receives a notification automatically |
| Announcements | Create and publish community-wide announcements |
| Flat Verification | View, approve, or reject flat number requests from residents; uses atomic Firestore transactions to prevent duplicate assignments |
| User Management | View all registered users, search by name, delete user data |
| Events Management | Create, edit, and delete community events; view event registration lists |
| Admin Logout | Dedicated logout from the admin dashboard |

---

## Technology Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform mobile UI framework |
| **Dart** | Programming language used with Flutter |
| **Firebase Core** | Firebase SDK initialisation |
| **Firebase Authentication** | User login (Email/Password and Google Sign-In) |
| **Cloud Firestore** | Real-time NoSQL database for all app data |
| **Firebase Storage** | Storage service included in project dependencies |
| **Firebase Cloud Messaging** | Push notification infrastructure (dependency included) |
| **Google Sign-In** | Google account authentication |
| **Provider** | State management (auth state, theme) |
| **go_router** | Navigation routing |
| **flutter_animate** | UI animations and transitions |
| **shared_preferences** | Persisting local settings (dark mode preference) |
| **image_picker** | Selecting images from device gallery/camera |
| **cached_network_image** | Efficiently loading and caching network images |
| **google_fonts** | Custom typography |
| **geolocator** | Device location access |
| **flutter_local_notifications** | Local push notifications |
| **flutter_background_service** | Background processing service |
| **sensors_plus** | Device sensor access |
| **audioplayers** | Audio playback |
| **vibration** | Device vibration control |
| **battery_plus** | Battery status monitoring |
| **flutter_map + latlong2** | Map rendering support |
| **timeago** | Human-readable timestamps (e.g., "5 minutes ago") |
| **uuid** | Generating unique IDs for posts and comments |
| **intl** | Internationalisation and date/time formatting |
| **url_launcher** | Opening URLs in the browser |
| **googleapis / googleapis_auth** | Google API authentication helpers |

---

## Application Architecture

NeighbourHub follows a layered, service-oriented architecture:

```
+------------------------------------------+
|          User (Mobile Device)            |
+--------------------+---------------------+
                     |
+--------------------v---------------------+
|          Flutter Application             |
|                                          |
|  +---------+  +----------+  +--------+  |
|  | Screens |  | Widgets  |  | Models |  |
|  +----+----+  +----+-----+  +---+----+  |
|       +------------+-----------+         |
|                    |                     |
|  +-----------------v----------------+   |
|  |           Services               |   |
|  |  AuthService  |  FirestoreService|   |
|  +-----------------+----------------+   |
+---------------------+--------------------+
                      |
+---------------------v--------------------+
|           Firebase Platform              |
|                                          |
|  +-----------------+ +----------------+  |
|  | Firebase Auth   | | Cloud Firestore|  |
|  +-----------------+ +----------------+  |
+------------------------------------------+
```

**State Management:** The application uses the `Provider` package. `AuthService` (a `ChangeNotifier`) manages authentication state, and `FirestoreService` handles all database interactions. A `ThemeController` manages the light/dark mode preference.

**Navigation:** Named routes (`AppRoutes`) and direct `Navigator.push` calls are used for screen navigation.

**Real-time Updates:** Firestore `StreamBuilder` widgets are used throughout the app to display live data (posts, events, notifications, connections, etc.) without requiring manual refresh.

---

## Project Structure

```
lib/
+-- main.dart                          # Entry point, app widget, auth wrapper
+-- firebase_options.dart              # Firebase configuration (auto-generated)
+-- constants.dart                     # App-level constants (e.g., admin email)
|
+-- data/
|   +-- mock_data.dart                 # Seed data for events, notifications, help requests
|
+-- models/                            # Data models (Firestore <-> Dart)
|   +-- user_model.dart
|   +-- post_model.dart
|   +-- comment_model.dart
|   +-- event_model.dart
|   +-- help_request_model.dart
|   +-- lost_found_model.dart
|   +-- announcement_model.dart
|   +-- notification_model.dart
|   +-- connection_model.dart
|   +-- connection_request_model.dart
|
+-- services/                          # Business logic and Firebase access
|   +-- auth_service.dart              # Firebase Auth (email, Google, logout)
|   +-- firestore_service.dart         # All Firestore read/write operations
|   +-- storage_service.dart           # Firebase Storage helper
|
+-- theme/
|   +-- app_theme.dart                 # Light and dark theme definitions
|
+-- routes/
|   +-- app_routes.dart                # Named route constants
|
+-- widgets/                           # Reusable UI components
|   +-- post_card.dart
|   +-- event_card.dart
|   +-- neighbour_card.dart
|   +-- notification_card.dart
|   +-- custom_button.dart
|
+-- screens/
    +-- auth/
    |   +-- login_screen.dart           # Login (email + Google)
    |   +-- register_screen.dart        # New account registration
    |
    +-- home/
    |   +-- home_screen.dart            # Main shell with bottom navigation
    |
    +-- posts/
    |   +-- create_post_screen.dart     # Create a new community post
    |   +-- post_details_screen.dart    # View post and comments
    |
    +-- neighbours/
    |   +-- neighbours_screen.dart      # Community members directory
    |   +-- my_neighbours_screen.dart   # Connected neighbours list
    |   +-- neighbour_profile_screen.dart  # View another user's profile
    |   +-- connection_requests_screen.dart  # Incoming connection requests
    |
    +-- community/
    |   +-- community_screen.dart       # Community hub (announcements, events, services)
    |   +-- announcements_screen.dart   # Full announcements list
    |   +-- events_screen.dart          # Upcoming events list
    |   +-- event_details_screen.dart   # Single event view and join
    |   +-- service_providers_screen.dart   # Service providers by category
    |   +-- service_provider_details_screen.dart  # Service provider detail
    |
    +-- help/
    |   +-- help_screen.dart            # Help requests board
    |
    +-- lost_found/
    |   +-- lost_found_screen.dart      # Lost and found board and claim flow
    |
    +-- safety/
    |   +-- emergency_screen.dart       # Emergency alert sender
    |   +-- report_issue_screen.dart    # Report a community issue
    |   +-- emergency_alert_detail_sheet.dart  # Emergency notification detail
    |
    +-- notifications/
    |   +-- notifications_screen.dart   # In-app notifications list
    |
    +-- profile/
    |   +-- profile_screen.dart         # User profile view
    |   +-- edit_profile_screen.dart    # Edit name, bio, neighbourhood
    |   +-- flat_number_section.dart    # Flat verification widget
    |   +-- my_posts_screen.dart        # User's own posts
    |   +-- my_issues_screen.dart       # User's submitted issue reports
    |   +-- issue_timeline_screen.dart  # Issue status timeline
    |   +-- settings_screen.dart        # App settings (dark mode, logout)
    |
    +-- admin/
        +-- admin_dashboard_screen.dart  # Admin panel with 5 tabs
        +-- admin_report_details_screen.dart  # View and update report status
        +-- admin_users_screen.dart      # Manage registered users
        +-- admin_events_screen.dart     # Create, edit, delete events
        +-- create_announcement_screen.dart   # Post an announcement
        +-- flat_verification_screen.dart     # Approve/reject flat requests
```

---

## Firebase Configuration

### Services Used

| Service | What It Is Used For |
|---|---|
| **Firebase Authentication** | Email/password registration and login, Google Sign-In, password reset |
| **Cloud Firestore** | All app data: users, posts, events, reports, notifications, connections, announcements, lost and found items |
| **Firebase Storage** | Dependency included; storage service available for future media uploads |
| **Firebase Cloud Messaging** | Dependency included for push notification infrastructure |

### Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | Stores user profiles (name, email, photo, neighbourhood, flat number, verification status) |
| `posts` | Community posts with likes and comment counts |
| `comments` | Comments on community posts |
| `events` | Community events (title, date, time, venue, participants) |
| `event_registrations` | Records of users who have joined events |
| `reports` | Issue reports submitted by residents |
| `notifications` | In-app notifications for each user |
| `community_alerts` | Emergency alert documents broadcast to the community |
| `announcements` | Announcements created by the admin |
| `connection_requests` | Pending/accepted/rejected neighbour connection requests |
| `connections` | Confirmed neighbour connections between users |
| `lost_found` | Lost and found item listings |
| `lost_found_claims` | Claims submitted on lost/found items |
| `flat_verification_requests` | Flat number requests submitted by users for admin approval |
| `flat_assignments` | Approved flat-to-user assignments (prevents duplicates) |
| `service_providers` | Community service providers managed by the admin |

> **Note:** Firebase API keys, project credentials, and `google-services.json` are **not** included in this repository. You must configure your own Firebase project to run this application.

---

## Requirements

| Requirement | Details |
|---|---|
| **Flutter SDK** | `^3.12.2` (or compatible) |
| **Dart SDK** | `^3.12.2` |
| **Android SDK** | API Level 21 (Android 5.0) or higher |
| **Firebase Project** | A configured Firebase project with Authentication and Firestore enabled |
| **Google Services File** | `google-services.json` placed in `android/app/` |
| **Operating System** | Windows / macOS / Linux (for development) |
| **IDE** | VS Code or Android Studio (recommended) |

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/SrinivasMadhu/NeighbourHub.git
cd NeighbourHub
```

### 2. Set Up Firebase

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new project (or use an existing one).
3. Enable **Authentication** (Email/Password and Google Sign-In providers).
4. Enable **Cloud Firestore**.
5. Download the `google-services.json` file.
6. Place it at: `android/app/google-services.json`
7. Run the FlutterFire CLI to generate `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 3. Install Dependencies

```bash
flutter pub get
```

---

## Running the Application

### Check Connected Devices

```bash
flutter devices
```

### Run in Debug Mode

```bash
flutter run
```

### Run on a Specific Device

```bash
flutter run -d <device-id>
```

### Build a Release APK

```bash
flutter build apk --release
```

The release APK is generated at:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## User Flow

```
App Launch
    |
    v
Auth Check (Firebase Auth State)
    |
    +---- Not Logged In ----> Login Screen
    |                              |
    |                    +---------+-----------+
    |                    |                     |
    |               Email Login          Google Sign-In
    |                    |                     |
    |                    +---------+-----------+
    |                              |
    +---- Logged In ---------------+
                                   |
                                   v
                              Home Screen
                         (Bottom Navigation Bar)
                                   |
         +--------+----------+-----+----------+----------+
         |        |          |                |           |
        Home  Neighbours  Community     Notifications  Profile
         |        |          |                |           |
       Feed    Members    Events         Read/Mark    Edit Profile
         |     Search    Announce       Notifications  My Posts
         |    Connect   Lost+Found                     My Issues
       Create   My       Service                       Flat No.
       Post   Neighbours Providers                    Settings
         |
      View Post
      Like / Comment
         |
      Emergency Alert  <-- Quick Action Button
      Report Issue     <-- Quick Action Button
```

---

## Admin Flow

The admin account is identified by a specific email address. When the admin logs in, they are directed to the **Admin Dashboard** instead of the regular home screen.

```
Admin Login
    |
    v
Admin Dashboard (5 tabs)
    |
    +-- Reports Tab
    |       +-- View all submitted issue reports
    |       +-- Filter by status (All / Pending / In Progress / Resolved)
    |       +-- Open report -> Update status -> User receives notification
    |
    +-- Announcements Tab
    |       +-- View existing announcements
    |       +-- Create new announcement -> Published to all users
    |
    +-- Flats Tab
    |       +-- View flat verification requests (Pending)
    |       +-- Approve request -> Flat assigned, user notified
    |       +-- Reject request -> User notified
    |
    +-- Users Tab
    |       +-- View all registered users
    |       +-- Search by name
    |       +-- Delete user -> All user data removed from Firestore
    |
    +-- Events Tab
            +-- View all events
            +-- Create new event (title, date, time, venue)
            +-- Edit existing event
            +-- View registered participants
            +-- Delete event -> Registrations also removed
```

---

## Database Structure

### `users` Collection

| Field | Type | Description |
|---|---|---|
| `name` | String | Full name |
| `email` | String | Email address |
| `photoUrl` | String | Profile photo URL |
| `neighbourhood` | String | Community/neighbourhood name |
| `apartment` | String | Flat/apartment identifier |
| `bio` | String | Short user bio |
| `createdAt` | Number | Account creation timestamp (milliseconds) |
| `flatNumber` | String | Verified flat number (set by admin on approval) |
| `flatVerificationStatus` | String | `Pending`, `Verified`, or `Rejected` |

### `posts` Collection

| Field | Type | Description |
|---|---|---|
| `userId` | String | Author's UID |
| `userName` | String | Author's display name |
| `userPhoto` | String | Author's photo URL |
| `type` | String | Post category (general, helpRequest, recommendation, announcement, safety, lostFound) |
| `title` | String | Post title |
| `description` | String | Post body |
| `imageUrl` | String | Optional attached image URL |
| `likesCount` | Number | Total number of likes |
| `commentsCount` | Number | Total number of comments |
| `likedBy` | Array | List of user IDs who liked the post |
| `createdAt` | Timestamp | When the post was created |

### `reports` Collection

| Field | Type | Description |
|---|---|---|
| `userId` | String | Reporter's UID |
| `userName` | String | Reporter's display name |
| `userEmail` | String | Reporter's email |
| `title` | String | Issue title |
| `description` | String | Issue description |
| `category` | String | Issue category (Maintenance, Plumbing, Electrical, etc.) |
| `status` | String | `Pending`, `In Progress`, or `Resolved` |
| `createdAt` | Timestamp | Submission timestamp |

### `events` Collection

| Field | Type | Description |
|---|---|---|
| `title` | String | Event name |
| `description` | String | Event details |
| `date` | Timestamp | Event date |
| `startTime` | String | Start time (e.g., "10:00 AM") |
| `endTime` | String | End time (e.g., "12:00 PM") |
| `place` | String | Venue |
| `additionalDetails` | String | Extra information |
| `createdBy` | String | Admin's UID |
| `createdByName` | String | Admin's display name |
| `participants` | Array | List of user IDs who joined the event |

### `notifications` Collection

| Field | Type | Description |
|---|---|---|
| `userId` | String | Recipient's UID |
| `title` | String | Notification heading |
| `message` | String | Notification body |
| `type` | String | One of: like, comment, event, announcement, helpResponse, issueStatus, emergency, general |
| `isRead` | Boolean | Whether the user has seen it |
| `createdAt` | Timestamp | When the notification was created |

### `lost_found` Collection

| Field | Type | Description |
|---|---|---|
| `type` | String | `lost` or `found` |
| `title` | String | Item name |
| `category` | String | Item category |
| `description` | String | Item description |
| `location` | String | Where it was lost or found |
| `postedBy` | String | Poster's display name |
| `postedById` | String | Poster's UID |
| `status` | String | `Active`, `ClaimPending`, `Returned`, or `Closed` |
| `createdAt` | Timestamp | Post creation timestamp |

### `connection_requests` Collection

| Field | Type | Description |
|---|---|---|
| `senderId` | String | Requesting user's UID |
| `senderName` | String | Requesting user's name |
| `receiverId` | String | Target user's UID |
| `receiverName` | String | Target user's name |
| `status` | String | `pending`, `accepted`, or `rejected` |
| `createdAt` | Timestamp | When the request was sent |

---

## Screenshots

Screenshots should be placed in a `screenshots/` folder at the root of the repository.

```
screenshots/
+-- login.png
+-- home_feed.png
+-- neighbours.png
+-- community.png
+-- lost_found.png
+-- emergency.png
+-- report_issue.png
+-- notifications.png
+-- profile.png
+-- admin_dashboard.png
```

To embed screenshots in this README once added:

```markdown
![Login Screen](screenshots/login.png)
![Home Feed](screenshots/home_feed.png)
![Admin Dashboard](screenshots/admin_dashboard.png)
```

---

## Security

### Authentication
- All users must authenticate via Firebase Authentication before accessing any feature.
- The app checks authentication state on launch and directs users to the correct screen automatically.

### Firestore Security Rules
Firestore Security Rules are defined in `firestore.rules` and enforce the following:
- Users can only read and write their **own** data where applicable.
- Post likes and comment counts can be updated by any authenticated user, but post content can only be edited by the author.
- **Admin-only** write access is enforced for: `announcements`, `flat_assignments`, `service_providers`, and event creation/deletion — based on the admin's registered email.
- Lost and Found claims can only be accepted or rejected by the item owner.
- Connection requests can only be accepted or rejected by the intended receiver.

### Admin Access
- Admin functionality is restricted to a single designated account identified by email address.
- The admin email is referenced in Firestore Security Rules and in the app's `constants.dart` file.
- Users cannot grant themselves admin privileges — there is no self-promotion mechanism.

### Sensitive Credentials
- Firebase configuration files (`google-services.json`, `firebase_options.dart`) contain project-specific credentials and are **not** committed to this repository.
- The `.gitignore` file is configured to exclude sensitive files.

---

## Future Enhancements

The following features are **not currently implemented** but are realistic improvements for future versions:

- **Push Notifications via FCM** — Send real push notifications to devices even when the app is closed, using Firebase Cloud Messaging (the dependency is already included in the project).
- **Image Attachments in Posts** — Allow users to attach photos when creating posts (Firebase Storage dependency is already set up).
- **In-App Messaging** — Direct messages between connected neighbours.
- **Role Management via Admin Panel** — Ability to designate multiple admins from within the app.
- **Map Integration** — Visualise lost and found item locations using the included `flutter_map` package.
- **Event RSVP Reminders** — Notify users of upcoming events they have joined.
- **Admin Analytics Dashboard** — Charts and statistics about community activity.
- **iOS Support** — Configure and test the app on iOS devices.
- **Multilingual Support** — Add support for regional languages using Flutter's internationalisation tools.
- **Community Rules Section** — A dedicated page for displaying community guidelines and bylaws.

---

## Limitations

Based on the current implementation:

- **Admin role is email-based** — Admin access is determined by a hard-coded email address in Firestore Security Rules. A more scalable solution would use custom Firebase Auth claims.
- **Help requests are in-memory only** — The help request feature uses mock/in-memory data and is not fully persisted to Firestore across app sessions.
- **No background push notifications** — Emergency alerts and status updates appear as in-app notifications only when the app is open. Full background push notifications via FCM are not yet implemented.
- **No image upload** — The image URL field exists in post and report data models, but photo upload from the create screens is not implemented in this version.
- **Android only** — The app has been developed and tested for Android. iOS configuration has not been set up.
- **Single community** — All registered users share the same community space. Multi-community support is not implemented.

---

## Project Information

| Property | Details |
|---|---|
| **Project Name** | NeighbourHub |
| **Platform** | Flutter / Android |
| **Version** | 1.0.0 |
| **Repository** | https://github.com/SrinivasMadhu/NeighbourHub |
| **Firebase Project** | neighbourhub-c0dfc |
| **Developer** | Srinivas Madhu |

---

## License

No license file is currently included in this project. A license can be added if required.

For a college/academic project, the [MIT License](https://opensource.org/licenses/MIT) is a common and permissive choice.

---

*NeighbourHub — Your neighbourhood, connected.*
