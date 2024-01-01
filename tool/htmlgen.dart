import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:html/dom.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:html/parser.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:toml/toml.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  TomlDocument document;
  try {
    document = TomlDocument.loadSync('htmlgen.toml');
  } on ParseError catch (e) {
    print("Parse error: $e");
    exit(99);
  } catch (e) {
    print("Error: $e");
    exit(3);
  }

  var options = document.toMap();
  var htmlTemplatePath = options['page_template'] as String;
  var markdownDirectoryPath = options['markdown_directory'] as String;
  var imagesDirectoryPath = options['images_directory'] as String;
  var footerMarkdownPath = options['footer_markdown_path'] as String;
  var markdownFilesBackup = options['markdown_files_backup'] as String;

  var outputDirectoryPath = options['output_directory'] as String;
  var outputImagesSubdirectoryPath =
      options['output_images_subdirectory'] as String;

  var outputDirectory = Directory(outputDirectoryPath);
  if (!outputDirectory.existsSync()) {
    print("Output directory '$outputDirectoryPath' doesn't exist. "
        "Creating.");
    outputDirectory.createSync(recursive: true);
  }

  var outputImagesDirectory =
      Directory(path.join(outputDirectoryPath, outputImagesSubdirectoryPath));
  if (!outputImagesDirectory.existsSync()) {
    print("Output directory '${outputImagesDirectory.path}' doesn't exist. "
        "Creating.");
    outputImagesDirectory.createSync(recursive: true);
  }

  var imagesDirectory = Directory(imagesDirectoryPath);
  if (!imagesDirectory.existsSync()) {
    print("Error: Images directory '$imagesDirectoryPath' doesn't exist.");
    exit(5);
  }

  var footerMarkdown = File(footerMarkdownPath).readAsStringSync();
  var footerHtml = md.markdownToHtml(
    footerMarkdown,
    extensionSet: md.ExtensionSet.gitHubWeb,
  );

  var markdownDirectory = Directory(markdownDirectoryPath);
  var markDownFiles = markdownDirectory
      .listSync()
      .whereType<File>()
      .where((element) => path.extension(element.path) == '.md')
      .toList(growable: false);

  var articles = <Article>[];

  for (var markdownPath in markDownFiles.map((f) => f.path)) {
    var mdFile = File(markdownPath);
    var mdSourceFull = mdFile.readAsStringSync();

    var filename =
        _sanitizeFilename(path.basenameWithoutExtension(markdownPath));
    var htmlFileName = path.setExtension(
      filename,
      '.html',
    );
    final blogUrl = Uri.parse('https://filiph.net/text/');
    var fullUrl = blogUrl.resolve(htmlFileName);

    // Remove and parse front-matter.
    var (frontMatter: yaml, markdown: mdSourceObsidian) =
        _readFile(mdSourceFull);

    if (yaml == null) {
      print("Skipping file with no front matter: $filename.");
      continue;
    }

    var frontMatter = loadYaml(yaml);
    var title = _smartyPants(
      frontMatter['title'] ?? path.basenameWithoutExtension(markdownPath),
    );
    var description = frontMatter['description'] ?? '';
    var date = frontMatter['date'] ?? '';
    var socialImage = frontMatter['social_image'] ??
        'https://filiph.net/img/filiphnet-text.png';
    var shouldPublish = frontMatter['publish'] == true;

    if (!shouldPublish) {
      print("Skipping '$title' "
          "as its publish is set to '${frontMatter['publish']}'");
      continue;
    }

    var createdString = frontMatter['created'];
    if (createdString == null) {
      stderr.writeln("Article '$title' has no `created` despite being marked "
          "for publishing.");
      stderr.writeln("Add something like:\n"
          "created: ${_isoDateFormat.format(DateTime.now().toUtc())}");
      exitCode = 1;
      continue;
    }
    DateTime created;
    try {
      created = DateTime.parse(createdString);
    } on FormatException catch (e) {
      stderr.writeln("Article '$title' has a `created` field that "
          "doesn't parse: $e");
      exitCode = 1;
      continue;
    }

    var obsidianEmbeds = <ObsidianEmbed>[];
    // Take the Markdown with Obsidian-specific notation
    // (such as `![[image.png]]` for an embedded picture)
    // and output a markdown that works everywhere.
    final mdSourceGeneric =
        mdSourceObsidian.replaceAllMapped(ObsidianEmbed.regExp, (e) {
      final fullMatch = e.group(0)!;
      final path = e.group(1)!;
      final dimensions = e.groupCount < 3
          // No dimensions provided.
          ? null
          // Take the group, and remove the '|' prefix.
          : e.group(2)!.substring(1);
      final embed = ObsidianEmbed(fullMatch, path, dimensions);
      obsidianEmbeds.add(embed);
      return embed.asHtml;
    });

    var htmlSource = md.markdownToHtml(
      mdSourceGeneric,
      // Use things like fenced code block.
      // See https://pub.dev/packages/markdown for details.
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    var doc = parseFragment(htmlSource);

    // Apply smartypants quotes.
    for (final element in doc.children) {
      _recursiveWalk(element);
    }

    // Gather all images. Not just embeds, but also images referenced
    // by regular (non-Obsidian) markdown or HTML.
    var images = <ImageContents>[];
    var htmlImageElements = doc.querySelectorAll('img');
    for (final image in htmlImageElements) {
      assert(image.localName == 'img');
      final src = image.attributes['src']!;
      final srcUri = Uri.parse(src);

      if (srcUri.scheme.isEmpty) {
        // We have a src without a scheme (such as 'https://') so we should
        // find the image and copy it over.
        final fullPath = path.join(imagesDirectoryPath, src);
        final data = File(fullPath).readAsBytesSync();
        final imageContents = ImageContents(src, data);
        images.add(imageContents);

        // Rewrite the src path in the element.
        final newSrcPath = imageContents.getCopiedSrcPath(
          outputImagesSubdirectoryPath: outputImagesSubdirectoryPath,
        );
        image.attributes['src'] = newSrcPath;

        // Copy the file.
        final newPath = path.join(outputDirectoryPath, newSrcPath);
        File(newPath).writeAsBytesSync(imageContents.data);
      }
    }

    var html = doc.outerHtml;

    // Output the template file updated in marked places with output.
    var template = File(htmlTemplatePath).readAsStringSync();
    var output = template
        .replaceFirst('<!-- GENERATED_HTML -->', html)
        .replaceFirst('<!-- GENERATED_FOOTER -->', footerHtml)
        .replaceAll('GENERATED_URL_ESCAPED',
            _attributeEscape.convert(fullUrl.toString()))
        .replaceAll('GENERATED_TITLE_ESCAPED', _attributeEscape.convert(title))
        // Must be _after_ the *_ESCAPED version because otherwise
        // we get things like "Videogames that teach you stuff_ESCAPED".
        .replaceAll('GENERATED_TITLE', title)
        .replaceAll('GENERATED_DESCRIPTION_ESCAPED',
            _attributeEscape.convert(description))
        .replaceAll('GENERATED_SOCIAL_IMAGE_ESCAPED',
            _attributeEscape.convert(socialImage))
        .replaceAll('<!-- GENERATED_DATE -->', date);

    var htmlFilePath = path.join(outputDirectoryPath, htmlFileName);
    File(htmlFilePath).writeAsStringSync(output);

    print('written $fullUrl');

    // Make a backup of the markdown file.
    var backupDirectory = Directory(markdownFilesBackup);
    backupDirectory.createSync(recursive: true);

    var backupFilePath =
        path.join(markdownFilesBackup, path.basename(markdownPath));
    mdFile.copySync(backupFilePath);

    var article = Article(
      url: fullUrl,
      title: title,
      description: description,
      created: created,
      socialImageUrl: socialImage,
      humanDate: date,
    );
    articles.add(article);
  }

  articles.sort((a, b) => -a.created.compareTo(b.created));

  print('\nAll articles:');
  articles.forEach((a) {
    print('${a.created} - ${a.title}');
  });
}

