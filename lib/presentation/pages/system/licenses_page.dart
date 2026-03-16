import 'package:flutter/material.dart';
import 'package:flutterbase/presentation/widgets/ui/widgets.dart';
import 'package:flutterbase/shared/theme/theme.dart';

/// 利用ライブラリライセンス情報ページ
class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMainHeader(title: 'ライセンス情報'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageMargin),
        children: const [
          _LicenseSection(
            name: 'Flutter',
            version: '3.x',
            license: 'BSD 3-Clause License',
            url: 'https://flutter.dev',
            copyright: 'Copyright 2014 The Flutter Authors',
          ),
          SizedBox(height: AppSpacing.sm),
          _LicenseSection(
            name: 'go_router',
            version: '^13.0.0',
            license: 'BSD 3-Clause License',
            url: 'https://pub.dev/packages/go_router',
            copyright: 'Copyright 2021 Flutter Authors',
          ),
          SizedBox(height: AppSpacing.sm),
          _LicenseSection(
            name: 'flutter_riverpod',
            version: '^2.5.1',
            license: 'MIT License',
            url: 'https://pub.dev/packages/flutter_riverpod',
            copyright: 'Copyright 2020 Remi Rousselet',
          ),
          SizedBox(height: AppSpacing.sm),
          _LicenseSection(
            name: 'get_it',
            version: '^7.7.0',
            license: 'MIT License',
            url: 'https://pub.dev/packages/get_it',
            copyright: 'Copyright 2018 Thomas Burkhart',
          ),
          SizedBox(height: AppSpacing.sm),
          _LicenseSection(
            name: 'sqflite',
            version: '^2.3.3',
            license: 'MIT License',
            url: 'https://pub.dev/packages/sqflite',
            copyright: 'Copyright 2017 Tekartik',
          ),
          SizedBox(height: AppSpacing.sm),
          _LicenseSection(
            name: 'package_info_plus',
            version: '^8.0.0',
            license: 'BSD 2-Clause License',
            url: 'https://pub.dev/packages/package_info_plus',
            copyright: 'Copyright 2017 The Chromium Authors',
          ),
          SizedBox(height: AppSpacing.sm),
          _LicenseSection(
            name: 'equatable',
            version: '^2.0.5',
            license: 'MIT License',
            url: 'https://pub.dev/packages/equatable',
            copyright: 'Copyright 2019 Felix Angelov',
          ),
          SizedBox(height: AppSpacing.sm),
          _LicenseSection(
            name: 'logger',
            version: '^2.4.0',
            license: 'MIT License',
            url: 'https://pub.dev/packages/logger',
            copyright: 'Copyright 2019 Simon Leier',
          ),
        ],
      ),
    );
  }
}

class _LicenseSection extends StatefulWidget {
  const _LicenseSection({
    required this.name,
    required this.version,
    required this.license,
    required this.url,
    required this.copyright,
  });

  final String name;
  final String version;
  final String license;
  final String url;
  final String copyright;

  @override
  State<_LicenseSection> createState() => _LicenseSectionState();
}

class _LicenseSectionState extends State<_LicenseSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppRadius.lgBorder,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.componentPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name, style: AppTextStyles.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${widget.version} • ${widget.license}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.componentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.copyright, style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.url,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _getLicenseText(widget.license),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLicenseText(String license) {
    return switch (license) {
      'MIT License' =>
        'Permission is hereby granted, free of charge, to any person obtaining '
            'a copy of this software and associated documentation files, to deal '
            'in the Software without restriction...',
      'BSD 3-Clause License' =>
        'Redistribution and use in source and binary forms, with or without '
            'modification, are permitted provided that the following conditions are met...',
      'BSD 2-Clause License' =>
        'Redistribution and use in source and binary forms, with or without '
            'modification, are permitted provided that the following conditions are met...',
      _ => '詳細はパッケージのライセンスファイルを参照してください。'
    };
  }
}
