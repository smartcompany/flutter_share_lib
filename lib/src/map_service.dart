import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 지도 앱 선택 및 열기 서비스
class MapService {
  /// 지도 앱 선택 다이얼로그 표시
  static Future<void> showMapAppPicker({
    required BuildContext context,
    required String locationName,
    double? latitude,
    double? longitude,
  }) async {
    final availableApps = await _getAvailableMapApps(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );

    if (availableApps.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용 가능한 지도 앱이 없습니다.'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => _MapAppPickerDialog(
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
  }) async {
    final apps = <MapApp>[];

    // 카카오맵
    final kakaoMapUrl = _buildKakaoMapUrl(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
    if (await canLaunchUrl(kakaoMapUrl)) {
      apps.add(MapApp(
        name: '카카오맵',
        icon: Icons.map,
        color: Colors.yellow.shade700,
        url: kakaoMapUrl,
      ));
    }

    // 네이버맵
    final naverMapUrl = _buildNaverMapUrl(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
    if (await canLaunchUrl(naverMapUrl)) {
      apps.add(MapApp(
        name: '네이버 지도',
        icon: Icons.map_outlined,
        color: Colors.green,
        url: naverMapUrl,
      ));
    }

    // 구글맵
    final googleMapUrl = _buildGoogleMapUrl(
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
    if (await canLaunchUrl(googleMapUrl)) {
      apps.add(MapApp(
        name: '구글 지도',
        icon: Icons.map,
        color: Colors.blue,
        url: googleMapUrl,
      ));
    }

    // 애플맵 (iOS만)
    if (latitude != null && longitude != null) {
      final appleMapUrl = _buildAppleMapUrl(
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
      );
      if (await canLaunchUrl(appleMapUrl)) {
        apps.add(MapApp(
          name: 'Apple 지도',
          icon: Icons.map,
          color: Colors.grey,
          url: appleMapUrl,
        ));
      }
    }

    return apps;
  }

  /// 카카오맵 URL 생성
  static Uri _buildKakaoMapUrl({
    required String locationName,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      // 좌표가 있으면 좌표로 검색
      return Uri.parse(
        'kakaomap://place?q=$locationName&x=$longitude&y=$latitude',
      );
    } else {
      // 좌표가 없으면 장소명으로 검색
      return Uri.parse(
          'kakaomap://search?q=${Uri.encodeComponent(locationName)}');
    }
  }

  /// 네이버맵 URL 생성
  static Uri _buildNaverMapUrl({
    required String locationName,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return Uri.parse(
        'nmap://place?name=${Uri.encodeComponent(locationName)}&lat=$latitude&lng=$longitude',
      );
    } else {
      return Uri.parse(
        'nmap://search?query=${Uri.encodeComponent(locationName)}',
      );
    }
  }

  /// 구글맵 URL 생성
  static Uri _buildGoogleMapUrl({
    required String locationName,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      // 좌표가 있으면 좌표 사용
      return Uri.parse('google.navigation:q=$latitude,$longitude');
    } else {
      // 좌표가 없으면 장소명으로 검색
      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationName)}',
      );
    }
  }

  /// Apple 지도 URL 생성
  static Uri _buildAppleMapUrl({
    required String locationName,
    required double latitude,
    required double longitude,
  }) {
    // iOS에서는 maps://, Android에서는 http://maps.apple.com 사용
    return Uri.parse(
      'maps://maps.apple.com/?q=$latitude,$longitude&name=${Uri.encodeComponent(locationName)}',
    );
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
    return AlertDialog(
      title: const Text('지도 앱 선택'),
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
          child: const Text('취소'),
        ),
      ],
    );
  }
}
