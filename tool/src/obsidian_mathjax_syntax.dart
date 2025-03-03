import 'package:markdown/markdown.dart';

class ObsidianMathJaxInlineSyntax extends InlineSyntax {
  ObsidianMathJaxInlineSyntax() : super(r'\$(.+?)\$');

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(Text(match.group(0)!));
    return true;
  }
}

class ObsidianMathJaxBlockSyntax extends BlockSyntax {
  static final RegExp _start = RegExp(r'^\$\$$');

  static final RegExp _end = RegExp(r'^\$\$$');

  @override
  RegExp get pattern => _start;

  @override
  Node? parse(BlockParser parser) {
    final buf = StringBuffer();
    buf.writeln(parser.current.content);
    parser.advance();

    while (!parser.isDone) {
      buf.writeln(parser.current.content);

      final match = _end.firstMatch(parser.current.content);
      if (match == null) {
        parser.advance();
        continue;
      } else {
        parser.advance();
        break;
      }
    }
    return Text(buf.toString());
  }
}
