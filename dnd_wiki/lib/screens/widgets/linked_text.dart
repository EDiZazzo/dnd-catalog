import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../services/keyword_service.dart';
import '../detail_popup.dart';

class LinkedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final int? excludeItemId;
  final String? excludeItemTable;

  const LinkedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 9999,
    this.overflow = TextOverflow.clip,
    this.excludeItemId,
    this.excludeItemTable,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final keywordService = KeywordService();
    if (!keywordService.isInitialized) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final segments = keywordService.parseText(text);

    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: segments.map((segment) {
          final isKeyword = segment['isKeyword'] as bool;
          final segmentText = segment['text'] as String;

          if (isKeyword) {
            final keyword = segment['keyword'] as Map<String, dynamic>;
            final String table = keyword['type'] as String? ?? 'feats';
            final int id = keyword['id'] as int;

            if (id == excludeItemId && table == excludeItemTable) {
              return TextSpan(text: segmentText);
            }

            // Distinct, vibrant premium link colors per category (matches the app styling)
            Color linkColor;
            switch (table) {
              case 'spells':
                linkColor = const Color(0xFFC084FC); // Purple 400
                break;
              case 'classes':
                linkColor = const Color(0xFFF87171); // Red 400
                break;
              case 'subclasses':
                linkColor = const Color(0xFFFB923C); // Orange 400
                break;
              case 'feats':
                linkColor = const Color(0xFF22D3EE); // Cyan 400
                break;
              case 'species':
                linkColor = const Color(0xFF4ADE80); // Green 400
                break;
              case 'backgrounds':
                linkColor = const Color(0xFFFBBF24); // Amber 400
                break;
              case 'equipment':
                linkColor = const Color(0xFF2DD4BF); // Teal 400
                break;
              case 'magic_items':
                linkColor = const Color(0xFF60A5FA); // Blue 400
                break;
              default:
                linkColor = const Color(0xFF38BDF8); // Sky 400
            }

            return TextSpan(
              text: segmentText,
              style: TextStyle(
                color: linkColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: linkColor.withOpacity(0.5),
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  DetailPopup.show(
                    context,
                    id: keyword['id'] as int,
                    table: table,
                    schema: keyword['schema'] as String? ?? 'official',
                    themeColor: linkColor,
                  );
                },
            );
          } else {
            return TextSpan(text: segmentText);
          }
        }).toList(),
      ),
    );
  }
}
