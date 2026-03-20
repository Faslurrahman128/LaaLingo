import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'dart:ui' as ui;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:LaaLingo/supabase_langs.dart';
import '../../writingbrain/writingbrain.dart';

class Writing extends StatefulWidget {
  late ColorScheme dync;
  Writing({required this.dync, super.key});

  @override
  State<Writing> createState() => _WritingState();
}

class _WritingState extends State<Writing> {
  final String headingcheck = "Handwriting Practice";
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  final Random _random = Random();

  String _languageCode = 'en';
  String _languageName = 'English';
  String _targetLetter = 'A';
  List<String> _letters = const ['A', 'B', 'C'];
  int _points = 0;
  int _streak = 0;
  String _lastResult = '';
  int _lastConfidence = 0;

  static const int _maskSize = 52;
  static const double _matchThreshold = 0.56;
  static const double _minPrecision = 0.52;
  static const double _minRecall = 0.45;
  static const double _insidePatternThreshold = 0.82;
  static const double _insidePatternCoverage = 0.34;

  static const Map<String, List<String>> _letterSets = {
    'en': [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
    ],
    'fr': [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
      'É', 'È', 'Ç'
    ],
    'ru': ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З', 'И', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Э', 'Ю', 'Я'],
    'ko': ['ㄱ', 'ㄴ', 'ㄷ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅅ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ', 'ㅏ', 'ㅓ', 'ㅗ', 'ㅜ', 'ㅡ', 'ㅣ'],
    'hi': ['अ', 'आ', 'इ', 'ई', 'उ', 'ऊ', 'ए', 'ऐ', 'ओ', 'औ', 'क', 'ख', 'ग', 'घ', 'च', 'ज', 'ट', 'ड', 'त', 'द', 'न', 'प', 'ब', 'म', 'य', 'र', 'ल', 'व'],
    'ta': ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ', 'க', 'ச', 'ட', 'த', 'ப', 'ம', 'ய', 'ர', 'ல', 'வ'],
    'ml': ['അ', 'ആ', 'ഇ', 'ഈ', 'ഉ', 'ഊ', 'എ', 'ഏ', 'ഐ', 'ഒ', 'ഓ', 'ക', 'ഖ', 'ഗ', 'ഘ', 'ച', 'ജ', 'ട', 'ഡ', 'ത', 'ദ', 'ന', 'പ', 'ബ', 'മ', 'യ', 'ര', 'ല', 'വ'],
    'kn': ['ಅ', 'ಆ', 'ಇ', 'ಈ', 'ಉ', 'ಊ', 'ಎ', 'ಏ', 'ಐ', 'ಒ', 'ಓ', 'ಕ', 'ಖ', 'ಗ', 'ಘ', 'ಚ', 'ಜ', 'ಟ', 'ಡ', 'ತ', 'ದ', 'ನ', 'ಪ', 'ಬ', 'ಮ', 'ಯ', 'ರ', 'ಲ', 'ವ'],
    'si': ['අ', 'ආ', 'ඇ', 'ඉ', 'ඊ', 'උ', 'ඌ', 'එ', 'ඒ', 'ඔ', 'ඕ', 'ක', 'ග', 'ච', 'ජ', 'ට', 'ඩ', 'ත', 'ද', 'න', 'ප', 'බ', 'ම', 'ය', 'ර', 'ල', 'ව', 'ස', 'හ'],
  };

  @override
  void initState() {
    super.initState();
    _loadGamification();
    _loadSelectedLanguage();
  }

  void _loadGamification() {
    final box = Hive.box('LocalDB');
    final rawPoints = box.get('writing_points');
    final rawStreak = box.get('writing_streak');

    setState(() {
      _points = (rawPoints is num)
          ? rawPoints.toInt()
          : int.tryParse(rawPoints?.toString() ?? '') ?? 0;
      _streak = (rawStreak is num)
          ? rawStreak.toInt()
          : int.tryParse(rawStreak?.toString() ?? '') ?? 0;
    });
  }

  void _saveGamification() {
    final box = Hive.box('LocalDB');
    box.put('writing_points', _points);
    box.put('writing_streak', _streak);
  }

  Future<bool> _hasDrawing() async {
    final state = _signaturePadKey.currentState;
    if (state == null) return false;

    try {
      final image = await state.toImage(pixelRatio: 0.3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) return false;
      final data = bytes.buffer.asUint8List();

      for (int i = 3; i < data.length; i += 4) {
        if (data[i] > 0) {
          return true;
        }
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  Uint8List _alphaMask(Uint8List rgba) {
    final mask = Uint8List(rgba.length ~/ 4);
    for (int i = 3, j = 0; i < rgba.length; i += 4, j++) {
      mask[j] = rgba[i] > 20 ? 1 : 0;
    }
    return mask;
  }

  _Bounds? _findBounds(Uint8List mask, int width, int height) {
    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        if (mask[idx] == 1) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) return null;
    return _Bounds(minX, minY, maxX, maxY);
  }

  Uint8List _normalizeMask(
    Uint8List srcMask,
    int srcW,
    int srcH,
    _Bounds bounds,
    int outSize,
  ) {
    final out = Uint8List(outSize * outSize);
    final bw = max(1, bounds.width);
    final bh = max(1, bounds.height);

    for (int oy = 0; oy < outSize; oy++) {
      for (int ox = 0; ox < outSize; ox++) {
        final sx = bounds.left + ((ox + 0.5) * bw / outSize).floor();
        final sy = bounds.top + ((oy + 0.5) * bh / outSize).floor();

        final cx = sx.clamp(0, srcW - 1);
        final cy = sy.clamp(0, srcH - 1);
        out[oy * outSize + ox] = srcMask[cy * srcW + cx];
      }
    }

    return out;
  }

  Uint8List _dilateMask(Uint8List src, int size, int radius) {
    final out = Uint8List(src.length);

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        bool on = false;
        for (int dy = -radius; dy <= radius && !on; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= size) continue;
          for (int dx = -radius; dx <= radius; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= size) continue;
            if (src[ny * size + nx] == 1) {
              on = true;
              break;
            }
          }
        }
        out[y * size + x] = on ? 1 : 0;
      }
    }

    return out;
  }

  Future<ui.Image> _renderReferenceLetterImage(
    int width,
    int height,
    String letter,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.black,
          fontSize: min(width, height) * 0.62,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = (width - tp.width) / 2;
    final dy = (height - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  _MatchResult _computeMatch(Uint8List drawnMask, Uint8List refMask) {
    int intersection = 0;
    int union = 0;
    int falsePositive = 0;
    int falseNegative = 0;
    int drawnInk = 0;
    int refInk = 0;

    final expandedRef = _dilateMask(refMask, _maskSize, 2);
    int insideExpandedRef = 0;

    for (int i = 0; i < drawnMask.length; i++) {
      final av = drawnMask[i] == 1;
      final bv = refMask[i] == 1;
      if (av && bv) intersection++;
      if (av || bv) union++;
      if (av && !bv) falsePositive++;
      if (!av && bv) falseNegative++;
      if (av) {
        drawnInk++;
        if (expandedRef[i] == 1) {
          insideExpandedRef++;
        }
      }
      if (bv) refInk++;
    }

    if (union == 0) {
      return const _MatchResult(hasInk: false, matched: false, confidence: 0, score: 0);
    }

    final iou = intersection / union;
    final precision = intersection / max(1, intersection + falsePositive);
    final recall = intersection / max(1, intersection + falseNegative);
    final f1 = (precision + recall) == 0
        ? 0.0
        : (2 * precision * recall) / (precision + recall);

    final blendedScore = (0.55 * f1) + (0.45 * iou);
    final insideRatio = insideExpandedRef / max(1, drawnInk);
    final patternCoverage = intersection / max(1, refInk);

    final confidence = (blendedScore * 100).round().clamp(0, 100);
    final matched = blendedScore >= _matchThreshold &&
      precision >= _minPrecision &&
      recall >= _minRecall ||
      (insideRatio >= _insidePatternThreshold &&
        patternCoverage >= _insidePatternCoverage);

    return _MatchResult(
      hasInk: true,
      matched: matched,
      confidence: confidence,
      score: blendedScore,
    );
  }

  Future<_MatchResult> _autoCheckMatch() async {
    final state = _signaturePadKey.currentState;
    if (state == null) {
      return const _MatchResult(hasInk: false, matched: false, confidence: 0, score: 0);
    }

    final drawnImage = await state.toImage(pixelRatio: 1.0);
    final drawnBytes = await drawnImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (drawnBytes == null) {
      return const _MatchResult(hasInk: false, matched: false, confidence: 0, score: 0);
    }

    final dW = drawnImage.width;
    final dH = drawnImage.height;
    final drawMask = _alphaMask(drawnBytes.buffer.asUint8List());
    final drawBounds = _findBounds(drawMask, dW, dH);
    if (drawBounds == null) {
      return const _MatchResult(hasInk: false, matched: false, confidence: 0, score: 0);
    }

    final refImage = await _renderReferenceLetterImage(dW, dH, _targetLetter);
    final refBytes = await refImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (refBytes == null) {
      return const _MatchResult(hasInk: true, matched: false, confidence: 0, score: 0);
    }

    final refMask = _alphaMask(refBytes.buffer.asUint8List());
    final refBounds = _findBounds(refMask, dW, dH);
    if (refBounds == null) {
      return const _MatchResult(hasInk: true, matched: false, confidence: 0, score: 0);
    }

    final normDraw = _normalizeMask(drawMask, dW, dH, drawBounds, _maskSize);
    final normRef = _normalizeMask(refMask, dW, dH, refBounds, _maskSize);
    return _computeMatch(normDraw, normRef);
  }

  Future<void> _checkLetter() async {
    final result = await _autoCheckMatch();
    if (!result.hasInk) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Draw the letter first, then tap Check Letter.')),
        );
      return;
    }

    setState(() {
      _lastConfidence = result.confidence;
      if (result.matched) {
        _streak += 1;
        final gained = 10 + (_streak >= 3 ? 5 : 0) + (result.confidence ~/ 20);
        _points += gained;
        _lastResult = 'PASS (${result.confidence}%) +$gained points';
      } else {
        _streak = 0;
        _points = (_points - 2).clamp(0, 1 << 30);
        _lastResult = 'FAIL (${result.confidence}%) -2 points';
      }
      _saveGamification();
    });
  }

  void _loadSelectedLanguage() {
    final box = Hive.box('LocalDB');
    final userRow = box.get('Lang');
    final rawCurrent = box.get('current_lang');
    final currentLang = (rawCurrent is num)
        ? rawCurrent.toInt()
        : int.tryParse(rawCurrent?.toString() ?? '') ?? 1;

    final slot = getLangSlot(userRow, currentLang);
    final selected = slot?['Selected_lang'];

    final langName = (selected is List && selected.isNotEmpty)
        ? selected[0].toString()
        : 'English';
    final langCode = (selected is List && selected.length >= 2)
        ? selected[1].toString().toLowerCase()
        : 'en';

    final letters = _letterSets[langCode] ?? _letterSets['en']!;

    setState(() {
      _languageName = langName;
      _languageCode = langCode;
      _letters = letters;
      _targetLetter = letters[_random.nextInt(letters.length)];
    });
  }

  void _nextLetter() {
    if (_letters.isEmpty) return;
    setState(() {
      String next = _letters[_random.nextInt(_letters.length)];
      if (_letters.length > 1) {
        while (next == _targetLetter) {
          next = _letters[_random.nextInt(_letters.length)];
        }
      }
      _targetLetter = next;
      _lastResult = '';
    });
    _signaturePadKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.dync.primary,
      appBar: AppBar(
        backgroundColor: widget.dync.primary,
        foregroundColor: widget.dync.onPrimary,
        elevation: 0,
        title: Text(
          headingcheck,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: widget.dync.onPrimary,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: widget.dync.primaryContainer,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Text(
                          _targetLetter,
                          style: TextStyle(
                            fontSize: 130,
                            fontWeight: FontWeight.w800,
                            color: widget.dync.primary.withOpacity(0.18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SfSignaturePad(
                    minimumStrokeWidth: 4,
                    maximumStrokeWidth: 6,
                    strokeColor: widget.dync.primary,
                    key: _signaturePadKey,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.dync.onPrimaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Points: $_points',
                        style: TextStyle(
                          color: widget.dync.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Streak: $_streak',
                        style: TextStyle(
                          color: widget.dync.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Write this ${_languageName} letter:',
                    style: TextStyle(
                      color: widget.dync.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Follow the pattern shape in the writing box.',
                    style: TextStyle(
                      color: widget.dync.primary.withOpacity(0.78),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _targetLetter,
                      style: TextStyle(
                        color: widget.dync.primary,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_lastResult.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _lastResult,
                        style: TextStyle(
                          color: widget.dync.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _lastConfidence / 100,
                      backgroundColor: widget.dync.primary.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _lastConfidence >= 60 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.dync.inversePrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    onPressed: () {
                      _signaturePadKey.currentState?.clear();
                    },
                    icon: Icon(Icons.clear, color: Colors.white),
                    label: Text(
                      "Clear",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.dync.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    onPressed: _checkLetter,
                    icon: Icon(Icons.check_circle, color: Colors.white),
                    label: Text(
                      "Check Letter",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.dync.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    onPressed: _nextLetter,
                    icon: Icon(Icons.navigate_next, color: Colors.white),
                    label: Text(
                      "Next Letter",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Bounds {
  final int left;
  final int top;
  final int right;
  final int bottom;

  const _Bounds(this.left, this.top, this.right, this.bottom);

  int get width => (right - left + 1).clamp(1, 1 << 30);
  int get height => (bottom - top + 1).clamp(1, 1 << 30);
}

class _MatchResult {
  final bool hasInk;
  final bool matched;
  final int confidence;
  final double score;

  const _MatchResult({
    required this.hasInk,
    required this.matched,
    required this.confidence,
    required this.score,
  });
}
