import 'dart:async';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_scraper_ui/models/class_tag_model.dart';
import 'package:maura_scraper_ui/utilities/services/excel_service.dart';

import '../../logical_interface/bloc/scraper_bloc.dart';
import '../../main.dart';

class TagSelectionScreen extends StatefulWidget {
  const TagSelectionScreen({super.key});

  @override
  State<TagSelectionScreen> createState() => _TagSelectionScreenState();
}

class _TagSelectionScreenState extends State<TagSelectionScreen> {
  late final ScraperBloc bloc = context.read<ScraperBloc>();
  List<String> selectedTags = [];
  static const String _kSelectedTagsKey = 'selected_tags_v1';

  Future<void> _loadPersistedSelection() async {
    // Grab the persisted list (if any)
    final List<String>? persisted =
        sharedPreferences.getStringList(_kSelectedTagsKey);

    if (persisted != null && persisted.isNotEmpty) {
      // Keep only tags that still exist in availableTags
      final filtered = persisted
          .where((t) => availableTags.map((e) => e.tag).contains(t))
          .toList();
      setState(() {
        selectedTags = filtered;
      });
    } else {
      // Seed from the bloc’s current selection and persist it
      setState(() {
        selectedTags = List<String>.from(bloc.selectedTags);
      });
      await _saveSelection();
    }
  }

  Future<void> _saveSelection() async {
    // Write to prefs every time the selection changes
    await sharedPreferences.setStringList(_kSelectedTagsKey, selectedTags);
  }

// Optional convenience API: toggles and persists
  void _toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
    _saveSelection();
  }

  @override
  void initState() {
    super.initState();
    // Seed from bloc immediately (for instant UI), then load persisted selection.
    selectedTags = List<String>.from(bloc.selectedTags);
    // Persisted selection takes precedence if present.
    // (sharedPreferences is already initialized globally before runApp)
    unawaited(_loadPersistedSelection());
  }

  void _handleUpdateTags() {
    Navigator.pop(context);
    bloc.add(UpdateTags(selectedTags));
    _saveSelection();
  }

  void _handleClearTags() {
    setState(() {
      selectedTags = [];
    });
    _saveSelection();
  }

  Future<void> _handleUploadTags() async {
    try {
      final Uint8List? bytes = await ExcelService.pickFileBytes();
      if (bytes == null) return;

      // Try to detect extension; fall back to content sniffing for CSV
      final String? pickedName = lastPickedName;
      final String ext = (pickedName ?? '').toLowerCase();
      List<List<String>> grid;

      if (ext.endsWith('.xlsx') || ext.endsWith('.xls')) {
        grid = await ExcelService.parseExcel(bytes);
      } else if (ext.endsWith('.csv') || ExcelService.looksLikeCsv(bytes)) {
        grid = await ExcelService.parseCsv(bytes);
      } else {
        // Attempt excel first, then CSV.
        grid = await ExcelService.safeTryExcelElseCsv(bytes);
      }

      if (grid.isEmpty) {
        if (!mounted) return;
        await _showInfo(
          context,
          'No data found',
          'The uploaded file appears to be empty.',
        );
        return;
      }

      // Show preview dialog with tappable cells (popups on non-empty)
      if (!mounted) return;
      await _showGridPreviewDialog(context, grid);

      // Offer to import tags from all non-empty cells
      final Set<String> nonEmpty = grid
          .expand((row) => row)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      // also replace the content of any tags that have " with an empty string
      // dont remove it from the list, just replace it with an empty string
      for (var i = 0; i < nonEmpty.length; i++) {
        final tag = nonEmpty.elementAt(i);
        if (tag.contains('"')) {
          nonEmpty.remove(tag);
          nonEmpty.add(tag.replaceAll('"', ''));
        }
      }

      if (nonEmpty.isEmpty) return;

      if (!mounted) return;
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import tags from file?'),
          content: Text('Found ${nonEmpty.length} unique non-empty values.\n\n'
              'Add them to your selected tags?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed ?? false) {
        // Merge into current selection (set union), then persist and notify BLoC.
        final merged = <String>{...selectedTags, ...nonEmpty}.toList()..sort();
        setState(() {
          selectedTags = merged;
        });
        _saveSelection();

        // If you want the BLoC to know immediately:
        context.read<ScraperBloc>().add(UpdateTagList(merged));

        if (!mounted) return;
        await _showInfo(
          context,
          'Imported',
          'Added ${nonEmpty.length} tags to your selection.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await _showInfo(
        context,
        'Upload failed',
        'Error reading file: $e',
      );
    }
  }

  // -------- File picking (web + non-web) --------

  // -------- UI helpers --------

  Future<void> _showGridPreviewDialog(
    BuildContext context,
    List<List<String>> grid,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final int rowCount = grid.length;
        final int colCount =
            grid.map((r) => r.length).fold<int>(0, (p, c) => c > p ? c : p);

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'File Preview (tap a non-empty cell to view)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: List.generate(
                          colCount,
                          (c) => DataColumn(label: Text('Col ${c + 1}')),
                        ),
                        rows: List.generate(rowCount, (r) {
                          final row = grid[r];
                          return DataRow(
                            cells: List.generate(colCount, (c) {
                              final value =
                                  (c < row.length ? row[c] : '').toString();
                              final isEmpty = value.trim().isEmpty;
                              return DataCell(
                                InkWell(
                                  onTap: isEmpty
                                      ? null
                                      : () {
                                          showDialog<void>(
                                            context: context,
                                            builder: (cellCtx) => AlertDialog(
                                              title: Text('R${r + 1}C${c + 1}'),
                                              content: SelectableText(value),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(cellCtx),
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      value,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isEmpty
                                            ? Colors.grey
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Text('Rows: $rowCount, Columns: $colCount'),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInfo(BuildContext context, String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectAllWithArticles() {
    setState(() {
      selectedTags = availableTags
          .where((tag) => tag.hasArticles)
          .map((tag) => tag.tag)
          .toList();
    });
    _saveSelection();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: `availableTags` is assumed to be provided from your app context (as in your original file).
    return BlocBuilder<ScraperBloc, ScraperState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Go Back (Without Saving)',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('Tag Selection'),
            actions: [
              IconButton(
                onPressed: _selectAllWithArticles,
                icon: const Icon(
                  Icons.auto_awesome,
                ),
                tooltip: 'Select all Tags with Articles',
              ),
              IconButton(
                onPressed: _handleUploadTags, // FIXED: do not call immediately
                tooltip: 'Upload Tags (Excel/CSV)',
                icon: const Icon(Icons.upload_file),
              ),
              IconButton(
                onPressed: _handleUpdateTags,
                tooltip: 'Update Tags',
                icon: const Icon(Icons.check),
              ),
              IconButton(
                onPressed: _handleClearTags,
                tooltip: 'Clear Tags',
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 6,
              ),
              child: Center(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    for (final tag in availableTags) _tagTile(tag),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tagTile(TagModel tag) {
    final bool isSelected = selectedTags.contains(tag.tag);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () => _toggleTag(tag.tag),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  tag.tag,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (tag.hasArticles)
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
          ),
      ],
    );
  }
}
