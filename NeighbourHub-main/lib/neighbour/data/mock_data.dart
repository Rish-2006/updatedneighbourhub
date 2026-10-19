//
// MOCK DATA - Sample data for development and demonstration.
//
// This file contains realistic fake data so we can see the UI working
// even before connecting Firebase. When Firebase is connected,
// the services will fetch real data from Firestore instead.
//
// To switch from mock to real data: edit the services (auth_service.dart,
// firestore_service.dart) to use Firestore queries instead of this file.

import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import '../models/help_request_model.dart';

class MockData {
  MockData._(); // Private constructor - no one should create an instance

  // ─── Sample Users ──────────────────────────────────────────────────────────
  static final List<UserModel> users = [
    UserModel(
      id: 'user_001',
      name: 'Srinivas Madhu',
      email: 'srinivas@example.com',
      photoUrl: '',
      neighbourhood: 'Green Valley Community',
      apartment: 'Block A, Flat 302',
      bio: 'Computer Science student. Love cricket and biryani! 🏏',
      createdAt: DateTime(2024, 1, 10),
    ),
    UserModel(
      id: 'user_002',
      name: 'Priya Kumar',
      email: 'priya@example.com',
      photoUrl: '',
      neighbourhood: 'Green Valley Community',
      apartment: 'Block B, Flat 105',
      bio: 'UI/UX Designer. Coffee lover ☕. Always looking for collaboration!',
      createdAt: DateTime(2024, 1, 12),
    ),
    UserModel(
      id: 'user_003',
      name: 'Rahul Sharma',
      email: 'rahul@example.com',
      photoUrl: '',
      neighbourhood: 'Green Valley Community',
      apartment: 'Block A, Flat 201',
      bio: 'Software engineer at a startup. Weekend hiker 🏔️',
      createdAt: DateTime(2024, 1, 15),
    ),
    UserModel(
      id: 'user_004',
      name: 'Ananya Reddy',
      email: 'ananya@example.com',
      photoUrl: '',
      neighbourhood: 'Green Valley Community',
      apartment: 'Block C, Flat 410',
      bio: 'Doctor. Mom of two kids. Here to help the community! 🏥',
      createdAt: DateTime(2024, 1, 18),
    ),
    UserModel(
      id: 'user_005',
      name: 'Kiran Patel',
      email: 'kiran@example.com',
      photoUrl: '',
      neighbourhood: 'Green Valley Community',
      apartment: 'Block D, Flat 301',
      bio: 'Retired teacher. Active community member. 📚',
      createdAt: DateTime(2024, 1, 20),
    ),
  ];

  // ─── Sample Posts ─────────────────────────────────────────────────────────
  static final List<PostModel> posts = [
    PostModel(
      id: 'post_001',
      userId: 'user_001',
      userName: 'Srinivas Madhu',
      userPhoto: '',
      type: PostType.helpRequest,
      title: 'Looking for a good plumber',
      description:
          'Does anyone know a reliable plumber near our neighbourhood? The kitchen tap has been leaking for two days. Any recommendations would be really helpful!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likesCount: 12,
      commentsCount: 4,
      likedBy: ['user_002', 'user_003'],
    ),
    PostModel(
      id: 'post_002',
      userId: 'user_002',
      userName: 'Priya Kumar',
      userPhoto: '',
      type: PostType.lostFound,
      title: 'Found: Set of keys near community park',
      description:
          'Found a set of keys near the community park bench this morning. There are 3 keys on a blue key ring. Please contact me through the app if these are yours!',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      likesCount: 8,
      commentsCount: 3,
      likedBy: ['user_001', 'user_004'],
    ),
    PostModel(
      id: 'post_003',
      userId: 'user_003',
      userName: 'Rahul Sharma',
      userPhoto: '',
      type: PostType.announcement,
      title: 'Community Cleanup this Sunday!',
      description:
          'Let\'s make our neighbourhood clean and beautiful! Join us this Sunday at 8 AM near the main gate. Bring gloves if you have them. Refreshments will be arranged!',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      likesCount: 25,
      commentsCount: 7,
      likedBy: ['user_001', 'user_002', 'user_004', 'user_005'],
    ),
    PostModel(
      id: 'post_004',
      userId: 'user_004',
      userName: 'Ananya Reddy',
      userPhoto: '',
      type: PostType.general,
      title: 'Parking issue near Block B',
      description:
          'There are some vehicles parked in the no-parking zone near Block B entrance causing trouble for residents. Can the association please look into this?',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likesCount: 15,
      commentsCount: 9,
      likedBy: ['user_001', 'user_003', 'user_005'],
    ),
    PostModel(
      id: 'post_005',
      userId: 'user_005',
      userName: 'Kiran Patel',
      userPhoto: '',
      type: PostType.recommendation,
      title: 'Best dal makhani near us!',
      description:
          'Tried the new dhaba that opened near the main road. Their dal makhani and butter naan is absolutely amazing! Highly recommended for a family dinner outing.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      likesCount: 32,
      commentsCount: 12,
      likedBy: ['user_001', 'user_002', 'user_003'],
    ),
  ];

