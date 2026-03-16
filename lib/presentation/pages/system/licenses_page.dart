import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';

/// ライセンス情報エントリ
class _LicenseEntry {
  const _LicenseEntry({
    required this.packageName,
    required this.licenses,
  });

  final String packageName;
  final List<String> licenses;
}

/// ライセンス情報ViewModel
class _LicensesViewModel extends StateNotifier<AsyncValue<List<_LicenseEntry>>> {
  _LicensesViewModel() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rawLicenses = await LicenseRegistry.licenses.toList();

      // Group by package
      final map = <String, List<String>>{};
      for (final license in rawLicenses) {
        for (final package in license.packages) {
          map.putIfAbsent(package, () => []);
          final paragraphs = license.paragraphs
              .map((p) => p.text.trim())
              .where((t) => t.isNotEmpty)
              .join('\n\n');
          map[package]!.add(paragraphs);
        }
      }

      final entries = map.entries
          .map((e) => _LicenseEntry(packageName: e.key, licenses: e.value))
          .toList()
        ..sort((a, b) => a.packageName.compareTo(b.packageName));

      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final _licensesViewModelProvider = StateNotifierProvider.autoDispose<
    _LicensesViewModel, AsyncValue<List<_LicenseEntry>>>(
  (ref) => _LicensesViewModel(),
);

/// 利用ライブラリライセンス情報ページ
class LicensesPage extends ConsumerWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_licensesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ライセンス情報'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_licensesViewModelProvider),
          ),
        ),
        data: (entries) => entries.isEmpty
            ? const _EmptyState()
            : _LicensesList(entries: entries),
      ),
    );
  }
}

class _LicensesList extends StatelessWidget {
  const _LicensesList({required this.entries});

  final List<_LicenseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontalPadding,
        vertical: AppSpacing.pageVerticalPadding,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _LicenseCard(entry: entry, scheme: scheme);
      },
    );
  }
}

class _LicenseCard extends StatefulWidget {
  const _LicenseCard({required this.entry, required this.scheme});

  final _LicenseEntry entry;
  final ColorScheme scheme;

  @override
  State<_LicenseCard> createState() => _LicenseCardState();
}

class _LicenseCardState extends State<_LicenseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.scheme.surface,
        border: Border.all(color: widget.scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(8))
                : BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.packageName,
                          style: AppTextStyles.dnsSmBold.copyWith(
                            color: widget.scheme.onSurface,
                          ),
                        ),
                        Text(
                          '${widget.entry.licenses.length} ライセンス',
                          style: AppTextStyles.dnsSmNormal.copyWith(
                            color: widget.scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: widget.scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(color: widget.scheme.outline, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                widget.entry.licenses.join('\n\n---\n\n'),
                style: AppTextStyles.monoMd.copyWith(
                  color: widget.scheme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'ライセンス情報がありません',
        style: AppTextStyles.stdBaseNormal.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: scheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            '読み込みに失敗しました',
            style: AppTextStyles.stdSmBold.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTextStyles.dnsSmNormal.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        ],
      ),
    );
  }
}
