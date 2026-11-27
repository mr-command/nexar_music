// ---------------------------------------------------------------------------
// SearchScreen — online catalog search (RemixBaz + NicMusic)
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:nexar_app/components/design_system.dart';
import 'package:nexar_app/services/providers.dart';

import '../viewmodel/remote_search_providers.dart';
import '../widgets/remote_track_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const Duration _debounceDelay = Duration(milliseconds: 450);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(remoteSearchQueryProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      ref.read(remoteSearchQueryProvider.notifier).state = value.trim();
    });
  }

  void _submit(String value) {
    _debounce?.cancel();
    ref.read(remoteSearchQueryProvider.notifier).state = value.trim();
  }

  void _clear() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(remoteSearchQueryProvider.notifier).state = '';
    _searchFocus.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(designProvider);
    final query = ref.watch(remoteSearchQueryProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final horizontal = compact ? 16.0 : 24.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                child: Row(
                  children: [
                    Text('Search', style: design.headingStyle),
                    const SizedBox(width: 10),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 9,
                    //     vertical: 3,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: design.controlBackground,
                    //     borderRadius: BorderRadius.circular(20),
                    //   ),
                    //   child: Text(
                    //     'ONLINE',
                    //     style: design.subtitleStyle.copyWith(
                    //       fontSize: 9.5,
                    //       fontWeight: FontWeight.w700,
                    //       letterSpacing: 1.1,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 2, horizontal, 12),
                child: Text(
                  'Search — download straight to your library',
                  style: design.subtitleStyle.copyWith(fontSize: 12.5),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: _SearchField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  design: design,
                  showClear: _searchController.text.isNotEmpty,
                  onChanged: _onChanged,
                  onSubmitted: _submit,
                  onClear: _clear,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(child: _SearchResults(query: query)),
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.design,
    required this.showClear,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final DesignSystem design;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: design.controlBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: design.titleStyle,
        cursorColor: design.accent,
        decoration: InputDecoration(
          hintText: 'Song or artist name...',
          hintStyle: design.subtitleStyle,
          prefixIcon: Icon(
            SolarIconsOutline.magnifier,
            size: 20,
            color: design.textSecondary,
          ),
          suffixIcon: showClear
              ? IconButton(
                  tooltip: 'Clear',
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: design.textSecondary,
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final term = query.trim();

    if (term.length < 2) {
      return const _SearchMessage(
        icon: SolarIconsOutline.magnifier,
        title: 'Find music online',
        message:
            'Type at least two characters of a song or artist name'
            'Matching tracks from internet show up here, '
      );
    }

    final result = ref.watch(remoteSearchProvider(term));

    return result.when(
      loading: () => _SearchLoading(term: term),
      error: (error, _) => _SearchMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Search failed',
        message: '$error',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(remoteSearchProvider(term)),
      ),
      data: (data) {
        if (data.tracks.isEmpty) {
          return _SearchMessage(
            icon: SolarIconsBold.musicNotes,
            title: data.errors.isEmpty
                ? 'No songs found'
                : 'Could not reach the sources',
            message: data.errors.isEmpty
                ? 'Nothing matched "$term". Try a shorter query or a '
                      'different spelling.'
                : data.errors.join('\n'),
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(remoteSearchProvider(term)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 6),
              child: Row(
                children: [
                  Text(
                    '${data.tracks.length} result'
                    '${data.tracks.length == 1 ? '' : 's'}',
                    style: design.titleStyle,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ready to download',
                      style: design.subtitleStyle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search again',
                    onPressed: () => ref.invalidate(remoteSearchProvider(term)),
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: design.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (data.errors.isNotEmpty)
              _SourceErrors(errors: data.errors, design: design),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: data.tracks.length,
                itemBuilder: (context, index) =>
                    RemoteTrackTile(track: data.tracks[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SourceErrors extends StatelessWidget {
  const _SourceErrors({required this.errors, required this.design});

  final List<String> errors;
  final DesignSystem design;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: design.controlBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: design.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errors.join('  ·  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: design.subtitleStyle.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchLoading extends ConsumerWidget {
  const _SearchLoading({required this.term});

  final String term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: design.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching RemixBaz & NicMusic...',
              style: design.titleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '"$term"',
              style: design.subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchMessage extends ConsumerWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: design.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: design.headingStyle,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: design.subtitleStyle,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: design.accent,
                  foregroundColor: design.onAccent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
