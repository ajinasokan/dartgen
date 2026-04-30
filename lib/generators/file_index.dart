import 'dart:io';

import 'package:path/path.dart' as p;
import '../generators/generator.dart';
import '../models/index.dart';
import '../utils.dart';

class FileIndexGenerator extends Generator {
  final GeneratorConfig config;
  final String formatterVersion;
  String? _lastGenerated;

  FileIndexGenerator({
    required this.config,
    required this.formatterVersion,
  });

  @override
  void init() {
    process(config.dir);
  }

  @override
  bool shouldRun(WatchEvent event) =>
      event.path.startsWith(config.dir!) && event.type != ChangeType.MODIFY;

  @override
  bool isLastGenerated(String path) => path == _lastGenerated;

  @override
  void resetLastGenerated() => _lastGenerated = null;

  @override
  void process(String? path) {
    log('Index: ${config.dir} ');
    final outFileName = config.outputFile ?? 'index.dart';
    var paths = listFiles(config.dir!, config.recursive!)
        .where((i) => !_isPartFile(i!))
        .map((i) => p.relative(i!, from: config.dir))
        .toList();
    paths.remove(outFileName);
    if (paths.isEmpty) return null;
    final exports = paths.map((i) => "export '$i';");
    final outFilePath = p.join(config.dir!, outFileName);

    try {
      var output = formatCode(exports.join('\n'), formatterVersion);
      if (fileWriteString(outFilePath, output)) {
        logDone();
      } else {
        logNoChange();
      }
    } catch (e) {
      print(e);
      return;
    }

    _lastGenerated = outFilePath;
  }

  bool _isPartFile(String path) => _PartFileScanner(path).isPartFile();
}

class _PartFileScanner {
  final RandomAccessFile _file;
  final _buffer = <int>[];
  var _index = 0;
  var _done = false;

  _PartFileScanner(String path) : _file = File(path).openSync();

  bool isPartFile() {
    try {
      _skipByteOrderMark();
      _skipScriptTag();
      _skipWhitespaceAndComments();
      while (_peek() == 0x40) {
        // @
        if (!_skipMetadata()) return false;
        _skipWhitespaceAndComments();
      }

      if (_readIdentifier() != 'part') return false;
      _skipWhitespaceAndComments();
      if (_readIdentifier() != 'of') return false;
      _skipWhitespaceAndComments();
      return _skipPartOfTarget() && _read() == 0x3b;
    } catch (_) {
      return false;
    } finally {
      _file.closeSync();
    }
  }

  void _skipByteOrderMark() {
    if (_peek() == 0xef && _peek(1) == 0xbb && _peek(2) == 0xbf) {
      _read();
      _read();
      _read();
    }
  }

  void _skipScriptTag() {
    if (_peek() == 0x23 && _peek(1) == 0x21) {
      // #!
      _skipLine();
    }
  }

  void _skipWhitespaceAndComments() {
    while (true) {
      while (_isWhitespace(_peek())) {
        _read();
      }

      if (_peek() == 0x2f && _peek(1) == 0x2f) {
        // //
        _skipLine();
        continue;
      }

      if (_peek() == 0x2f && _peek(1) == 0x2a) {
        // /*
        _skipBlockComment();
        continue;
      }

      return;
    }
  }

  bool _skipMetadata() {
    _read();
    _skipWhitespaceAndComments();
    if (!_skipQualifiedIdentifier()) return false;

    _skipWhitespaceAndComments();
    if (_peek() == 0x28 && !_skipGroup(0x28)) {
      // (
      return false;
    }

    return true;
  }

  bool _skipPartOfTarget() {
    if (_skipStringLiteralToken()) {
      _skipWhitespaceAndComments();
      while (_skipStringLiteralToken()) {
        _skipWhitespaceAndComments();
      }
      return true;
    }

    final isName = _skipQualifiedIdentifier();
    _skipWhitespaceAndComments();
    return isName;
  }

  bool _skipQualifiedIdentifier() {
    if (_readIdentifier() == null) return false;

    while (true) {
      _skipWhitespaceAndComments();
      if (_peek() != 0x2e) return true;

      // .
      _read();
      _skipWhitespaceAndComments();
      if (_readIdentifier() == null) return false;
    }
  }

