import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<JournalEntry> journalEntries = [];
  String selectedQuote = "Good mornings!";
  bool _isAwaitingResponse = false;
  String _lastDateHeader = "";

  final String ollamaModel = "journalbud";

  @override
  void initState() {
    super.initState();
    _setTodayDateHeader();
  }

  void _setTodayDateHeader() {
    final now = DateTime.now();
    final formatter = DateFormat('MMMM d, yyyy');
    _lastDateHeader = formatter.format(now);
    
    // Add initial date entry
    journalEntries.add(JournalEntry(
      isDateHeader: true,
      content: "Today, $_lastDateHeader",
      timestamp: now,
    ));
  }

  Future<String> fetchOllamaResponse(String prompt) async {
    final uri = Uri.parse('http://10.0.2.2:11434/api/chat');

    final request = http.Request("POST", uri);
    request.headers["Content-Type"] = "application/json";
    request.body = jsonEncode({
      "model": ollamaModel,
      "messages": [
        {"role": "user", "content": prompt}
      ]
    });

    try {
      final streamedResponse = await request.send();
      final content = StringBuffer();

      await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.trim().split(RegExp(r'\r?\n'));
        for (final line in lines) {
          try {
            final jsonLine = jsonDecode(line);
            final part = jsonLine["message"]?["content"];
            if (part != null) content.write(part);
          } catch (_) {}
        }
      }

      return content.toString().trim().isNotEmpty
          ? content.toString().trim()
          : "Hmm, I'm not sure what to say.";
    } catch (e) {
      return "⚠️ Failed to connect to AI.";
    }
  }

  void _checkAndAddDateHeader() {
    final now = DateTime.now();
    final formatter = DateFormat('MMMM d, yyyy');
    final today = formatter.format(now);
    
    if (_lastDateHeader != today) {
      journalEntries.add(JournalEntry(
        isDateHeader: true,
        content: "Today, $today",
        timestamp: now,
      ));
      _lastDateHeader = today;
    }
  }

  void _onSendPressed() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    _checkAndAddDateHeader();

    setState(() {
      journalEntries.add(JournalEntry(
        isDateHeader: false,
        content: userText,
        timestamp: DateTime.now(),
        isUserMessage: true,
      ));
      _isAwaitingResponse = true;
    });

    _controller.clear();

    final aiResponse = await fetchOllamaResponse(userText);

    setState(() {
      selectedQuote = aiResponse;
      _isAwaitingResponse = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF79800), Color(0xFF6B2D06)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Center(
          child: Container(
            height: height * 0.90, // Increased from 0.8 to 0.85
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Adjusted for consistent borders
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF0D3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // Create a row to place owl and response bubble side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI response bubble
                    Expanded(
                      flex: 4,
                      child: AnimatedOpacity(
                        opacity: _isAwaitingResponse ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 100,
                            maxHeight: 200,
                          ),
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: _isAwaitingResponse
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Lottie.asset('assets/pen_thought.json', height: 40),
                                    const SizedBox(width: 10),
                                    const Text("Thinking...",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontStyle: FontStyle.italic)),
                                  ],
                                )
                              : SingleChildScrollView(
                                  child: TypewriterText(
                                    text: selectedQuote,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.brown,
                                      fontFamily: 'Sansita',
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    
                    // Owl animation
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Lottie.asset('assets/owl.json'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Journal entries display with date headers
                Expanded(
                  child: ListView.builder(
                    itemCount: journalEntries.length,
                    itemBuilder: (context, index) {
                      final entry = journalEntries[index];
                      
                      if (entry.isDateHeader) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD3B88C),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                entry.content,
                                style: const TextStyle(
                                  color: Colors.brown,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE8C2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.content,
                                style: const TextStyle(
                                  color: Colors.brown,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Multiline input box
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4D1E00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Write your journal entry...",
                            hintStyle: TextStyle(color: Colors.white70),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          maxLines: null, // Allows multiple lines
                          minLines: 1,  // Starts with one line
                          textInputAction: TextInputAction.newline, // Enter key creates a new line
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFFFFA000)),
                        onPressed: _onSendPressed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// JournalEntry model class
class JournalEntry {
  final bool isDateHeader;
  final String content;
  final DateTime timestamp;
  final bool isUserMessage;

  JournalEntry({
    required this.isDateHeader,
    required this.content,
    required this.timestamp,
    this.isUserMessage = false,
  });
}

// Typewriter animation widget
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final Duration speed;

  const TypewriterText({
    super.key,
    required this.text,
    required this.textStyle,
    this.speed = const Duration(milliseconds: 30),
  });

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _visibleText = "";
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    Future.doWhile(() async {
      if (_index >= widget.text.length) return false;
      await Future.delayed(widget.speed);
      setState(() {
        _visibleText += widget.text[_index];
        _index++;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _visibleText,
      style: widget.textStyle,
    );
  }
}