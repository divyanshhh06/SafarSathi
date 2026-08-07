import 'package:flutter/material.dart';
import '../modelss/bus.dart';

/// 3-button crowd feedback dialog ("Waze for Buses") - FE-1 Winning X-Factor
class CrowdReportingDialog extends StatelessWidget {
  final Bus bus;
  final String currentLang;
  final ValueChanged<OccupancyLevel> onReportSubmitted;

  const CrowdReportingDialog({
    super.key,
    required this.bus,
    required this.currentLang,
    required this.onReportSubmitted,
  });

  static Future<OccupancyLevel?> show(
    BuildContext context, {
    required Bus bus,
    required String currentLang,
    required ValueChanged<OccupancyLevel> onReportSubmitted,
  }) {
    return showDialog<OccupancyLevel>(
      context: context,
      builder: (context) => CrowdReportingDialog(
        bus: bus,
        currentLang: currentLang,
        onReportSubmitted: onReportSubmitted,
      ),
    );
  }

  String _getTitle() {
    if (currentLang == 'pa') return 'ਬੱਸ ਭੀੜ ਰਿਪੋਰਟ ਕਰੋ';
    if (currentLang == 'hi') return 'बस भीड़ की रिपोर्ट करें';
    return 'Report Bus Occupancy';
  }

  String _getSubtitle() {
    if (currentLang == 'pa') return 'ਮੌਜੂਦਾ ਬੱਸ ਸਥਿਤੀ ਚੁਣੋ:';
    if (currentLang == 'hi') return 'वर्तमान बस की स्थिति चुनें:';
    return 'Select current crowd level for Bus ${bus.busId}:';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt_rounded, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getSubtitle(),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 20),
          // 3 Crowd Level Buttons
          _buildOccupancyButton(
            context,
            level: OccupancyLevel.seatsAvailable,
            icon: Icons.airline_seat_recline_normal_rounded,
            color: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
          ),
          const SizedBox(height: 10),
          _buildOccupancyButton(
            context,
            level: OccupancyLevel.standingOnly,
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
          ),
          const SizedBox(height: 10),
          _buildOccupancyButton(
            context,
            level: OccupancyLevel.packed,
            icon: Icons.groups_rounded,
            color: const Color(0xFFC62828),
            bgColor: const Color(0xFFFFEBEE),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyButton(
    BuildContext context, {
    required OccupancyLevel level,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    final isCurrent = bus.occupancy == level;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onReportSubmitted(level);
          Navigator.of(context).pop(level);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: color,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thanks for reporting! Occupancy updated to ${level.label(currentLang)}.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? color : color.withValues(alpha: 0.3),
              width: isCurrent ? 2.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  level.label(currentLang),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
