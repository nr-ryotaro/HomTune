import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class ManualViewerScreen extends StatefulWidget {
  final File pdfFile;
  final String deviceName;
  final String modelNumber;

  const ManualViewerScreen({
    super.key,
    required this.pdfFile,
    required this.deviceName,
    required this.modelNumber,
  });

  @override
  State<ManualViewerScreen> createState() => _ManualViewerScreenState();
}

class _ManualViewerScreenState extends State<ManualViewerScreen> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final controller = PdfController(
        document: PdfDocument.openFile(widget.pdfFile.path),
      );
      setState(() {
        _pdfController = controller;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        _errorMessage = 'PDFの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.deviceName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              widget.modelNumber,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: const Color(0xFFE5E5E5),
            height: 0.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _pdfController != null
                  ? PdfView(
                      controller: _pdfController!,
                    )
                  : const Center(
                      child: Text('PDFを読み込めませんでした'),
                    ),
    );
  }
}
