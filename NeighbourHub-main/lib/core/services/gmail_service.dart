import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/auth/providers/auth_provider.dart';

final gmailServiceProvider = Provider<GmailService>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return GmailService(authRepo.googleSignInInstance);
});

class GmailService {
  final GoogleSignIn _googleSignIn;

  GmailService(this._googleSignIn);

  Future<bool> requestGmailAccess() async {
    final scopes = ['https://www.googleapis.com/auth/gmail.readonly'];
    try {
      final granted = await _googleSignIn.requestScopes(scopes);
      return granted;
    } catch (e) {
      return false;
    }
  }

  Future<List<Message>> fetchRecentEmails({int maxResults = 10}) async {
    try {
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) {
        throw Exception('Not authenticated with Google');
      }

      final gmailApi = GmailApi(client);
      
      // Get the list of message IDs
      final response = await gmailApi.users.messages.list('me', maxResults: maxResults);
      
      if (response.messages == null || response.messages!.isEmpty) {
        return [];
      }

      // Fetch the full details for each message
      List<Message> fullMessages = [];
      for (var msg in response.messages!) {
        if (msg.id != null) {
          final fullMsg = await gmailApi.users.messages.get('me', msg.id!);
          fullMessages.add(fullMsg);
        }
      }
      
      return fullMessages;
    } catch (e) {
      throw Exception('Failed to fetch emails: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return 0;
      
      final gmailApi = GmailApi(client);
      final response = await gmailApi.users.labels.get('me', 'INBOX');
      return response.messagesUnread ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
