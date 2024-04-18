import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import './chat_page.dart';

class UploadPDFPage extends StatefulWidget {
  const UploadPDFPage({super.key});

  @override
  _UploadPDFPageState createState() => _UploadPDFPageState();
}

class _UploadPDFPageState extends State<UploadPDFPage> {
  File? _pdfFile;
  String _pdfText = '';

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
      });
      _extractPDFText();
    }
  }

  Future<void> _extractPDFText() async {
    final PdfDocument document = PdfDocument(inputBytes: _pdfFile!.readAsBytesSync());
    String text = PdfTextExtractor(document).extractText();

    document.dispose();

    setState(() {
      _pdfText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Question Answering'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickPDF,
              child: const Text('Select PDF'),
            ),
            const SizedBox(height: 16),
            if (_pdfText.isNotEmpty)
              Expanded(
                child: ChatPage(
                  pdfText: _pdfText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}