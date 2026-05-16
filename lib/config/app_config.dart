/// Configuration de l'application
/// ⚠️ NE PAS COMMITER LA CLÉ API EN PRODUCTION
class AppConfig {
  /// Clé API Google Gemini
  /// À remplacer par ta vraie clé depuis https://aistudio.google.com/apikey
  static const String geminiApiKey = 'AIzaSyAjmg3JMZzlQb3CkuJp__76WSPZNogoIWc';

  /// URL de base pour les appels API
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Modèle Gemini à utiliser
  static const String geminiModel = 'gemini-2.5-flash';

  /// Timeout pour les appels API (en secondes)
  static const int apiTimeoutSeconds = 30;

  /// Confiance minimale pour accepter une analyse
  static const double minConfidence = 0.75;

  /// Qualité des images capturées (0-100)
  static const int imageQuality = 85;

  /// Taille maximale des images (en MB)
  static const int maxImageSizeMB = 20;

  /// Validation de la configuration
  static bool validate() {
    if (geminiApiKey.isEmpty || geminiApiKey == 'YOUR_API_KEY_HERE') {
      throw Exception(
        'Clé API Gemini non configurée. '
        'Mets à jour lib/config/app_config.dart avec ta vraie clé.',
      );
    }
    return true;
  }
}
