import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';

class TicketIndicator extends StatefulWidget {
  final Map<String, dynamic> userData;
  const TicketIndicator({super.key, required this.userData});

  @override
  State<TicketIndicator> createState() => _TicketIndicatorState();
}

class _TicketIndicatorState extends State<TicketIndicator> {
  late Timer _timer;
  String _timeUntilNext = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant TicketIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTime(); // Refresh on data change
  }

  void _startTimer() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    final tickets = widget.userData['tickets'] ?? 0;
    final isPremium = widget.userData['isPremium'] == true;

    if (isPremium || tickets >= SocialService.maxTickets) {
      setState(() => _timeUntilNext = "");
      return;
    }

    final Timestamp? lastUpdate = widget.userData['lastTicketUpdate'];
    if (lastUpdate == null) return;

    final DateTime nextRegen = lastUpdate.toDate().add(const Duration(minutes: SocialService.ticketRegenMinutes));
    final Duration remaining = nextRegen.difference(DateTime.now());

    if (remaining.isNegative) {
      // Should trigger a refresh ideally, but we'll show 0:00 for now or call regenerate
      setState(() => _timeUntilNext = "0:00");
    } else {
      final min = remaining.inMinutes;
      final sec = remaining.inSeconds % 60;
      setState(() => _timeUntilNext = "$min:${sec.toString().padLeft(2, '0')}");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int tickets = widget.userData['tickets'] ?? 0;
    final bool isPremium = widget.userData['isPremium'] == true;

    if (isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text("PREMIUM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_num, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            "$tickets/${SocialService.maxTickets}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (_timeUntilNext.isNotEmpty) ...[
             const SizedBox(width: 8),
             Text(
               "($_timeUntilNext)",
               style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
             ),
          ]
        ],
      ),
    );
  }
}
