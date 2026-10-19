import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/journey_model.dart';
import '../../../data/models/location_point.dart';
import '../../../shared/widgets/pulse_indicator.dart';
import '../../journey/providers/journey_provider.dart';

class ContactLiveTrackingScreen extends ConsumerWidget {
  final String journeyId;

  const ContactLiveTrackingScreen({
    super.key,
    required this.journeyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(journeyRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('In-App Circle Tracking'),
      ),
      body: StreamBuilder<JourneyModel?>(
        stream: repository.watchJourneyById(journeyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final journey = snapshot.data;

          if (journey == null || !journey.isActive) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_outlined, color: AppColors.textMuted, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Journey Inactive or Ended',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This safety journey is no longer broadcasting live updates.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final isPanic = journey.isPanicTriggered;

          return StreamBuilder<List<LocationPoint>>(
            stream: repository.watchJourneyLocations(journeyId),
            builder: (context, locSnapshot) {
              final locations = locSnapshot.data ?? [];
              LatLng currentCenter;
              List<LatLng> polylinePoints = [];

              if (locations.isNotEmpty) {
                polylinePoints = locations.map((l) => LatLng(l.latitude, l.longitude)).toList();
                currentCenter = LatLng(locations.first.latitude, locations.first.longitude);
              } else if (journey.lastKnownLocation != null) {
                currentCenter = LatLng(
                  journey.lastKnownLocation!.latitude,
                  journey.lastKnownLocation!.longitude,
                );
                polylinePoints = [currentCenter];
              } else {
                currentCenter = const LatLng(37.7749, -122.4194);
                polylinePoints = [currentCenter];
              }

              return Column(
                children: [
                  // Panic Header Banner if Emergency Triggered
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isPanic ? AppColors.danger.withValues(alpha: 0.2) : AppColors.surface,
                    child: Row(
                      children: [
                        PulseIndicator(
                          color: isPanic ? AppColors.danger : AppColors.success,
                          size: 14,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                journey.destinationName ?? 'Active Safety Journey',
                                style: TextStyle(
                                  color: isPanic ? AppColors.danger : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                isPanic
                                    ? 'EMERGENCY PANIC ALERT ACTIVE!'
                                    : 'Live stream active from user device',
                                style: TextStyle(
                                  color: isPanic ? AppColors.danger : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Native Flutter Map View
                  Expanded(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: currentCenter,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.neighbourhub.neighbourhub',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              strokeWidth: 4.5,
                              color: isPanic ? AppColors.danger : AppColors.primary,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: currentCenter,
                              width: 48,
                              height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isPanic ? AppColors.danger : AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black38, blurRadius: 8),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
