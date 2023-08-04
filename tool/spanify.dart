import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:markdown/markdown.dart' as md;

main(List<String> args) {
  var argParser = ArgParser(allowTrailingOptions: true)
    ..addOption("html", help: "Template HTML.");
  var options = argParser.parse(args);

  var htmlTemplatePath = options['html'];
  var markdown = options.rest.single;

  var mdSource = File(markdown).readAsStringSync();
  var htmlSource = md.markdownToHtml(mdSource);
  var doc = parseFragment(htmlSource);

  for (var e in doc.children) {
    _recursiveWalk(e);
  }

  var html = doc.outerHtml;
  var css = _buildCss().toString();

  if (htmlTemplatePath == null) {
    // Just output the HTML, followed by
    print(html);
    print(css);
  } else {
    // Output the template file updated in marked places with output.
    var template = File(htmlTemplatePath).readAsStringSync();
    var output = template
        .replaceFirst('<!-- GENERATED HTML -->', html)
        .replaceFirst('/* GENERATED CSS */', css);
    print(output);
  }
}

/// Number of steps in which to build the page.
const _keyframesCount = 20;

/// Mapping from class names to the index of the `keyframes` definition.
final Map<String, int> _classToKeyframes = {};

final _endsWithWhitespace = RegExp(r'\s$');

/// Index of the first generated class name, so that we start with something
/// like `_2s` instead of `_0`.
int _index = 100;

final Random _rand = Random();

final _startWithWhitespace = RegExp(r'^\s');

final _wordBoundary = RegExp(r'\b');

/// Builds the CSS.
String _buildCss() {
  final StringBuffer css = StringBuffer();
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
        ${i + 2}% {color: white;}
        ${i + 30}% {color: inherit;}
      }
  '''
      .trim()
      .replaceAll(RegExp(r'\n'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Recursively walk the tree and wrap `<span>` around each word. Assign
/// a new class to each span.
void _recursiveWalk(Element e) {
  var nodes = <Node>[];
  for (var node in e.nodes) {
    if (node is Element) {
      _recursiveWalk(node);
      nodes.add(node);
    } else if (node is Text) {
      for (var word in _splitByBoundary(node.text)) {
        if (word.isEmpty) continue;
        if (word == '&nbsps;') {
          nodes.add(Text('&nbsp;'));
          continue;
        }
        if (word == ' ') {
          nodes.add(Text(' '));
          continue;
        }
        if (word.contains('\n') && word.trim().isEmpty) {
          nodes.add(Text(" "));
          continue;
        }
        var className = '_${_index.toRadixString(36)}';
        var span = Element.tag('span')
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

Iterable<String> _splitByBoundary(String text) {
  final result = List<String?>.from(text.split(_wordBoundary));

  for (int i = 0; i < result.length; i++) {
    var current = result[i];
    if (current == null) continue;
    if (_endsWithWhitespace.hasMatch(current)) continue;
    for (int j = i + 1; j < result.length; j++) {
      final next = result[j];
      assert(next != null);
      if (_startWithWhitespace.hasMatch(next!)) break;
      current = '$current$next';
      result[j] = null;
    }
    result[i] = current;
  }

  return result.whereType<String>();
}
