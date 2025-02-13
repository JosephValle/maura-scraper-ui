import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logical_interface/bloc/scraper_bloc.dart';
import '../../main.dart';

class TagSelectionScreen extends StatefulWidget {
  const TagSelectionScreen({super.key});

  @override
  State<TagSelectionScreen> createState() => _TagSelectionScreenState();
}

class _TagSelectionScreenState extends State<TagSelectionScreen> {
  late final bloc = context.read<ScraperBloc>();
  List<String> selectedTags = [];

  @override
  void initState() {
    super.initState();
    selectedTags = bloc.selectedTags;
  }

  void _handleUpdateTags() {
    Navigator.pop(context);
    bloc.add(UpdateTags(selectedTags));
  }

  void _handleClearTags() {
    setState(() {
      selectedTags = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Go Back (Without Saving)',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Tag Selection'),
        actions: [
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
                for (final String tag in availableTags) tagTile(tag),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget tagTile(String tag) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: selectedTags.contains(tag) ? Colors.blue : Colors.white,
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
          onTap: () {
            setState(() {
              if (selectedTags.contains(tag)) {
                selectedTags.remove(tag);
              } else {
                selectedTags.add(tag);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              tag,
              style: TextStyle(
                color: selectedTags.contains(tag) ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