class Article {
  final Uri url;

  final String title;

  final String description;

  final String? socialImageUrl;

  final DateTime created;

  final String? humanDate;

  const Article({
    required this.url,
    required this.title,
    required this.description,
    required this.created,
    required this.socialImageUrl,
    required this.humanDate,
  });
}

class ImageContents {
  final String src;

  final Uint8List data;

  const ImageContents(this.src, this.data);

  String getCopiedSrcPath({required String outputImagesSubdirectoryPath}) {
    return path.join(outputImagesSubdirectoryPath, src);
  }
}

class ObsidianEmbed {
  static RegExp regExp = RegExp(r'!\[\[(.+?)(\|.+?)?\]\]');

  final String fullMatch;

  final String path;

  final String? dimensions;

  String get asHtml => '<img src="$path">';

  const ObsidianEmbed(this.fullMatch, this.path, this.dimensions)
      : assert(dimensions == null,
            "Unimplemented: dimensions of an obsidian embed");
}

String _sanitizeFilename(String input, {String replacement = ''}) {
  final result = input
      // illegalRe
      .replaceAll(
        RegExp(r'[\/\?<>\\:\*\|"]'),
        replacement,
      )
      // controlRe
      .replaceAll(
        RegExp(
          r'[\x00-\x1f\x80-\x9f]',
        ),
        replacement,
      )
      // reservedRe
      .replaceFirst(
        RegExp(r'^\.+$'),
        replacement,
      )
      // windowsReservedRe
      .replaceFirst(
        RegExp(
          r'^(con|prn|aux|nul|com[0-9]|lpt[0-9])(\..*)?$',
          caseSensitive: false,
        ),
        replacement,
      )
      // windowsTrailingRe
      .replaceFirst(RegExp(r'[\. ]+$'), replacement)
      // Spaces
      .replaceAll(' ', '-')
      // Replace many dashes in a row.
      .replaceAll(_severalDashes, '-')
      // Lowercase looks better
      .toLowerCase();

  return result.length > 255 ? result.substring(0, 255) : result;
}