  // ─── Sample Events ────────────────────────────────────────────────────────
  static final List<EventModel> events = [
    EventModel(
      id: 'event_001',
      title: 'Community Cleanup Drive',
      description:
          'Join us for a monthly neighbourhood cleanup. Let\'s work together to keep Green Valley clean and beautiful for everyone!',
      emoji: '🧹',
      date: DateTime.now().add(const Duration(days: 3, hours: 6)),
      place: 'Main Gate, Green Valley',
      startTime: '8:00 AM',
      endTime: '11:00 AM',
      createdBy: 'user_003',
      createdByName: 'Rahul Sharma',
      participants: ['user_001', 'user_002', 'user_005'],
    ),
    EventModel(
      id: 'event_002',
      title: 'Morning Run',
      description:
          'Weekly morning run around the neighbourhood park. All fitness levels welcome! We run, chat, and enjoy the fresh morning air.',
      emoji: '🏃',
      date: DateTime.now().add(const Duration(days: 5, hours: 4, minutes: 30)),
      place: 'Community Park Entrance',
      startTime: '6:00 AM',
      endTime: '7:30 AM',
      createdBy: 'user_001',
      createdByName: 'Srinivas Madhu',
      participants: ['user_003', 'user_004'],
    ),
    EventModel(
      id: 'event_003',
      title: 'Residents Meeting',
      description:
          'Monthly residents association meeting. Agenda: water supply issues, security update, maintenance fund discussion, and upcoming festival plans.',
      emoji: '🏘️',
      date: DateTime.now().add(const Duration(days: 7, hours: 11)),
      place: 'Community Hall, Block A',
      startTime: '11:00 AM',
      endTime: '1:00 PM',
      createdBy: 'user_005',
      createdByName: 'Kiran Patel',
      participants: [
        'user_001',
        'user_002',
        'user_003',
        'user_004',
        'user_005',
      ],
    ),
    EventModel(
      id: 'event_004',
      title: 'Blood Donation Camp',
      description:
          'Free blood donation camp organized by the residents association in collaboration with City Hospital. All donors get certificates and refreshments.',
      emoji: '🩸',
      date: DateTime.now().add(const Duration(days: 10, hours: 9)),
      place: 'Community Hall Lobby',
      startTime: '9:00 AM',
      endTime: '2:00 PM',
      createdBy: 'user_004',
      createdByName: 'Ananya Reddy',
      participants: ['user_001', 'user_005'],
    ),
  ];

