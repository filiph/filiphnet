import 'package:markdown/markdown.dart';

class ObsidianHighlightInlineSyntax extends InlineSyntax {
  ObsidianHighlightInlineSyntax() : super(r'==(\w.+?)==');

  @override
  bool onMatch(InlineParser parser, Match match) {
    final text = match[1]!;
    final element = Element.text('span', text);
    element.attributes['class'] = 'highlight';
    parser.addNode(element);

    return true;
  }
}
