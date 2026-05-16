# AI Style Genie MVP - Semaine 1

**Status** : 🟢 **PRÊT POUR TESTER**

## 🎯 Objectif MVP Semaine 1

**Une photo → Une suggestion de tenue (texte)**

- ✅ Capture photo avec caméra
- ✅ Sélection depuis galerie
- ✅ Analyse Gemini Vision API
- ✅ Affichage de l'analyse (type, couleur, style, fit)
- ✅ Génération d'une suggestion personnalisée

## 🚀 Installation & Lancement

### Prérequis

- Flutter 3.0+ installé
- Clé API Gemini (déjà incluse dans le code)

### Étapes

```bash
# 1. Naviguer au dossier du projet
cd style_genie_mvp

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'app
flutter run -d android  # ou ios, ou chrome
```

## 📁 Structure du Projet

```
style_genie_mvp/
├── lib/
│   ├── main.dart                          # App principale + HomeScreen
│   └── services/
│       └── gemini_clothing_analyzer.dart  # Logique Gemini Vision API
├── pubspec.yaml                           # Dépendances
└── README.md                              # Ce fichier
```

## 🔑 Clé API Gemini

La clé API est incluse dans `lib/main.dart` :

```dart
final String _geminiApiKey = 'AIzaSyAjmg3JMZzlQb3CkuJp__76WSPZNogoIWc';
```

⚠️ **Attention** : En production, ne pas commiter la clé. Utiliser des variables d'environnement ou Firebase Cloud Functions.

## 📱 Utilisation

1. **Lancer l'app**
2. **Cliquer sur "Caméra"** pour prendre une photo ou **"Galerie"** pour en sélectionner une
3. **Attendre l'analyse** (~5-8 secondes)
4. **Voir les résultats** :
   - Type de vêtement détecté
   - Couleur primaire et secondaires
   - Style (Casual, Chic, Formal, etc.)
   - Fit (Slim, Regular, Loose, etc.)
   - Matière estimée
   - Confiance de l'analyse
5. **Lire la suggestion personnalisée**

## 🧪 Tester Localement

### Avec des images réelles

```bash
# Prendre une photo avec la caméra
flutter run -d android

# Ou sélectionner une image depuis la galerie
```

### Avec des images de test

Télécharger des images de vêtements depuis :
- Unsplash : https://unsplash.com/s/photos/clothing
- Pexels : https://www.pexels.com/search/clothing/

## 📊 Dépendances

| Package | Version | Raison |
|---------|---------|--------|
| `google_generativeai` | ^0.4.0 | Gemini Vision API |
| `image_picker` | ^1.0.0 | Capture caméra + galerie |
| `image` | ^4.0.0 | Traitement d'images |
| `hive_flutter` | ^1.1.0 | Cache local (Phase 2) |
| `hive` | ^2.2.0 | Cache local (Phase 2) |
| `crypto` | ^3.0.0 | Hash d'image (Phase 2) |

## 🔧 Architecture

### Flux de Données

```
HomeScreen
    ↓
[Sélectionner image]
    ↓
GeminiClothingAnalyzer.analyze()
    ↓
[Appel API Gemini]
    ↓
ClothingAnalysis (JSON parsé)
    ↓
GeminiClothingAnalyzer.generateSuggestion()
    ↓
[Afficher résultats]
```

### Classe Principale : `GeminiClothingAnalyzer`

```dart
// Analyser une image
final analyzer = GeminiClothingAnalyzer(apiKey);
final analysis = await analyzer.analyze(imageBytes);

// Générer une suggestion
final suggestion = analyzer.generateSuggestion(analysis);
```

## ⚠️ Pièges Connus

1. **Markdown dans JSON** : Gemini retourne parfois `\`\`\`json ... \`\`\`` → Nettoyé automatiquement
2. **Superpositions** : Avec blazer + chemise, retourne "Blazer outfit" au lieu de 2 items → Accepté pour MVP
3. **Latence** : 5-8 secondes par appel → Loading UI affichée
4. **Confiance variable** : 0.85-0.98 selon complexité → Seuil minimum 0.75

## 🚀 Prochaines Phases

**Phase 2 (Semaine 2)** : Stocker 10 vêtements dans Hive (dressing)
**Phase 3 (Semaine 3)** : Intégrer météo pour suggestions contextuelles
**Phase 4 (Semaine 4)** : Partager suggestion en image (screenshot)

## 📝 Notes

- **Pas de Riverpod** : Trop complexe pour MVP, utiliser State simple
- **Pas de Freezed** : Utiliser Map<String, dynamic> directement
- **Pas d'AR** : Phase 5+
- **Pas de pose estimation** : Phase 2+

## 🐛 Troubleshooting

### "Module not found: google_generativeai"

```bash
flutter pub get
flutter pub upgrade
```

### "Permission denied: Camera"

Vérifier les permissions dans :
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### "API timeout"

- Vérifier la connexion internet
- Vérifier la clé API
- Réessayer (limite 15 req/min)

## 📞 Support

Pour des questions ou bugs, vérifier :
1. La clé API est valide
2. La connexion internet fonctionne
3. L'image est en format JPEG
4. La taille de l'image < 20 MB

## 📄 Licence

MIT - Libre d'utilisation

---

**Créé avec ❤️ par Manus AI - Mai 2026**

**Status** : 🟢 **MVP SEMAINE 1 PRÊT**
