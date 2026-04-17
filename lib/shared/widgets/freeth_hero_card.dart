import 'package:flutter/material.dart';

class FreethHeroCard extends StatelessWidget {
  const FreethHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badges = const <Widget>[],
    this.actions = const <Widget>[],
  });

  final String title;
  final String subtitle;
  final List<Widget> badges;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            scheme.primaryContainer,
            scheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (badges.isNotEmpty) ...<Widget>[
            Wrap(spacing: 10, runSpacing: 10, children: badges),
            const SizedBox(height: 18),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(fontSize: 16, height: 1.45)),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            Wrap(spacing: 12, runSpacing: 12, children: actions),
          ],
        ],
      ),
    );
  }
}
