import 'dart:io';
import 'dart:math';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:markdown/markdown.dart' as md;

main(args) {
  var mdSource = new File(args.single).readAsStringSync();
  var html = md.markdownToHtml(mdSource);
  var doc = parseFragment(html);

  for (var e in doc.children) {
    _recursiveWalk(e);
  }

  print(doc.outerHtml);

  print(_buildCss().toString());
}

/// Number of steps in which to build the page.
const _keyframesCount = 20;

/// Mapping from class names to the index of the `keyframes` definition.
final Map<String, int> _classToKeyframes = {};

/// Index of the first generated class name, so that we start with something
/// like `_2s` instead of `_0`.
int _index = 100;

final Random _rand = new Random();

final _whitespace = new RegExp(r'\s');

final _wordBoundary = new RegExp(r'\b');

/// Builds the CSS.
String _buildCss() {
  final StringBuffer css = new StringBuffer();
  for (int i = 1; i <= _keyframesCount; i++) {
    var classes = <String>[];
    _classToKeyframes.forEach((cl, kf) {
      if (kf != i) return;
      classes.add('.$cl');
    });
    css.write(classes.join(','));
    css.write('{animation: appear$i 6s}');
  }
  css.write("\n\n");
  for (int i = 1; i <= _keyframesCount; i++) {
    css.write(_buildKeyframes(i));
  }
  return css.toString();
}

/// Build each `@keyframe` declaration.
String _buildKeyframes(int i) {
  return '''
        @keyframes appear$i {
        0% {color: white;}
        ${i+2}% {color: white;}
        ${i+30}% {color: inherit;}
      }
  '''
      .trim()
      .replaceAll(new RegExp(r'\n'), '')
      .replaceAll(new RegExp(r'\s+'), ' ');
}

/// Recursively walk the tree and wrap `<span>` around each word. Assign
/// a new class to each span.
void _recursiveWalk(Element e) {
  var nodes = new List<Node>();
  for (var node in e.nodes) {
    if (node is Element) {
      _recursiveWalk(node);
      nodes.add(node);
    } else if (node is Text) {
      for (var word in node.text.split(_wordBoundary)) {
        if (word.isEmpty) continue;
        if (word == '&nbsps;') {
          nodes.add(new Text('&nbsp;'));
          continue;
        }
        if (word.contains('\n') && word.trim().isEmpty) {
          nodes.add(new Text(" "));
          continue;
        }
        var className = '_${_index.toRadixString(36)}';
        var span = new Element.tag('span')
          ..text = word
          ..classes.add(className);
        nodes.add(span);
        _classToKeyframes[className] = _rand.nextInt(_keyframesCount) + 1;
        _index += 1;
      }
    }
  }
  e.nodes.clear();
  e.nodes.addAll(nodes);
}
