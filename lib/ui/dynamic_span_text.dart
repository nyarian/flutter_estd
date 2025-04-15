import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DynamicSpanText extends StatelessWidget {
  final String text;
  final List<DynamicSpanTextReplacement> spans;
  final TextAlign textAlign;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  const DynamicSpanText({
    required this.text,
    required this.spans,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicSpans = _orderSpans(context);
    final divided = _divideDescriptionByDynamicSpanDelimiters();
    final spans = divided.map<InlineSpan>((e) => TextSpan(text: e)).toList();
    for (int i = 0; i < dynamicSpans.length; i++) {
      spans.insert(i * 2 + 1, dynamicSpans[i]);
    }
    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(style: style, children: spans),
    );
  }

  List<InlineSpan> _orderSpans(BuildContext context) {
    return (spans.map((e) => (e.span, text.indexOf(e.marker))).toList()
          ..sort((a, b) => a.$2.compareTo(b.$2)))
        .map((e) => e.$1)
        .toList();
  }

  List<String> _divideDescriptionByDynamicSpanDelimiters() {
    final dividedText = ' $text '.split(
      RegExp(spans.map((e) => RegExp.escape(e.marker)).join('|')),
    );
    dividedText[0] = dividedText[0].trimLeft();
    dividedText[dividedText.length - 1] =
        dividedText[dividedText.length - 1].trimRight();
    return dividedText;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(IterableProperty('spans', spans))
      ..add(EnumProperty('textAlign', textAlign))
      ..add(DiagnosticsProperty('style', style))
      ..add(IntProperty('maxLines', maxLines))
      ..add(EnumProperty('overflow', overflow));
  }
}

class DynamicSpanTextReplacement {
  const DynamicSpanTextReplacement({
    required this.span,
    this.marker = '%%%MARKER%%%',
  });

  const DynamicSpanTextReplacement.regular(InlineSpan span) : this(span: span);

  final String marker;
  final InlineSpan span;
}
