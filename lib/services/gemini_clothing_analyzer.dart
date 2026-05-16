import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Modèle pour l'analyse de vêtement
class ClothingAnalysis {
  final String clothingType;
  final String primaryColor;
  final List<String> secondaryColors;
  final String style;
  final String fit;
  final String materialGuess;
  final List<String> occasions;
  final double confidence;
  final String details;

  ClothingAnalysis({
    required this.clothingType,
    required this.primaryColor,
    required this.secondaryColors,
    required this.style,
    required this.fit,
    required this.materialGuess,
    required this.occasions,
    required this.confidence,
    required this.details,
  });

  factory ClothingAnalysis.fromJson(Map<String, dynamic> json) {
    return ClothingAnalysis(
      clothingType: json['clothing_type'] ?? 'Unknown',
      primaryColor: json['primary_color'] ?? 'Unknown',
      secondaryColors: List<String>.from(json['secondary_colors'] ?? []),
      style: json['style'] ?? 'Unknown',
      fit: json['fit'] ?? 'Unknown',
      materialGuess: json['material_guess'] ?? 'Unknown',
      occasions: List<String>.from(json['occasions'] ?? []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      details: json['details'] ?? '',
    );
  }

  @override
  String toString() => '''
ClothingAnalysis(
  type: $clothingType,
  color: $primaryColor,
  style: $style,
  confidence: ${(confidence * 100).toStringAsFixed(1)}%
)''';
}

class AnalysisException implements Exception {
  final String message;
  AnalysisException(this.message);

  @override
  String toString() => 'AnalysisException: $message';
}

/// Service pour analyser les vêtements avec Gemini Vision API via HTTP
class GeminiClothingAnalyzer {
  final String apiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  GeminiClothingAnalyzer(this.apiKey);

  /// Analyser une image de vêtement
  Future<ClothingAnalysis> analyze(Uint8List imageBytes) async {
    try {
      // Encoder l'image en base64
      final base64Image = base64Encode(imageBytes);

      // Construire le payload
      final payload = {
        'contents': [
          {
            'parts': [
              {
                'text': _buildAnalysisPrompt(),
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      // Appeler l'API
      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw AnalysisException('API timeout (>30s)'),
          );

      if (response.statusCode != 200) {
        throw AnalysisException(
          'API error ${response.statusCode}: ${response.body}',
        );
      }

      // Parser la réponse
      final responseData = jsonDecode(response.body);
      final text = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

      if (text.isEmpty) {
        throw AnalysisException('Empty response from API');
      }

      return _parseResponse(text);
    } on AnalysisException {
      rethrow;
    } catch (e) {
      throw AnalysisException('Analysis failed: $e');
    }
  }

  /// Construire le prompt pour l'analyse
  String _buildAnalysisPrompt() {
    return '''Analyze this clothing image and return ONLY valid JSON (no markdown, no extra text).

Return this exact structure:
{
  "clothing_type": "type of clothing (e.g., T-shirt, Jeans, Dress, Blazer)",
  "primary_color": "main color",
  "secondary_colors": ["color1", "color2"],
  "style": "style category (Casual, Formal, Sporty, Chic, Bohemian)",
  "fit": "fit type (Slim, Regular, Loose, Oversized)",
  "material_guess": "likely material (Cotton, Wool, Silk, Synthetic)",
  "occasions": ["suitable occasion 1", "suitable occasion 2"],
  "confidence": 0.95,
  "details": "brief description of visible details"
}

Be precise and return ONLY valid JSON.''';
  }

  /// Parser la réponse JSON de Gemini
  ClothingAnalysis _parseResponse(String responseText) {
    try {
      String jsonStr = responseText.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '');
      }
      jsonStr = jsonStr.trim();

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final analysis = ClothingAnalysis.fromJson(json);

      if (analysis.confidence < 0.75) {
        throw AnalysisException(
          'Low confidence (${(analysis.confidence * 100).toStringAsFixed(1)}%)',
        );
      }

      return analysis;
    } catch (e) {
      throw AnalysisException('Failed to parse response: $e');
    }
  }

  /// Générer une suggestion de tenue basée sur l'analyse
  String generateSuggestion(ClothingAnalysis analysis) {
    final suggestions = <String>[];

    switch (analysis.style.toLowerCase()) {
      case 'casual':
        suggestions.add('Pour ce look casual, optez pour des pièces confortables et décontractées.');
        break;
      case 'chic':
        suggestions.add('Pour ce style chic, privilégiez l\'élégance et la sophistication.');
        break;
      case 'formal':
        suggestions.add('Pour ce look formel, choisissez des pièces structurées et épurées.');
        break;
      case 'sporty':
        suggestions.add('Pour ce style sportif, préférez les matières techniques et les coupes dynamiques.');
        break;
      default:
        suggestions.add('Ce style convient à diverses occasions.');
    }

    if (analysis.primaryColor.isNotEmpty) {
      suggestions.add(
        'Avec le ${analysis.primaryColor.toLowerCase()} comme couleur principale, '
        'associez-le avec des neutres ou des couleurs complémentaires.',
      );
    }

    switch (analysis.fit.toLowerCase()) {
      case 'slim':
        suggestions.add('Le fit slim met en avant votre silhouette : associez avec des accessoires discrets.');
        break;
      case 'loose':
        suggestions.add('Le fit ample offre du confort : jouez avec les accessoires pour structurer.');
        break;
      case 'oversized':
        suggestions.add('Le style oversized est tendance : équilibrez avec un bas cintré.');
        break;
    }

    if (analysis.occasions.isNotEmpty) {
      suggestions.add('Idéal pour : ${analysis.occasions.take(2).join(", ")}.');
    }

    suggestions.add(
      'Confiance de l\'analyse : ${(analysis.confidence * 100).toStringAsFixed(0)}% - '
      'N\'hésitez pas à personnaliser selon vos préférences !',
    );

    return suggestions.join('\n\n');
  }
}