final DateFormat _isoDateFormat = DateFormat('yyyy-MM-ddTHH:mm:ss.mmm000Z');

final RegExp _frontMatterLine = RegExp(r'^\s*-{3,}\s*$');

final RegExp _severalDashes = RegExp(r'\-{2,}');

/// Escaping text going into double-quoted HTML attribute values.
final _attributeEscape = HtmlEscape(HtmlEscapeMode.attribute);

/// Recursively walk the tree and fix quotes.
void _recursiveWalk(Element e) {
  for (var node in e.nodes) {
    if (node is Element) {
      _recursiveWalk(node);
    } else if (node is Text) {
      node.text = _smartyPants(node.text);
    }
  }
}

/// An extremely simplified algorithm for substituting `'` with `’`.
/// TODO: use https://github.com/munificent/journal/blob/master/packages/typographic_markdown/lib/typographic_markdown.dart
String _smartyPants(String text) {
  // List of common contractions
  var contractions = [
    "I'm",
    "you're",
    "it's",
    "don't",
    "can't",
    "won't",
    "isn't",
    "aren't",
    "he's",
    "she's",
    "they're",
    "we're",
    "wasn't",
    "wouldn't",
    "couldn't",
    "shouldn't",
    "doesn't",
    "haven't",
    "hasn't",
    "hadn't"
  ];

  // Replace single quotes in common contractions
  for (var contraction in contractions) {
    var replacement = contraction.replaceAll("'", "’");
    text = text.replaceAll(contraction, replacement);

    var capitalized =
        contraction.substring(0, 1).toUpperCase() + contraction.substring(1);
    var replacementCapitalized = capitalized.replaceAll("'", "’");
    text = text.replaceAll(capitalized, replacementCapitalized);
  }

  // Replace single quotes in simple possessives (ending with 's)
  text = text.replaceAllMapped(_simplePossessive, (match) {
    return '${match.group(1)}’s';
  });

  // Replace single quotes in simple future tense (ending with 'll)
  text = text.replaceAllMapped(_simpleFuture, (match) {
    return '${match.group(1)}’ll';
  });

  // Replace double quotes based on surrounding context
  text = text.replaceAllMapped(_doubleQuotes, (match) {
    return '“${match.group(1)}${match.group(2)}”';
  });

  return text;
}

final _simplePossessive = RegExp(r"(\w)'s\b");

final _simpleFuture = RegExp(r"(\w)'ll\b");

final _doubleQuotes = RegExp(r'"(\s?\w.*?)([!,.?;:]?\s?)"');

/// Splits file [content] into [frontMatter] and [markdown].
({String? frontMatter, String markdown}) _readFile(String content) {
  var yamlBuf = StringBuffer();
  var mdBuf = StringBuffer();
  var afterFrontMatter = false;
  int lineNo = -1;

  for (final line in LineSplitter.split(content)) {
    lineNo++;
    if (lineNo == 0) {
      if (!_frontMatterLine.hasMatch(line)) {
        // File doesn't start with front matter.
        return (frontMatter: null, markdown: content);
      }
      continue;
    }
    if (_frontMatterLine.hasMatch(line) && !afterFrontMatter) {
      // Reached end of front matter.
      afterFrontMatter = true;
      continue;
    }
    if (afterFrontMatter) {
      mdBuf.writeln(line);
    } else {
      yamlBuf.writeln(line);
    }
  }

  return (
    frontMatter: yamlBuf.toString(),
    markdown: mdBuf.toString(),
  );
}
