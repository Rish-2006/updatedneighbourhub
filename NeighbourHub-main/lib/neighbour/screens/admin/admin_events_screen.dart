// lib/neighbour/screens/admin/admin_events_screen.dart
//
// Admin screen to create, edit and delete community events.
// Events are stored in Firestore 'events' collection and are
// streamed in real-time to the user-facing Community screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  // ── Show Create / Edit Dialog ──────────────────────────────────────────────
  Future<void> _showEventDialog({EventModel? existing}) async {
    final isEditing = existing != null;

    final titleController     = TextEditingController(text: existing?.title ?? '');
    final descController      = TextEditingController(text: existing?.description ?? '');
    final placeController     = TextEditingController(text: existing?.place ?? '');
    final addlController      = TextEditingController(text: existing?.additionalDetails ?? '');

    DateTime? selectedDate    = existing?.date;
    TimeOfDay? startTime = existing != null && existing.startTime.isNotEmpty
        ? _parseTime(existing.startTime)
        : null;
    TimeOfDay? endTime = existing != null && existing.endTime.isNotEmpty
        ? _parseTime(existing.endTime)
        : null;

    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppTheme.darkCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Header ───────────────────────────────────────────
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.event_outlined, color: AppTheme.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEditing ? 'Edit Event' : 'Create Event',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Event Title ───────────────────────────────────────
                        _buildLabel('Event Title *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('e.g. Community Clean-Up Drive'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // ── Description ───────────────────────────────────────
                        _buildLabel('Description *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('Brief event description'),
                          maxLines: 3,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // ── Date ─────────────────────────────────────────────
                        _buildLabel('Event Date *'),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime(2030),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primaryColor),
                                ),
                                child: child!,
                              ),
                            );
                            if (d != null) setDialogState(() => selectedDate = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.darkBg,
                              border: Border.all(color: selectedDate != null ? AppTheme.primaryColor : AppTheme.darkBorder),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  selectedDate != null
                                      ? DateFormat('d MMMM yyyy').format(selectedDate!)
                                      : 'Select Date',
                                  style: TextStyle(
                                    color: selectedDate != null ? Colors.white : AppTheme.darkSubtext,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Start Time / End Time ─────────────────────────────
                        _buildLabel('Event Time *'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _TimePicker(
                                label: 'Start Time',
                                time: startTime,
                                onPicked: (t) => setDialogState(() => startTime = t),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TimePicker(
                                label: 'End Time',
                                time: endTime,
                                onPicked: (t) => setDialogState(() => endTime = t),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Venue ─────────────────────────────────────────────
                        _buildLabel('Venue / Place *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: placeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('e.g. NeighbourHub Community Park'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Venue is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // ── Additional Details (optional) ─────────────────────
                        _buildLabel('Additional Details (optional)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: addlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('e.g. Please bring gloves and water'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 28),

                        // ── Actions ──────────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 46),
                                  foregroundColor: AppTheme.darkSubtext,
                                  side: const BorderSide(color: AppTheme.darkBorder),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) return;
                                  if (selectedDate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select an event date.')),
                                    );
                                    return;
                                  }
                                  if (startTime == null || endTime == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select start and end times.')),
                                    );
                                    return;
                                  }
                                  Navigator.pop(ctx, true);
                                },
                                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                                child: Text(isEditing ? 'Save Changes' : 'Create Event'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final svc = context.read<FirestoreService>();

    final event = EventModel(
      id: existing?.id ?? '',
      title: titleController.text.trim(),
      description: descController.text.trim(),
      date: selectedDate!,
      startTime: startTime!.format(context),
      endTime: endTime!.format(context),
      place: placeController.text.trim(),
      additionalDetails: addlController.text.trim(),
      createdBy: existing?.createdBy ?? 'admin',
      createdByName: existing?.createdByName ?? 'Admin',
      participants: existing?.participants ?? [],
    );

    if (isEditing) {
      await svc.updateEvent(event);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated.'), backgroundColor: AppTheme.successColor),
        );
      }
    } else {
      await svc.createEvent(event);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully! 🎉'), backgroundColor: AppTheme.successColor),
        );
      }
    }
  }

  // ── Delete with confirmation ───────────────────────────────────────────────
  Future<void> _confirmDelete(EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Delete Event?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete:\n\n"${event.title}"\n\nThis action cannot be undone.',
          style: const TextStyle(color: AppTheme.darkSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<FirestoreService>().deleteEvent(event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted.'), backgroundColor: AppTheme.darkCard),
        );
      }
    }
  }

  // ── View Registrations ────────────────────────────────────────────────────
  void _viewRegistrations(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.darkBorder, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  '${DateFormat('d MMM yyyy').format(event.date)}  •  ${event.startTime} – ${event.endTime}',
                  style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                ),
                const Divider(color: AppTheme.darkBorder, height: 20),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: context.read<FirestoreService>().getEventRegistrationsStream(event.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final regs = snapshot.data ?? [];
                      if (regs.isEmpty) {
                        return const Center(child: Text('No registrations yet.', style: TextStyle(color: AppTheme.darkSubtext)));
                      }
                      return ListView.builder(
                        controller: controller,
                        itemCount: regs.length,
                        itemBuilder: (context, index) {
                          final reg = regs[index];
                          final regDate = (reg['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                              child: const Icon(Icons.person, color: AppTheme.primaryColor),
                            ),
                            title: Text(reg['userName'] ?? 'Unknown User', style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              reg['flatNumber'] != null && reg['flatNumber'].toString().isNotEmpty
                                  ? 'Flat ${reg['flatNumber']}'
                                  : reg['userEmail'] ?? '',
                              style: const TextStyle(color: AppTheme.darkSubtext, fontSize: 12),
                            ),
                            trailing: Text(
                              DateFormat('d MMM').format(regDate),
                              style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Create Event button ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ElevatedButton.icon(
            onPressed: () => _showEventDialog(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Create Event'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),

        // ── Events list ──────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<EventModel>>(
            stream: context.read<FirestoreService>().getEventsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy_outlined, size: 56, color: AppTheme.darkSubtext.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text('No events yet', style: TextStyle(color: AppTheme.darkSubtext)),
                      const SizedBox(height: 6),
                      const Text('Tap "Create Event" to add the first event.', style: TextStyle(color: AppTheme.darkSubtext, fontSize: 12)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isPast = event.date.isBefore(DateTime.now());
                  return _AdminEventCard(
                    event: event,
                    isPast: isPast,
                    onEdit: () => _showEventDialog(existing: event),
                    onDelete: () => _confirmDelete(event),
                    onViewRegistrations: () => _viewRegistrations(event),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return null;
      final hour = int.parse(parts[0]);
      final rest = parts[1].split(' ');
      var minute = int.parse(rest[0]);
      if (rest.length > 1 && rest[1].toLowerCase() == 'pm' && hour != 12) {
        return TimeOfDay(hour: hour + 12, minute: minute);
      }
      if (rest.length > 1 && rest[1].toLowerCase() == 'am' && hour == 12) {
        return TimeOfDay(hour: 0, minute: minute);
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.darkSubtext,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.darkSubtext.withValues(alpha: 0.6), fontSize: 13),
        filled: true,
        fillColor: AppTheme.darkBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.errorColor)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5)),
      );
}

// ─── Time Picker helper widget ────────────────────────────────────────────────
class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay?> onPicked;

  const _TimePicker({required this.label, required this.time, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primaryColor),
            ),
            child: child!,
          ),
        );
        if (t != null) onPicked(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkBg,
          border: Border.all(color: time != null ? AppTheme.primaryColor : AppTheme.darkBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppTheme.primaryColor, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                time != null ? time!.format(context) : label,
                style: TextStyle(
                  color: time != null ? Colors.white : AppTheme.darkSubtext,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Event Card ─────────────────────────────────────────────────────────
class _AdminEventCard extends StatelessWidget {
  final EventModel event;
  final bool isPast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewRegistrations;

  const _AdminEventCard({
    required this.event,
    required this.isPast,
    required this.onEdit,
    required this.onDelete,
    required this.onViewRegistrations,
  });

  @override
  Widget build(BuildContext context) {
    final timeRange = [event.startTime, event.endTime]
        .where((t) => t.isNotEmpty)
        .join(' – ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isPast ? AppTheme.darkBorder : AppTheme.primaryColor.withValues(alpha: 0.25),
          width: isPast ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isPast ? AppTheme.darkSubtext : Colors.white,
                    ),
                  ),
                ),
                if (isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBorder,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Past', style: TextStyle(fontSize: 10, color: AppTheme.darkSubtext)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Details ──────────────────────────────────────────────────────
            _InfoRow(icon: Icons.calendar_today_outlined, text: DateFormat('d MMMM yyyy').format(event.date)),
            if (timeRange.isNotEmpty)
              _InfoRow(icon: Icons.access_time_rounded, text: timeRange),
            if (event.place.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, text: event.place),
            const SizedBox(height: 6),
            Text(
              event.description,
              style: const TextStyle(color: AppTheme.darkSubtext, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // ── Actions ──────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewRegistrations,
                    icon: const Icon(Icons.people_outline, size: 16),
                    label: Text('Registered (${event.participantCount})'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 16),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.darkSubtext, fontSize: 12))),
        ],
      ),
    );
  }
}
