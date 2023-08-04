import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  for (var markdownPath in markDownFiles.map((f) => f.path)) {
    var mdFile = File(markdownPath);
    var mdSourceFull = mdFile.readAsStringSync();

    var title = path.basenameWithoutExtension(markdownPath);

    // Remove and parse front-matter.
    var yamlBuf = StringBuffer();
    var mdBuf = StringBuffer();
    var afterFrontMatter = false;
    int lineNo = -1;

    for (final line in LineSplitter.split(mdSourceFull)) {
      lineNo++;
      if (lineNo == 0) {
        if (!_frontMatterLine.hasMatch(line)) {
          throw FormatException(
              "File doesn't start with front matter: $markdownPath");
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

    var frontMatter = loadYaml(yamlBuf.toString());
    var description = frontMatter['description'] ?? '';
    var date = frontMatter['date'] ?? '';

    var mdSource = mdBuf.toString();

    var obsidianEmbeds = <ObsidianEmbed>[];
    mdSource = mdSource.replaceAllMapped(ObsidianEmbed.regExp, (e) {
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
      mdSource,
      // Use things like fenced code block.
      // See https://pub.dev/packages/markdown for details.
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    var doc = parseFragment(htmlSource);

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

    for (final image in images) {
      print('${image.src} : ${image.data.length} bytes');
    }

    var html = doc.outerHtml;

    // Output the template file updated in marked places with output.
    var template = File(htmlTemplatePath).readAsStringSync();
    var output = template
        .replaceFirst('<!-- GENERATED_HTML -->', html)
        .replaceFirst('<!-- GENERATED_FOOTER -->', footerHtml)
        .replaceAll('GENERATED_TITLE_ESCAPED', _attributeEscape.convert(title))
        .replaceAll('GENERATED_TITLE', title)
        .replaceAll('GENERATED_DESCRIPTION_ESCAPED',
            _attributeEscape.convert(description))
        .replaceAll('<!-- GENERATED_DATE -->', date);

    var htmlFileName = path.setExtension(
      _sanitizeFilename(path.basenameWithoutExtension(markdownPath)),
      '.html',
    );
    var htmlFilePath = path.join(outputDirectoryPath, htmlFileName);
    File(htmlFilePath).writeAsStringSync(output);
  }
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

String _sanitizeFilename(String input, {String replacement = '-'}) {
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
      .replaceAll(' ', replacement)
      // Lowercase looks better
      .toLowerCase();

  return result.length > 255 ? result.substring(0, 255) : result;
}

final RegExp _frontMatterLine = RegExp(r'^\s*-{3,}\s*$');

/// Escaping text going into double-quoted HTML attribute values.
final _attributeEscape = HtmlEscape(HtmlEscapeMode.attribute);
