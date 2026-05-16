import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'config/app_config.dart';
import 'services/gemini_clothing_analyzer.dart';
import 'widgets/error_app.dart';

void main() {
  // Valider la configuration
  try {
    AppConfig.validate();
  } catch (e) {
    print('❌ Erreur de configuration: $e');
    runApp(const ErrorApp(error: 'Clé API non configurée'));
    return;
  }
  runApp(const StyleGenieApp());
}

class StyleGenieApp extends StatelessWidget {
  const StyleGenieApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Style Genie MVP',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late GeminiClothingAnalyzer _analyzer;

  Uint8List? _selectedImage;
  ClothingAnalysis? _analysis;
  String? _suggestion;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _analyzer = GeminiClothingAnalyzer(AppConfig.geminiApiKey);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImage = imageBytes;
          _analysis = null;
          _suggestion = null;
          _errorMessage = null;
        });

        // Analyser l'image
        await _analyzeImage(imageBytes);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la capture : $e';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImage = imageBytes;
          _analysis = null;
          _suggestion = null;
          _errorMessage = null;
        });

        // Analyser l'image
        await _analyzeImage(imageBytes);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection : $e';
      });
    }
  }

  Future<void> _analyzeImage(Uint8List imageBytes) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analysis = await _analyzer.analyze(imageBytes);
      final suggestion = _analyzer.generateSuggestion(analysis);

      setState(() {
        _analysis = analysis;
        _suggestion = suggestion;
        _isLoading = false;
      });
    } on AnalysisException catch (e) {
      setState(() {
        _errorMessage = 'Erreur d\'analyse : ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur inattendue : $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Style Genie MVP'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre
              const Text(
                'Scannez votre tenue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prenez une photo ou sélectionnez une image pour obtenir une suggestion personnalisée',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Aperçu de l'image
              if (_selectedImage != null)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.memory(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune image sélectionnée',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Caméra'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Loading
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyse en cours...'),
                    ],
                  ),
                ),

              // Erreur
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          const Text(
                            'Erreur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),

              // Analyse
              if (_analysis != null && !_isLoading) ...[
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analyse de votre tenue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAnalysisRow('Type', _analysis!.clothingType),
                        _buildAnalysisRow('Couleur', _analysis!.primaryColor),
                        _buildAnalysisRow('Style', _analysis!.style),
                        _buildAnalysisRow('Fit', _analysis!.fit),
                        _buildAnalysisRow('Matière', _analysis!.materialGuess),
                        const SizedBox(height: 12),
                        _buildConfidenceBar(_analysis!.confidence),
                      ],
                    ),
                  ),
                ),
              ],

              // Suggestion
              if (_suggestion != null && !_isLoading) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.indigo[50],
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Colors.indigo[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Suggestion personnalisée',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _suggestion!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Chip(
            label: Text(value),
            backgroundColor: Colors.indigo[100],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confiance de l\'analyse',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(
              confidence > 0.9 ? Colors.green : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
