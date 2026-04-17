import 'package:flutter/material.dart';

class FreethModeCard extends StatelessWidget {
  const FreethModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onToggle,
    required this.toggleLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onToggle;
  final String toggleLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onToggle,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(toggleLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