  bool _skipGroup(int openDelimiter) {
    final closeDelimiter = _matchingCloseDelimiter(openDelimiter);
    if (closeDelimiter == null) return false;

    final closeDelimiters = <int>[];
    _read();
    closeDelimiters.add(closeDelimiter);

    while (closeDelimiters.isNotEmpty) {
      final byte = _read();
      if (byte == null) return false;

      if (byte == 0x2f && _peek() == 0x2f) {
        // //
        _skipLine();
        continue;
      }

      if (byte == 0x2f && _peek() == 0x2a) {
        // /*
        _skipBlockCommentAfterSlash();
        continue;
      }

      if (_isRawStringPrefix(byte) && _isQuote(_peek())) {
        final quote = _read()!;
        if (!_skipStringLiteralAfterOpening(quote, raw: true)) return false;
        continue;
      }

      if (_isQuote(byte)) {
        if (!_skipStringLiteralAfterOpening(byte, raw: false)) return false;
        continue;
      }

      if (byte == 0x28) {
        // (
        closeDelimiters.add(0x29);
      } else if (byte == 0x5b) {
        // [
        closeDelimiters.add(0x5d);
      } else if (byte == 0x7b) {
        // {
        closeDelimiters.add(0x7d);
      } else if (byte == closeDelimiters.last) {
        closeDelimiters.removeLast();
      }
    }

    _skipWhitespaceAndComments();
    return true;
  }

  void _skipLine() {
    while (true) {
      final byte = _read();
      if (byte == null || byte == 0x0a || byte == 0x0d) return;
    }
  }

  void _skipBlockComment() {
    _read();
    _skipBlockCommentAfterSlash();
  }

  void _skipBlockCommentAfterSlash() {
    _read();

    var depth = 1;
    while (depth > 0) {
      final byte = _read();
      if (byte == null) return;

      if (byte == 0x2f && _peek() == 0x2a) {
        // /*
        _read();
        depth++;
      } else if (byte == 0x2a && _peek() == 0x2f) {
        // */
        _read();
        depth--;
      }
    }
  }

  bool _skipStringLiteralToken() {
    final byte = _peek();
    if (_isRawStringPrefix(byte) && _isQuote(_peek(1))) {
      _read();
      final quote = _read()!;
      return _skipStringLiteralAfterOpening(quote, raw: true);
    }

    if (_isQuote(byte)) {
      final quote = _read()!;
      return _skipStringLiteralAfterOpening(quote, raw: false);
    }

    return false;
  }

  bool _skipStringLiteralAfterOpening(int quote, {required bool raw}) {
    final multiline = _peek() == quote && _peek(1) == quote;
    if (multiline) {
      _read();
      _read();
    }

    while (true) {
      final byte = _read();
      if (byte == null) return false;

      if (!raw && byte == 0x5c) {
        // \
        _read();
        continue;
      }

      if (!raw && byte == 0x24) {
        // $
        if (_peek() == 0x7b) {
          // {
          if (!_skipGroup(0x7b)) return false;
          continue;
        }

        if (_isIdentifierStart(_peek())) {
          _readIdentifier();
          continue;
        }
      }

      if (byte != quote) continue;

      if (!multiline) return true;

      if (_peek() == quote && _peek(1) == quote) {
        _read();
        _read();
        return true;
      }
    }
  }

  String? _readIdentifier() {
    final first = _peek();
    if (!_isIdentifierStart(first)) return null;

    final bytes = <int>[];
    bytes.add(_read()!);
    while (_isIdentifierPart(_peek())) {
      bytes.add(_read()!);
    }

    return String.fromCharCodes(bytes);
  }

  int? _peek([int offset = 0]) {
    while (!_done && _index + offset >= _buffer.length) {
      final bytes = _file.readSync(4096);
      if (bytes.isEmpty) {
        _done = true;
      } else {
        _buffer.addAll(bytes);
      }
    }

    final position = _index + offset;
    if (position >= _buffer.length) return null;
    return _buffer[position];
  }

  int? _read() {
    final byte = _peek();
    if (byte != null) _index++;
    return byte;
  }

  bool _isWhitespace(int? byte) =>
      byte == 0x20 || byte == 0x09 || byte == 0x0a || byte == 0x0d;

  bool _isQuote(int? byte) => byte == 0x22 || byte == 0x27;

  bool _isRawStringPrefix(int? byte) => byte == 0x72;

  int? _matchingCloseDelimiter(int openDelimiter) => switch (openDelimiter) {
        0x28 => 0x29,
        0x5b => 0x5d,
        0x7b => 0x7d,
        _ => null,
      };

  bool _isIdentifierStart(int? byte) =>
      byte == 0x5f ||
      byte == 0x24 ||
      (byte != null && byte >= 0x80) ||
      (byte != null && byte >= 0x41 && byte <= 0x5a) ||
      (byte != null && byte >= 0x61 && byte <= 0x7a);

  bool _isIdentifierPart(int? byte) =>
      _isIdentifierStart(byte) ||
      (byte != null && byte >= 0x30 && byte <= 0x39);
}
