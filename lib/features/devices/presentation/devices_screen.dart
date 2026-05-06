import 'package:flutter/material.dart';

import '../../../core/api/devices_api.dart';
import '../../../core/models/device_info.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({
    super.key,
    required this.devicesApi,
    required this.sessionController,
  });

  final DevicesApi devicesApi;
  final SessionController sessionController;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _isLoading = true;
  String? _errorText;
  List<DeviceInfo> _devices = <DeviceInfo>[];
  int _maxDevices = 0;
  int _activeDevices = 0;
  bool _canAddMore = false;
  int? _currentDeviceId;
  int? _revokingDeviceId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final DevicesResponse data = await widget.devicesApi.getDevices();

      if (!mounted) {
        return;
      }

      setState(() {
        _devices = data.devices;
        _maxDevices = data.maxDevices;
        _activeDevices = data.activeDevices;
        _canAddMore = data.canAddMore;
        _currentDeviceId = data.currentDeviceId;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'Не удалось загрузить устройства';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _revokeDevice(int deviceId) async {
    setState(() {
      _revokingDeviceId = deviceId;
    });

    try {
      await widget.devicesApi.revokeDevice(deviceId);

      final bool revokedCurrentDevice = _currentDeviceId == deviceId;
      if (revokedCurrentDevice) {
        await widget.sessionController.logout();
        return;
      }

      await _load();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Устройство отозвано')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отозвать устройство')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _revokingDeviceId = null;
        });
      }
    }
  }

  String _capacityText() {
    if (_maxDevices <= 0) {
      return 'Лимит устройств пока не определён.';
    }

    if (_activeDevices > _maxDevices) {
      return 'Подключено $_activeDevices из $_maxDevices. Лимит превышен — отключите лишние устройства.';
    }

    if (_canAddMore) {
      return 'Подключено $_activeDevices из $_maxDevices. Можно добавить ещё устройство.';
    }

    return 'Подключено $_activeDevices из $_maxDevices. Лимит достигнут.';
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_errorText!),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }

    final List<DeviceInfo> devices = <DeviceInfo>[..._devices]
      ..sort((DeviceInfo a, DeviceInfo b) {
        final int aRank = a.id == _currentDeviceId ? 0 : (a.isRevoked ? 2 : 1);
        final int bRank = b.id == _currentDeviceId ? 0 : (b.isRevoked ? 2 : 1);
        return aRank.compareTo(bRank);
      });

    final DeviceInfo? currentDevice = devices.cast<DeviceInfo?>().firstWhere(
      (device) => device?.id == _currentDeviceId,
      orElse: () => null,
    );

    final String currentDeviceName = currentDevice == null
        ? 'Не определено'
        : AppFormatters.fallback(
            currentDevice.deviceName,
            empty: 'Без названия',
          );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Text(
              'Устройства',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Сводка',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_capacityText()),
                    const SizedBox(height: 8),
                    Text('Текущее устройство: $currentDeviceName'),
                    const SizedBox(height: 8),
                    const Text('Текущее устройство отмечено в списке ниже.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...devices.map(
              (device) => _DeviceCard(
                device: device,
                isCurrent: _currentDeviceId == device.id,
                isRevoking: _revokingDeviceId == device.id,
                onRevoke: () => _revokeDevice(device.id),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _load, child: const Text('Обновить')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Устройства')),
      body: _buildBody(),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  String _shortDeviceUid(String? value) {
    if (value == null || value.isEmpty) {
      return 'Не определено';
    }

    if (value.length <= 20) {
      return value;
    }

    return '${value.substring(0, 12)}...${value.substring(value.length - 6)}';
  }

  const _DeviceCard({
    required this.device,
    required this.isCurrent,
    required this.isRevoking,
    required this.onRevoke,
  });

  final DeviceInfo device;
  final bool isCurrent;
  final bool isRevoking;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final String platform = AppFormatters.fallback(device.platform);
    final String deviceName = AppFormatters.fallback(
      device.deviceName,
      empty: 'Без названия',
    );
    final String appVersion = AppFormatters.fallback(device.appVersion);
    final String osVersion = AppFormatters.fallback(device.osVersion);
    final String lastSeenAt = AppFormatters.dateTime(device.lastSeenAt);
    final bool isRevoked = device.isRevoked;
    final bool isActive = device.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (isCurrent)
                  const StatusBadge(
                    label: 'Текущее устройство',
                    isPositive: true,
                  ),
                StatusBadge(
                  label: isRevoked
                      ? 'Отозвано'
                      : isActive
                      ? 'Активно'
                      : 'Не активно',
                  isPositive: !isRevoked && isActive,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              deviceName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _InfoRow(label: 'Платформа', value: platform),
            const SizedBox(height: 6),
            _InfoRow(label: 'Версия', value: appVersion),
            const SizedBox(height: 6),
            _InfoRow(label: 'OS', value: osVersion),
            const SizedBox(height: 6),
            _InfoRow(label: 'Активность', value: lastSeenAt),
            const SizedBox(height: 6),
            _InfoRow(label: 'ID', value: _shortDeviceUid(device.deviceUid)),
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Добавлено',
              value: AppFormatters.dateTime(device.createdAt),
            ),
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Обновлено',
              value: AppFormatters.dateTime(device.updatedAt),
            ),
            if (!isRevoked) ...<Widget>[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: isRevoking ? null : onRevoke,
                child: isRevoking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isCurrent
                            ? 'Отключить это устройство'
                            : 'Отключить устройство',
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
