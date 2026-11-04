import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/l10n/app_localizations_en.dart';
import 'package:flutterbase/presentation/l10n/app_localizations_ja.dart';
import 'package:flutterbase/presentation/notifications/notification_channel_catalog.dart';

void main() {
  const languages = <String, AppLocalizations>{
    'ja': AppLocalizationsJa(),
    'en': AppLocalizationsEn(),
  };

  test('the app\'s group is headed by the app\'s name', () {
    for (final l10n in languages.values) {
      final app = NotificationChannelCatalog.groupsFor(l10n)
          .singleWhere((g) => g.id == NotificationChannelCatalog.appGroupId);
      expect(app.name, l10n.appName);
    }
  });

  test('the notices are in the app\'s group, named for what they are', () {
    final ja = NotificationChannelCatalog.groupsFor(const AppLocalizationsJa());
    final notices = ja.single.channels.single;
    expect(notices.id, NotificationChannelCatalog.serverNoticesChannelId);
    expect(notices.name, 'お知らせ');
    expect(notices.description, 'Web 版から届くお知らせ');

    final en = NotificationChannelCatalog.groupsFor(const AppLocalizationsEn());
    expect(en.single.channels.single.name, 'Notices');
  });

  test('ids and names are never shared, in either language', () {
    for (final MapEntry(key: language, value: l10n) in languages.entries) {
      final groups = NotificationChannelCatalog.groupsFor(l10n);
      final channels = [for (final g in groups) ...g.channels];
      expect(
        groups.map((g) => g.id).toSet(),
        hasLength(groups.length),
        reason: language,
      );
      expect(
        channels.map((c) => c.id).toSet(),
        hasLength(channels.length),
        reason: language,
      );
      expect(
        channels.map((c) => c.name).toSet(),
        hasLength(channels.length),
        reason: '$language: a channel borrows another\'s name',
      );
      for (final c in channels) {
        expect(c.name.trim(), isNotEmpty, reason: '$language ${c.id}');
      }
    }
  });

  test('ids stay the same in every language', () {
    List<String> idsOf(AppLocalizations l10n) => [
      for (final g in NotificationChannelCatalog.groupsFor(l10n)) ...[
        g.id,
        ...g.channels.map((c) => c.id),
      ],
    ];
    expect(
      idsOf(const AppLocalizationsJa()),
      idsOf(const AppLocalizationsEn()),
    );
  });

  test('a retired channel is not one still in use', () {
    final inUse = {
      for (final g in NotificationChannelCatalog.groupsFor(
        const AppLocalizationsEn(),
      ))
        ...g.channels.map((c) => c.id),
    };
    expect(
      NotificationChannelCatalog.retiredChannelIds.where(inUse.contains),
      isEmpty,
    );
  });
}
