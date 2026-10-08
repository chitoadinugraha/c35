import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class InSiteLocation extends StatelessWidget {
  const InSiteLocation({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onDevicePick,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final void Function(double lat, double lng, String label)? onDevicePick;

  Future<void> _useDevice(BuildContext context) async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition();
    final text = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    controller.text = text;
    onDevicePick?.call(pos.latitude, pos.longitude, text);
    onChanged();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Location', hintText: 'Address or place name'),
            onChanged: (_) => onChanged(),
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _useDevice(context),
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Use device location'),
            ),
          ),
        ],
      );
}
