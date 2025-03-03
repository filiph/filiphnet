import 'package:markdown/markdown.dart';

class ObsidianCommentBlockSyntax extends BlockSyntax {
  static final RegExp _start = RegExp(r'^%%[^%]*$');

  static final RegExp _end = RegExp(r'^[^%]*%%$');

  @override
  RegExp get pattern => _start;

  @override
  Node? parse(BlockParser parser) {
    parser.advance();
    while (!parser.isDone) {
      final match = _end.firstMatch(parser.current.content);
      if (match == null) {
        parser.advance();
        continue;
      } else {
        parser.advance();
        break;
      }
    }
    // Don't actually emit anything.
    return null;
  }
}

class ObsidianCommentInlineSyntax extends InlineSyntax {
  ObsidianCommentInlineSyntax() : super('%% (.+) %%');

  @override
  bool onMatch(InlineParser parser, Match match) {
    // Simply advance the parser.
    return true;
  }
}
