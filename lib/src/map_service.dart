import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:share_lib/src/l10n_helper.dart';

/// 지도 앱 선택 및 열기 서비스
class MapService {
  /// 지도 앱 선택 다이얼로그 표시
  static Future<void> showMapAppPicker({
    required BuildContext context,
    required String locationName,
    double? latitude,
    double? longitude,
  }) async {
    final l10n = shareLibL10n(context);
    final availableApps = await _getAvailableMapApps(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      kakaoName: l10n.mapKakao,
      naverName: l10n.mapNaver,
      googleName: l10n.mapGoogle,
      appleName: l10n.mapApple,
    );

    if (availableApps.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mapNoAppsAvailable)),
        );
      }
      return;
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (dialogContext) => _MapAppPickerDialog(
          apps: availableApps,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }
  }

  /// 사용 가능한 지도 앱 목록 가져오기
  static Future<List<MapApp>> _getAvailableMapApps({
    required String locationName,
    double? latitude,
    double? longitude,
    required String kakaoName,
    required String naverName,
    required String googleName,
    required String appleName,
  }) async {
    final apps = <MapApp>[];

    final kakaoMapUrl = _buildKakaoMapUrl(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
    if (await canLaunchUrl(kakaoMapUrl)) {
      apps.add(MapApp(
        name: kakaoName,
        icon: Icons.map,
        color: Colors.yellow.shade700,
        url: kakaoMapUrl,
      ));
    }

    final naverMapUrl = _buildNaverMapUrl(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
    if (await canLaunchUrl(naverMapUrl)) {
      apps.add(MapApp(
        name: naverName,
        icon: Icons.map_outlined,
        color: Colors.green,
        url: naverMapUrl,
      ));
    }

    final googleMapUrl = _buildGoogleMapUrl(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
    if (await canLaunchUrl(googleMapUrl)) {
      apps.add(MapApp(
        name: googleName,
        icon: Icons.map,
        color: Colors.blue,
        url: googleMapUrl,
      ));
    }

    final appleMapUrl = _buildAppleMapUrl(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
    if (await canLaunchUrl(appleMapUrl)) {
      apps.add(MapApp(
        name: appleName,
        icon: Icons.map,
        color: Colors.grey,
        url: appleMapUrl,
      ));
    }

    return apps;
  }

  static Uri _buildKakaoMapUrl({
    required String locationName,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return Uri.parse(
        'kakaomap://place?q=$locationName&x=$longitude&y=$latitude',
      );
    }
    return Uri.parse(
      'kakaomap://search?q=${Uri.encodeComponent(locationName)}',
    );
  }

  static Uri _buildNaverMapUrl({
    required String locationName,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return Uri.parse(
        'nmap://place?name=${Uri.encodeComponent(locationName)}&lat=$latitude&lng=$longitude',
      );
    }
    return Uri.parse(
      'nmap://search?query=${Uri.encodeComponent(locationName)}',
    );
  }

  static Uri _buildGoogleMapUrl({
    required String locationName,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return Uri.parse('google.navigation:q=$latitude,$longitude');
    }
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationName)}',
    );
  }

  static Uri _buildAppleMapUrl({
    required String locationName,
    double? latitude,
    double? longitude,
  }) {
    final encodedName = Uri.encodeComponent(locationName);
    if (latitude != null && longitude != null) {
      return Uri.parse(
        'http://maps.apple.com/?ll=$latitude,$longitude&q=$encodedName',
      );
    }
    return Uri.parse('http://maps.apple.com/?q=$encodedName');
  }
}

/// 지도 앱 정보
class MapApp {
  final String name;
  final IconData icon;
  final Color color;
  final Uri url;

  MapApp({
    required this.name,
    required this.icon,
    required this.color,
    required this.url,
  });
}

/// 지도 앱 선택 다이얼로그
class _MapAppPickerDialog extends StatelessWidget {
  final List<MapApp> apps;
  final String locationName;
  final double? latitude;
  final double? longitude;

  const _MapAppPickerDialog({
    required this.apps,
    required this.locationName,
    this.latitude,
    this.longitude,
  });

  Future<void> _openMapApp(MapApp app) async {
    try {
      final launched = await launchUrl(
        app.url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('Failed to launch ${app.name}');
      }
    } catch (e) {
      debugPrint('Error launching ${app.name}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = shareLibL10n(context);
    return AlertDialog(
      title: Text(l10n.mapPickerTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: apps.map((app) {
          return ListTile(
            leading: Icon(app.icon, color: app.color),
            title: Text(app.name),
            onTap: () {
              Navigator.pop(context);
              _openMapApp(app);
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
