import 'package:markdown/markdown.dart';

class FilipAsideBlockSyntax extends BlockSyntax {
  static final RegExp _start = RegExp(r'^\*\*Aside:\*\*');

  @override
  RegExp get pattern => _start;

  @override
  bool canEndBlock(BlockParser parser) => false;

  @override
  Node? parse(BlockParser parser) {
    // Copied from [ParagraphSyntax].

    final childLines = <String>[parser.current.content];

    parser.advance();
    var interruptedBySetextHeading = false;
    // Eat until we hit something that ends a paragraph.
    while (!parser.isDone) {
      final syntax = interruptedBy(parser);
      if (syntax != null) {
        interruptedBySetextHeading = syntax is SetextHeaderSyntax;
        break;
      }
      childLines.add(parser.current.content);
      parser.advance();
    }

    // It is not a paragraph, but a setext heading.
    if (interruptedBySetextHeading) {
      return null;
    }

    final contents = UnparsedContent(childLines.join('\n').trimRight());
    return Element('p', [contents])..attributes['class'] = 'aside';
  }
}
