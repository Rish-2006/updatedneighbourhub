import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/journey_model.dart';
import '../../../data/repositories/journey_repository.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/location_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/providers/contact_provider.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository();
});

final activeJourneyStreamProvider = StreamProvider<JourneyModel?>((ref) {
  final repository = ref.watch(journeyRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  final userId = user?.uid ?? 'demo_user_123';
  return repository.watchActiveJourney(userId);
});

class JourneyController extends StateNotifier<AsyncValue<JourneyModel?>> {
  final JourneyRepository _repository;
  final Ref _ref;

  JourneyController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<JourneyModel?> startJourney({
    String? destinationName,
    bool isPanic = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authStateProvider).value;
      final userId = user?.uid ?? 'demo_user_123';

      final contacts = await _ref.read(contactRepositoryProvider).getContacts(userId);
      final contactIds = contacts.map((c) => c.id).toList();

      await LocationService.requestLocationPermissions();

      final journey = await _repository.startJourney(
        userId: userId,
        contactIds: contactIds,
        destinationName: destinationName,
        isPanicTriggered: isPanic,
      );

      final initialLoc = await LocationService.getCurrentLocation();
      await _repository.updateLocation(journeyId: journey.id, location: initialLoc);

      await BackgroundTrackingService.startTracking(journey.id);

      state = AsyncValue.data(journey);
      return journey;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> endJourney(String journeyId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.endJourney(journeyId);
      await BackgroundTrackingService.stopTracking();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendQuickPing() async {
    final user = _ref.read(authStateProvider).value;
    final userId = user?.uid ?? 'demo_user_123';

    final contacts = await _ref.read(contactRepositoryProvider).getContacts(userId);
    final contactIds = contacts.map((c) => c.id).toList();

    await LocationService.requestLocationPermissions();
    final loc = await LocationService.getCurrentLocation();

    await _repository.sendQuickPing(
      userId: userId,
      location: loc,
      contactIds: contactIds,
    );
  }
}

final journeyControllerProvider =
    StateNotifierProvider<JourneyController, AsyncValue<JourneyModel?>>((ref) {
  final repository = ref.watch(journeyRepositoryProvider);
  return JourneyController(repository, ref);
});

