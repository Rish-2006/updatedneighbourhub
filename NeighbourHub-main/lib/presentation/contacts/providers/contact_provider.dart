import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../auth/providers/auth_provider.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository();
});

final contactsStreamProvider = StreamProvider<List<ContactModel>>((ref) {
  final repository = ref.watch(contactRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  final userId = user?.uid ?? 'demo_user_123';
  return repository.getContactsStream(userId);
});

class ContactController extends StateNotifier<AsyncValue<void>> {
  final ContactRepository _repository;
  final Ref _ref;

  ContactController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> addContact({
    required String name,
    required String phone,
    required String email,
    String? relationship,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authStateProvider).value;
      final userId = user?.uid ?? 'demo_user_123';

      final contact = ContactModel(
        id: const Uuid().v4(),
        name: name,
        phone: phone,
        email: email,
        relationship: relationship,
        addedAt: DateTime.now(),
      );

      await _repository.addContact(userId, contact);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> deleteContact(String contactId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authStateProvider).value;
      final userId = user?.uid ?? 'demo_user_123';
      await _repository.deleteContact(userId, contactId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final contactControllerProvider =
    StateNotifierProvider<ContactController, AsyncValue<void>>((ref) {
  final repository = ref.watch(contactRepositoryProvider);
  return ContactController(repository, ref);
});
