import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Apple에서 받은 성·이름을 JSON으로 저장하는 키 (`familyName`, `givenName`).
const String kAppleNamePartsPrefKey = 'share_lib_apple_name_parts';

/// 이전 버전 단일 문자열 캐시 (마이그레이션용).
const String kAppleDisplayNameLegacyKey = 'share_lib_apple_display_name';

bool _containsHangul(String s) {
  if (s.isEmpty) return false;
  return RegExp(r'[가-힣]').hasMatch(s);
}

/// Apple 성·이름을 표시용 한 줄로 만듭니다.
///
/// - 성·이름 중 **한글이 하나라도 있으면**: 한국식 `성+이름`, 공백 없음.
/// - **둘 다 한글이 아니면**: 서양식 `이름 성`(given + family), 공백 1칸.
String joinAppleFamilyGivenForDisplay(String? familyName, String? givenName) {
  final f = familyName?.trim() ?? '';
  final g = givenName?.trim() ?? '';
  if (f.isEmpty && g.isEmpty) return '';

  if (_containsHangul(f) || _containsHangul(g)) {
    return '$f$g'.trim();
  }

  final parts = <String>[];
  if (g.isNotEmpty) parts.add(g);
  if (f.isNotEmpty) parts.add(f);
  return parts.join(' ');
}

Map<String, String>? readAppleNamePartsMap(SharedPreferences prefs) {
  final s = prefs.getString(kAppleNamePartsPrefKey);
  if (s == null || s.isEmpty) return null;
  try {
    final decoded = jsonDecode(s) as Map<String, dynamic>?;
    if (decoded == null) return null;
    final out = <String, String>{};
    final fam = decoded['familyName']?.toString().trim();
    final giv = decoded['givenName']?.toString().trim();
    if (fam != null && fam.isNotEmpty) out['familyName'] = fam;
    if (giv != null && giv.isNotEmpty) out['givenName'] = giv;
    if (out.isEmpty) return null;
    return out;
  } catch (_) {
    return null;
  }
}

Future<void> writeAppleNamePartsMap(
  SharedPreferences prefs,
  Map<String, String> parts,
) async {
  if (parts.isEmpty) {
    await prefs.remove(kAppleNamePartsPrefKey);
    return;
  }
  await prefs.setString(kAppleNamePartsPrefKey, jsonEncode(parts));
  await prefs.remove(kAppleDisplayNameLegacyKey);
}

/// 캐시된 성·이름 또는 레거시 단일 문자열에서 표시용 문자열.
String displayNameFromApplePrefs(SharedPreferences prefs) {
  final m = readAppleNamePartsMap(prefs);
  if (m != null) {
    final joined = joinAppleFamilyGivenForDisplay(m['familyName'], m['givenName']);
    if (joined.isNotEmpty) return joined;
  }
  final legacy = prefs.getString(kAppleDisplayNameLegacyKey)?.trim();
  if (legacy != null && legacy.isNotEmpty) return legacy;
  return '';
}
