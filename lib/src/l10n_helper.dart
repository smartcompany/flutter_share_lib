import 'package:flutter/widgets.dart';

import 'package:share_lib/src/auth/generated/auth_localizations.dart';

/// Resolves package strings from [AuthLocalizations] (ARB), with locale fallback
/// when the host app did not register [AuthLocalizations.delegate].
AuthLocalizations shareLibL10n(BuildContext context) {
  return AuthLocalizations.of(context) ??
      lookupAuthLocalizations(
        Localizations.maybeLocaleOf(context) ?? const Locale('en'),
      );
}