  // ─── Sample Notifications ─────────────────────────────────────────────────
  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'notif_001',
      userId: 'user_001',
      title: 'New comment on your post',
      message:
          'Priya Kumar commented on your post "Looking for a good plumber"',
      type: NotificationType.comment,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    NotificationModel(
      id: 'notif_002',
      userId: 'user_001',
      title: 'Community Announcement',
      message:
          'Water maintenance will take place this Saturday from 10 AM to 1 PM.',
      type: NotificationType.announcement,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'notif_003',
      userId: 'user_001',
      title: 'Event Reminder',
      message: 'Community Cleanup Drive is in 3 days. Don\'t forget to join!',
      type: NotificationType.event,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NotificationModel(
      id: 'notif_004',
      userId: 'user_001',
      title: 'Someone liked your post',
      message: 'Rahul Sharma liked your post.',
      type: NotificationType.like,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'notif_005',
      userId: 'user_001',
      title: 'Response to your help request',
      message: 'Ananya Reddy responded to your help request about the plumber.',
      type: NotificationType.helpResponse,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // ─── Sample Help Requests ─────────────────────────────────────────────────
  static final List<HelpRequestModel> helpRequests = [
    HelpRequestModel(
      id: 'help_001',
      userId: 'user_001',
      userName: 'Srinivas Madhu',
      userPhoto: '',
      title: 'Looking for a good electrician',
      description:
          'The power socket in my living room has stopped working. Can anyone recommend a trusted electrician who works in our area?',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      responseCount: 2,
    ),
    HelpRequestModel(
      id: 'help_002',
      userId: 'user_002',
      userName: 'Priya Kumar',
      userPhoto: '',
      title: 'Can someone lend a ladder?',
      description:
          'I need a ladder for a couple of hours to fix a light fitting. Will return it the same day. Anyone who can help?',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      responseCount: 1,
    ),
    HelpRequestModel(
      id: 'help_003',
      userId: 'user_004',
      userName: 'Ananya Reddy',
      userPhoto: '',
      title: 'Help needed with furniture moving',
      description:
          'Moving to a new flat in Block C this weekend. Looking for 2-3 people who can help carry furniture. Will provide lunch and snacks!',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      responseCount: 4,
      isResolved: true,
    ),
  ];

  // ─── Sample Announcements ─────────────────────────────────────────────────
  static final List<Map<String, String>> announcements = [
    {
      'title': 'Water Maintenance on Saturday',
      'message':
          'Water supply will be interrupted on Saturday from 10:00 AM to 1:00 PM for routine maintenance. Please store water in advance.',
      'date': 'Sep 20, 2026',
      'postedBy': 'Association Committee',
    },
    {
      'title': 'Security Camera Installation',
      'message':
          'New CCTV cameras will be installed at all entrance/exit points on Monday and Tuesday. Please cooperate with the technicians.',
      'date': 'Sep 18, 2026',
      'postedBy': 'Association Committee',
    },
    {
      'title': 'New Park Benches',
      'message':
          'The association has added 4 new benches in the community park. Please maintain them and do not damage public property.',
      'date': 'Sep 15, 2026',
      'postedBy': 'Association Committee',
    },
  ];

  // ─── Sample Community Rules ───────────────────────────────────────────────
  static final List<String> communityRules = [
    'Maintain silence after 10:00 PM in residential areas.',
    'No vehicles allowed in the children\'s play area.',
    'Garbage must be disposed in designated bins only.',
    'Common areas should be kept clean and tidy.',
    'Pets must be kept on a leash in common areas.',
    'Visitors must be registered at the security gate.',
    'No loud music in apartments or common areas.',
    'Community decisions are made by majority vote in monthly meetings.',
  ];

  // ─── Lost & Found Items ───────────────────────────────────────────────────
  static final List<Map<String, dynamic>> lostFoundItems = [
    {
      'id': 'lf_001',
      'type': 'found',
      'title': 'Black Wallet',
      'description':
          'Found a black leather wallet near the community park entrance. Contains cards (no cash). Reach out through the app.',
      'location': 'Community Park',
      'postedBy': 'Srinivas Madhu',
      'postedById': 'user_001',
      'date': '2 hours ago',
      'isResolved': false,
    },
    {
      'id': 'lf_002',
      'type': 'lost',
      'title': 'Blue Backpack',
      'description':
          'Lost my blue Wildcraft backpack with my laptop charger inside. Last seen near the main gate security cabin. Very urgent!',
      'location': 'Near Main Gate',
      'postedBy': 'Rahul Sharma',
      'postedById': 'user_003',
      'date': '5 hours ago',
      'isResolved': false,
    },
    {
      'id': 'lf_003',
      'type': 'found',
      'title': 'Keys (Set of 3)',
      'description':
          'Found a set of keys on a blue key ring near the park bench. Please claim them soon.',
      'location': 'Community Park',
      'postedBy': 'Priya Kumar',
      'postedById': 'user_002',
      'date': '1 day ago',
      'isResolved': true,
    },
  ];
}
