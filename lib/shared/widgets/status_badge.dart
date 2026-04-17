import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.isPositive});

  final String label;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final Color bg = isPositive
        ? const Color(0xFFDDF5E8)
        : const Color(0xFFF8DDE1);

    final Color fg = isPositive
        ? const Color(0xFF1E7A46)
        : const Color(0xFFB23A48);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
