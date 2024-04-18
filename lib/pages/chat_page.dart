import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String pdfText;

  const ChatPage({
    super.key,
    required this.pdfText,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _questionController = TextEditingController();
  String _answer = '';

  Future<List<double>> _computeEmbeddings(String text) async {
    final url = Uri.parse('https://api.openai.com/v1/embeddings');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer sk-proj-hRisQyBDgeTFc6koCwUYT3BlbkFJ4Vo8vix2MqwYvASieXMb',
    };
    final body = jsonEncode({
      'model': 'text-embedding-ada-002',
      'input': text,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<double>.from(data['data'][0]['embedding']);
    } else {
      throw Exception('Failed to compute embeddings');
    }
  }

  Future<String> _analyzeTextWithAI(String question) async {
    final questionEmbeddings = await _computeEmbeddings(question);
    final pdfEmbeddings = await _computeEmbeddings(widget.pdfText);

    List<double> similarities = [];
    for (int i = 0; i < pdfEmbeddings.length; i += 1536) {
      final embeddingChunk =
          pdfEmbeddings.sublist(i, min(i + 1536, pdfEmbeddings.length));
      final similarity =
          _cosineSimilarity(questionEmbeddings, embeddingChunk);
      similarities.add(similarity);
    }

    final sortedIndices = similarities.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String relevantSections = '';
    for (int i = 0; i < 3 && i < sortedIndices.length; i++) {
      final index = sortedIndices[i].key;
      final startIndex = max(0, index * 1536 - 200);
      final endIndex = min(widget.pdfText.length, index * 1536 + 1736);
      relevantSections +=
          '${widget.pdfText.substring(startIndex, endIndex)}\n\n';
    }

    final prompt =
        'Based on the following relevant sections from the PDF:\n\n$relevantSections\nAnswer the question: $question';
    final url = Uri.parse('https://api.openai.com/v1/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer sk-proj-hRisQyBDgeTFc6koCwUYT3BlbkFJ4Vo8vix2MqwYvASieXMb'
    };
    final body = jsonEncode({
      'model': 'text-davinci-003',
      'prompt': prompt,
      'max_tokens': 500,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['text'];
    } else {
      throw Exception('Failed to analyze text with AI');
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    final dotProduct =
        a.fold(0.0, (sum, value) => sum + value * b[a.indexOf(value)]);
    final aMagnitude = sqrt(a.fold(0.0, (sum, value) => sum + value * value));
    final bMagnitude = sqrt(b.fold(0.0, (sum, value) => sum + value * value));
    return dotProduct / (aMagnitude * bMagnitude);
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isNotEmpty) {
      final answer = await _analyzeTextWithAI(question);
      setState(() {
        _answer = answer;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _questionController,
          decoration: const InputDecoration(
            hintText: 'Enter your question',
          ),
        ),
        ElevatedButton(
          onPressed: _askQuestion,
          child: const Text('Ask'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Text(_answer),
          ),
        ),
      ],
    );
  }
}