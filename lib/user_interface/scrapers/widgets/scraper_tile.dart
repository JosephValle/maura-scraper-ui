import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:maura_scraper_ui/models/scraper_model.dart';

class ScraperTile extends StatefulWidget {
  final ScraperModel scraper;

  const ScraperTile({super.key, required this.scraper});

  @override
  State<ScraperTile> createState() => _ScraperTileState();
}

class _ScraperTileState extends State<ScraperTile> {
  late final ScraperModel scraper = widget.scraper;
  bool expanded = false;

  Future<void> _openUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _openUrl(context, scraper.url);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scraper.title,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${scraper.source} • ${DateFormat('MMM dd, yyyy').format(scraper.publishedDate)}',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text("Tags: ${scraper.tags.join(', ')}"),
                    const SizedBox(height: 6.0),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: expanded
                          ? HtmlWidget(
                              scraper.summary,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: expanded ? 'Collapse' : 'Expand',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    expanded = !expanded;
                  });
                },
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
