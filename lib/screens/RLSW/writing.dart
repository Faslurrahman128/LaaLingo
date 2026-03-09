import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import '../../writingbrain/writingbrain.dart';

class Writing extends StatefulWidget {
  late ColorScheme dync;
  Writing({required this.dync, super.key});

  @override
  State<Writing> createState() => _WritingState();
}

class _WritingState extends State<Writing> {
  String headingcheck = "Handwriting Practice";

  WritingBrain _writingBrain = WritingBrain();

  @override
  Widget build(BuildContext context) {
    GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

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
              child: SfSignaturePad(
                minimumStrokeWidth: 4,
                maximumStrokeWidth: 6,
                strokeColor: widget.dync.primary,
                key: _signaturePadKey,
                backgroundColor: widget.dync.primaryContainer,
              ),
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80.0),
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
                _signaturePadKey.currentState!.clear();
              },
              icon: Icon(Icons.clear, color: Colors.white),
              label: Text(
                "Clear",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
