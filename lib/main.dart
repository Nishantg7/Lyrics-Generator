import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(const LyricsGeneratorApp());
}

class LyricsGeneratorApp extends StatelessWidget {
  const LyricsGeneratorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lyrics Generator',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        fontFamily: 'Arial',
      ),
      home: const LyricsForm(),
    );
  }
}

class LyricsForm extends StatefulWidget {
  const LyricsForm({Key? key}) : super(key: key);

  @override
  _LyricsFormState createState() => _LyricsFormState();
}

class _LyricsFormState extends State<LyricsForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _languageController = TextEditingController();
  final _descriptionController = TextEditingController();
  String generatedLyrics = '';
  bool isLoading = false;

  // New variable to hold selected genre
  String? _selectedGenre;

  // List of predefined genres
  final List<String> genres = [
    "Pop",
    "Rock",
    "Hip-Hop/Rap",
    "Electronic/Dance",
    "Jazz",
    "R&B/Soul",
    "Country",
    "Classical",
  ];

  Future<void> generateLyrics() async {
    setState(() {
      isLoading = true;
      generatedLyrics = ''; // Clear previous lyrics to refresh
    });

    try {
      final response = await http.post(
        Uri.parse('https://your-vercel-backend-url.vercel.app/generate_lyrics'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'title': _titleController.text,
          'genre': _selectedGenre ?? '', // Use selected genre
          'language': _languageController.text,
          'description': _descriptionController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          generatedLyrics = data['content'];
        });
      } else {
        setState(() {
          generatedLyrics = 'Failed to generate lyrics: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        generatedLyrics = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void copyLyrics() {
    if (generatedLyrics.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: generatedLyrics));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lyrics copied to clipboard!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Widget buildLoadingAnimation() {
    return const CircularProgressIndicator(
      color: Color.fromARGB(255, 47, 175, 53),
      strokeWidth: 4,
      strokeCap: StrokeCap.round,
      valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 47, 175, 53)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Generate Song Lyrics',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInputField("Song Title", _titleController, "Please enter a title"),
                    const SizedBox(height: 15),
                    _buildGenreDropdown(), // Replaced genre text field with dropdown
                    const SizedBox(height: 15),
                    _buildInputField("Language", _languageController, "Please enter a language"),
                    const SizedBox(height: 15),
                    _buildInputField("Description (optional)", _descriptionController, null),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    generateLyrics();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text(
                  "Generate Lyrics",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (isLoading) buildLoadingAnimation(),
              const SizedBox(height: 20),
              if (generatedLyrics.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Text(
                            'Generated Lyrics:\n\n$generatedLyrics',
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: copyLyrics,
                            icon: const Icon(Icons.copy, color: Colors.white),
                            tooltip: 'Copy Lyrics',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Genre dropdown
  Widget _buildGenreDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: DropdownButtonFormField<String>(
          value: _selectedGenre,
          dropdownColor: Colors.black, // Set dropdown color to pure AMOLED black
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white12,
            labelText: "Genre",
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.white54),
            ),
          ),
          items: genres.map((genre) {
            return DropdownMenuItem(
              value: genre,
              child: Text(genre),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGenre = value;
            });
          },
          validator: (value) => value == null || value.isEmpty ? "Please select a genre" : null,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String? validationMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white12,
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.white54),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          validator: validationMessage != null
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return validationMessage;
                  }
                  return null;
                }
              : null,
        ),
      ),
    );
  }
}
