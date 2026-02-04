import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:yazdrive/theme.dart';

/// A widget that captures signatures using a canvas drawing approach.
/// The signature is stored as a base64-encoded PNG image.
class SignatureCaptureWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final ValueChanged<String?> onSignatureChanged;
  final double height;
  final Color penColor;
  final double penWidth;

  const SignatureCaptureWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.onSignatureChanged,
    this.height = 200,
    this.penColor = Colors.black,
    this.penWidth = 3.0,
  });

  @override
  State<SignatureCaptureWidget> createState() => _SignatureCaptureWidgetState();
}

class _SignatureCaptureWidgetState extends State<SignatureCaptureWidget> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSignature = false;
  final GlobalKey _canvasKey = GlobalKey();

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(List.from(_currentStroke));
        _currentStroke = [];
        _hasSignature = true;
      });
      _saveSignature();
    }
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _hasSignature = false;
    });
    widget.onSignatureChanged(null);
  }

  Future<void> _saveSignature() async {
    if (_strokes.isEmpty) {
      widget.onSignatureChanged(null);
      return;
    }

    try {
      final RenderBox? renderBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final size = renderBox.size;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // Draw signature strokes
      final paint = Paint()
        ..color = widget.penColor
        ..strokeWidth = widget.penWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in _strokes) {
        if (stroke.length < 2) continue;
        final path = Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final base64Signature = base64Encode(bytes);
        widget.onSignatureChanged('data:image/png;base64,$base64Signature');
      }
    } catch (e) {
      debugPrint('Error saving signature: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (_hasSignature)
                  TextButton.icon(
                    onPressed: _clearSignature,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              key: _canvasKey,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: _hasSignature ? AppColors.success : AppColors.lightBorder,
                  width: _hasSignature ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: _SignaturePainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                      penColor: widget.penColor,
                      penWidth: widget.penWidth,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _hasSignature ? Icons.check_circle : Icons.touch_app,
                  size: 16,
                  color: _hasSignature ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _hasSignature
                    ? 'Signature captured'
                    : 'Sign in the box above using your finger',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _hasSignature ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color penColor;
  final double penWidth;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.penColor,
    required this.penWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = penWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw signature line hint if empty
    if (strokes.isEmpty && currentStroke.isEmpty) {
      final hintPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // Draw "Sign here" line
      final y = size.height * 0.75;
      canvas.drawLine(
        Offset(20, y),
        Offset(size.width - 20, y),
        hintPaint,
      );

      // Draw X mark for signature
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'X',
          style: TextStyle(
            color: Colors.grey.withOpacity(0.4),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(24, y - textPainter.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return strokes.length != oldDelegate.strokes.length ||
        currentStroke.length != oldDelegate.currentStroke.length;
  }
}

/// A modal dialog for capturing signatures
class SignatureCaptureModal extends StatefulWidget {
  final String title;
  final String? subtitle;

  const SignatureCaptureModal({
    super.key,
    required this.title,
    this.subtitle,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SignatureCaptureModal(
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<SignatureCaptureModal> createState() => _SignatureCaptureModalState();
}

class _SignatureCaptureModalState extends State<SignatureCaptureModal> {
  String? _signature;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.1,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SignatureCaptureWidget(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    height: 250,
                    onSignatureChanged: (signature) {
                      setState(() => _signature = signature);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _signature != null
                              ? () => Navigator.pop(context, _signature)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
