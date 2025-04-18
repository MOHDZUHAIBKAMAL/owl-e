import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> sendToOllama(String prompt) async {
  final uri = Uri.parse("http://localhost:11434/api/chat");

  final headers = {"Content-Type": "application/json"};

  final body = jsonEncode({
    "model": "journalbud",
    "messages": [
      {"role": "user", "content": prompt}
    ]
  });

  try {
    final response = await http.post(uri, headers: headers, body: body);
    final lines = LineSplitter().convert(response.body);
    final last = jsonDecode(lines.last); // Ollama streams chunked lines
    return last['message']['content'] ?? "No response";
  } catch (e) {
    return "❌ Error: $e";
  }
}
