import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/journey_model.dart';
import '../../../data/models/location_point.dart';
import '../../journey/providers/journey_provider.dart';
import '../../../shared/widgets/pulse_indicator.dart';

class WebLiveTrackingScreen extends ConsumerStatefulWidget {
  final String journeyId;

  const WebLiveTrackingScreen({
    super.key,
    required this.journeyId,
  });

  @override
  ConsumerState<WebLiveTrackingScreen> createState() => _WebLiveTrackingScreenState();
}

class _WebLiveTrackingScreenState extends ConsumerState<WebLiveTrackingScreen> {
  // Demo simulation state
  bool _isDemoPanic = false;
  bool _isDemoArrived = false;
  int _demoStepIndex = 0;
  Timer? _autoMoveTimer;

  // Demo route points around San Francisco Market St to Ferry Building
  final List<LatLng> _demoRoutePoints = const [
    LatLng(37.7812, -122.4110), // Civic Center / Market St
    LatLng(37.7845, -122.4068), // Powell St
    LatLng(37.7865, -122.4055), // Montgomery St
    LatLng(37.7897, -122.4012), // Embarcadero
    LatLng(37.7925, -122.3930), // Ferry Building
  ];

  @override
  void initState() {
    super.initState();
    if (widget.journeyId.toLowerCase().contains('demo')) {
      // Start gentle auto-movement along demo route for live web preview
      _autoMoveTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted && !_isDemoArrived) {
          setState(() {
            _demoStepIndex = (_demoStepIndex + 1) % _demoRoutePoints.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _autoMoveTimer?.cancel();
    super.dispose();
  }

  bool get _isDemoMode => widget.journeyId.toLowerCase().contains('demo');

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(journeyRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'NeighbourHub Web Live Tracker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (_isDemoMode)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Text(
                    'LIVE DEMO MODE',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
        ],
        centerTitle: true,
      ),
      body: StreamBuilder<JourneyModel?>(
        stream: repository.watchJourneyById(widget.journeyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isDemoMode) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final journey = snapshot.data;

          if (journey == null && !_isDemoMode) {
            return _buildExpiredCard('Journey Link Expired or Not Found');
          }

          // Handle Demo Mode Overrides
          final activeJourney = journey ?? JourneyModel(
            id: widget.journeyId,
            userId: 'demo_user_123',
            isActive: !_isDemoArrived,
            startTime: DateTime.now().subtract(const Duration(minutes: 18)),
            destinationName: 'Ferry Building & Embarcadero, San Francisco',
            contactIds: ['c1', 'c2'],
            isPanicTriggered: _isDemoPanic,
            expiresAt: DateTime.now().add(const Duration(hours: 12)),
          );

          final isPanic = _isDemoMode ? _isDemoPanic : activeJourney.isPanicTriggered;
          final isCompleted = _isDemoMode ? _isDemoArrived : (!activeJourney.isActive || DateTime.now().isAfter(activeJourney.expiresAt));

          if (isCompleted) {
            return _buildExpiredCard(
              _isDemoArrived || !activeJourney.isActive
                  ? 'Journey Completed - User Arrived Safely'
                  : 'Tracking Link Expired',
              isCompleted: true,
            );
          }

          return StreamBuilder<List<LocationPoint>>(
            stream: repository.watchJourneyLocations(widget.journeyId),
            builder: (context, locSnapshot) {
              List<LatLng> polylinePoints = [];
              LatLng currentCenter;

              if (_isDemoMode) {
                polylinePoints = _demoRoutePoints.sublist(0, _demoStepIndex + 1);
                currentCenter = _demoRoutePoints[_demoStepIndex];
              } else {
                final locs = locSnapshot.data ?? [];
                if (locs.isNotEmpty) {
                  polylinePoints = locs.map((l) => LatLng(l.latitude, l.longitude)).toList();
                  currentCenter = LatLng(locs.first.latitude, locs.first.longitude);
                } else if (activeJourney.lastKnownLocation != null) {
                  currentCenter = LatLng(
                    activeJourney.lastKnownLocation!.latitude,
                    activeJourney.lastKnownLocation!.longitude,
                  );
                  polylinePoints = [currentCenter];
                } else {
                  currentCenter = const LatLng(37.7749, -122.4194);
                  polylinePoints = [currentCenter];
                }
              }

              final destPoint = _demoRoutePoints.last;

              return Column(
                children: [
                  // Status Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isPanic ? AppColors.danger.withValues(alpha: 0.15) : AppColors.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: isPanic ? AppColors.danger : AppColors.border,
                          width: isPanic ? 2.0 : 1.0,
                        ),
                      ),
                    ),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      activeJourney.destinationName ?? 'Active Journey Tracking',
                                      style: TextStyle(
                                        color: isPanic ? AppColors.danger : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (isPanic)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'EMERGENCY PANIC',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Live location updated • Disposable safety tracking active',
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

                  // Map Container
                  Expanded(
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: currentCenter,
                            initialZoom: 15.5,
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
                                  strokeWidth: 5.0,
                                  color: isPanic ? AppColors.danger : AppColors.primary,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                // Destination Marker
                                Marker(
                                  point: destPoint,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black26, blurRadius: 4),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.flag_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                // Traveler Current Location Marker
                                Marker(
                                  point: currentCenter,
                                  width: 52,
                                  height: 52,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isPanic ? AppColors.danger : AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isPanic ? AppColors.danger : AppColors.primary)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_circle_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Stats Overlay Box
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 8),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.speed, color: AppColors.accent, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Speed: ~14 km/h',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.battery_charging_full, color: AppColors.success, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Battery: 88% OK',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Demo Simulation Controls Bar (for evaluators on demo link)
                  if (_isDemoMode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: AppColors.surface,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPanic ? AppColors.surfaceAlt : AppColors.danger,
                              foregroundColor: isPanic ? AppColors.textPrimary : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(isPanic ? Icons.notifications_off : Icons.warning_amber_rounded, size: 18),
                            label: Text(isPanic ? 'Clear SOS Panic' : 'Simulate SOS Panic'),
                            onPressed: () {
                              setState(() {
                                _isDemoPanic = !_isDemoPanic;
                              });
                            },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Simulate Safe Arrival'),
                            onPressed: () {
                              setState(() {
                                _isDemoArrived = true;
                              });
                            },
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Copy Tracking Link'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: Uri.base.toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Demo web tracking link copied to clipboard!'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
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

  Widget _buildExpiredCard(String message, {bool isCompleted = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isCompleted ? AppColors.success : AppColors.border),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.shield_outlined,
                color: isCompleted ? AppColors.success : AppColors.textMuted,
                size: 68,
              ),
              const SizedBox(height: 18),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'For privacy and safety reasons, disposable tracking links stop providing location updates once the journey ends or expires.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              if (_isDemoMode && _isDemoArrived) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart Demo Journey'),
                  onPressed: () {
                    setState(() {
                      _isDemoArrived = false;
                      _isDemoPanic = false;
                      _demoStepIndex = 0;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
