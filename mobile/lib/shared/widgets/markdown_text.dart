import 'package:flutter/material.dart';

/// Rendu Markdown **léger** et sans dépendance, suffisant pour les réponses de
/// l'IA Ndiogoye (qui renvoie du Markdown : **gras**, *italique*, puces,
/// titres, sauts de ligne). Évite d'afficher les `**`/`*` bruts.
class MarkdownText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double height;

  const MarkdownText(
    this.text, {
    super.key,
    this.color = const Color(0xFF1E293B),
    this.fontSize = 14,
    this.height = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(color: color, fontSize: fontSize, height: height);
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: fontSize * 0.45));
        continue;
      }

      // Titres (#, ##, ###)
      final h = RegExp(r'^\s*#{1,3}\s+(.*)').firstMatch(line);
      if (h != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: _inline(
              h.group(1)!,
              base.copyWith(fontWeight: FontWeight.w700, fontSize: fontSize + 1),
            ),
          ),
        ));
        continue;
      }

      // Puces (-, *, •)
      final b = RegExp(r'^\s*[-*•]\s+(.*)').firstMatch(line);
      if (b != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 2, top: 1, bottom: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: base),
              Expanded(child: RichText(text: _inline(b.group(1)!, base))),
            ],
          ),
        ));
        continue;
      }

      widgets.add(RichText(text: _inline(line, base)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  /// Convertit **gras** / *italique* / __gras__ / _italique_ en TextSpans.
  TextSpan _inline(String s, TextStyle base) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|__(.+?)__|\*(.+?)\*|_(.+?)_');
    var i = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > i) {
        spans.add(TextSpan(text: s.substring(i, m.start), style: base));
      }
      final bold = m.group(1) ?? m.group(2);
      final ital = m.group(3) ?? m.group(4);
      if (bold != null) {
        spans.add(TextSpan(
            text: bold, style: base.copyWith(fontWeight: FontWeight.w700)));
      } else if (ital != null) {
        spans.add(TextSpan(
            text: ital, style: base.copyWith(fontStyle: FontStyle.italic)));
      }
      i = m.end;
    }
    if (i < s.length) spans.add(TextSpan(text: s.substring(i), style: base));
    return TextSpan(children: spans);
  }
}
