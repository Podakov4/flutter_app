import 'package:flutter/material.dart';

import '../../../core/models/split_tunnel_config.dart';
import '../../../features/access/application/connection_controller.dart';
import '../../../shared/widgets/freeth_hero_card.dart';
import '../../../shared/widgets/freeth_section_title.dart';
import '../../../shared/widgets/status_badge.dart';
import '../application/split_tunnel_controller.dart';

class SplitTunnelScreen extends StatefulWidget {
  const SplitTunnelScreen({
    super.key,
    required this.splitTunnelController,
    required this.connectionController,
  });

  final SplitTunnelController splitTunnelController;
  final ConnectionController connectionController;

  @override
  State<SplitTunnelScreen> createState() => _SplitTunnelScreenState();
}

class _SplitTunnelScreenState extends State<SplitTunnelScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.splitTunnelController.ensureInitialized().then((_) {
      if (mounted) widget.splitTunnelController.loadInstalledApps();
    });
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final String q = _search.text.toLowerCase();
    if (q != _query) setState(() => _query = q);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  List<InstalledApp> get _filtered {
    final List<InstalledApp> apps =
        widget.splitTunnelController.installedApps;
    if (_query.isEmpty) return apps;
    return apps
        .where(
          (InstalledApp a) =>
              a.name.toLowerCase().contains(_query) ||
              a.packageName.toLowerCase().contains(_query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.splitTunnelController,
        widget.connectionController,
      ]),
      builder: (BuildContext context, _) {
        final SplitTunnelController st = widget.splitTunnelController;
        final ConnectionController cc = widget.connectionController;
        final SplitTunnelMode mode = st.mode;
        final int count = st.selectedPackages.length;
        final bool showApps = mode != SplitTunnelMode.all;

        return Scaffold(
          appBar: AppBar(title: const Text('VPN для приложений')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  FreethHeroCard(
                    title: 'VPN для приложений',
                    subtitle:
                        'Выберите, какие приложения используют Freeth VPN.',
                    badges: <Widget>[
                      StatusBadge(
                        label: mode.label,
                        isPositive: mode != SplitTunnelMode.all,
                      ),
                      StatusBadge(
                        label: count == 0 ? 'Не выбрано' : '$count прил.',
                        isPositive: count > 0,
                      ),
                    ],
                    actions: <Widget>[
                      if (cc.isConnected)
                        FilledButton.icon(
                          onPressed: cc.isBusy ? null : cc.reconnect,
                          icon: const Icon(Icons.sync_rounded),
                          label: const Text('Применить сейчас'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const FreethSectionTitle(
                    title: 'Режим работы',
                    subtitle:
                        'Выберите, как VPN взаимодействует с приложениями.',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SegmentedButton<SplitTunnelMode>(
                            showSelectedIcon: false,
                            segments: const <ButtonSegment<SplitTunnelMode>>[
                              ButtonSegment<SplitTunnelMode>(
                                value: SplitTunnelMode.all,
                                label: Text('Все'),
                                icon: Icon(Icons.public_rounded),
                              ),
                              ButtonSegment<SplitTunnelMode>(
                                value: SplitTunnelMode.includeOnly,
                                label: Text('Только выбранные'),
                                icon: Icon(Icons.check_circle_outline_rounded),
                              ),
                              ButtonSegment<SplitTunnelMode>(
                                value: SplitTunnelMode.excludeOnly,
                                label: Text('Все, кроме'),
                                icon: Icon(
                                  Icons.do_not_disturb_on_outlined,
                                ),
                              ),
                            ],
                            selected: <SplitTunnelMode>{mode},
                            onSelectionChanged:
                                (Set<SplitTunnelMode> selection) =>
                                    st.setMode(selection.first),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            mode.description,
                            style: const TextStyle(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (cc.isConnected) ...<Widget>[
                    const SizedBox(height: 12),
                    Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'VPN активен. Изменения применятся после переподключения.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (showApps) ...<Widget>[
                    const SizedBox(height: 16),
                    FreethSectionTitle(
                      title: 'Приложения',
                      subtitle: mode == SplitTunnelMode.includeOnly
                          ? 'Отмеченные приложения будут работать через VPN.'
                          : 'Отмеченные приложения будут обходить VPN.',
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            TextField(
                              controller: _search,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search_rounded),
                                hintText: 'Поиск приложений...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildAppList(st),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppList(SplitTunnelController st) {
    if (st.appsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (st.installedApps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Приложения не найдены')),
      );
    }

    final List<InstalledApp> apps = _filtered;

    if (apps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Ничего не найдено')),
      );
    }

    return Column(
      children: apps.map((InstalledApp app) {
        final bool selected = st.isSelected(app.packageName);
        return CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          secondary: CircleAvatar(
            radius: 18,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          title: Text(
            app.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            app.packageName,
            style: const TextStyle(fontSize: 12),
          ),
          value: selected,
          onChanged: (_) => st.toggleApp(app.packageName),
        );
      }).toList(),
    );
  }
}
