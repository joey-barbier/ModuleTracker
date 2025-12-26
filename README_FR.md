# ModuleTracker

[![EN](https://img.shields.io/badge/lang-EN-blue)](README.md)

Un framework CLI Swift leger qui scanne votre codebase iOS/Swift et genere un dashboard HTML interactif affichant les metriques des modules, les patterns d'architecture et la progression de migration dans le temps.

**Caracteristique cle :** ModuleTracker est une **coquille vide** par design. Il fournit le moteur central, et votre projet ajoute des scanners et regles personnalises via un simple systeme d'enregistrement.

**Cas d'usage :**
- Suivre la progression de modularisation (monolithe → modules SPM)
- Monitorer la migration d'architecture (VIPER → VIP → SwiftUI)
- Appliquer des standards de code via des regles de detection
- Visualiser les tendances dans le temps avec des graphiques auto-generes

## Prerequis

- Swift 5.9+ (macOS 13+)
- Aucune dependance externe

## Demarrage rapide

```bash
# Cloner et compiler
git clone git@github.com:joey-barbier/ModuleTracker.git
cd ModuleTracker
swift build

# Lancer sur votre projet
swift run ModuleTracker /chemin/vers/votre/projet/ios

# Ou utiliser une variable d'environnement
export MODULE_TRACKER_ROOT=/chemin/vers/votre/projet/ios
swift run ModuleTracker

# Voir les resultats
open Output/index.html
```

## Architecture

ModuleTracker utilise un **pattern Registry** ou les scanners et regles s'enregistrent au demarrage :

```
┌─────────────────────────────────────────────────────────────┐
│                    VOTRE PROJET                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Bootstrap.swift                                     │   │
│  │  ├── _ = MonScanner._register                       │   │
│  │  ├── _ = MaRegle._register                          │   │
│  │  └── ...                                            │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ s'enregistre via
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              ModuleTracker Core (coquille vide)             │
│  ┌─────────────────┐        ┌─────────────────┐            │
│  │ ScannersRegistry│        │  RulesRegistry  │            │
│  │  (tableau vide) │        │  (tableau vide) │            │
│  └────────┬────────┘        └────────┬────────┘            │
│           │                          │                      │
│           ▼                          ▼                      │
│  ┌─────────────────┐        ┌─────────────────┐            │
│  │ ScannersEngine  │───────▶│   RulesEngine   │            │
│  │(boucle registry)│        │(boucle registry)│            │
│  └─────────────────┘        └─────────────────┘            │
│                    │                                        │
│                    ▼                                        │
│           ┌─────────────────┐                              │
│           │  HTMLExporter   │ → JSON + Dashboard           │
│           └─────────────────┘                              │
└─────────────────────────────────────────────────────────────┘
```

**Resultat :** Lancer ModuleTracker seul = 0 modules, 0 regles. Ajoutez vos scanners/regles = analyse complete.

## Structure du projet

```
Sources/ModuleTracker/
├── Core/
│   ├── ModuleInfo.swift       # Modele de donnees module
│   ├── ModuleMetrics.swift    # Modele de sortie metriques
│   ├── AnyCodable.swift       # Support champs dynamiques
│   └── HTMLExporter.swift     # Utilitaires d'export
├── Registry/
│   ├── ScannersRegistry.swift # Enregistrement scanners
│   └── RulesRegistry.swift    # Enregistrement regles
├── Scanners/
│   ├── ScannerProtocol.swift  # Interface scanner
│   └── ScannersEngine.swift   # Orchestrateur
├── Rules/
│   ├── RuleProtocol.swift     # Interface regle + FieldMetadata
│   └── RulesEngine.swift      # Orchestrateur
├── Bootstrap.swift            # VOS ENREGISTREMENTS ICI
└── main.swift                 # Point d'entree
```

## Creer un Scanner

### 1. Creez votre fichier scanner

```swift
import Foundation

struct SPMScanner {
    let rootPath: URL

    // Pattern d'auto-enregistrement
    static let _register: Void = {
        ScannersRegistry.shared.register(name: "spm") { rootPath in
            SPMScanner(rootPath: rootPath).scan()
        }
    }()

    func scan() -> [ModuleInfo] {
        var modules: [ModuleInfo] = []

        // Votre logique de decouverte
        let modulePath = rootPath.appendingPathComponent("Modules/MonModule")
        modules.append(ModuleInfo(
            name: "MonModule",
            path: modulePath,
            source: "spm"  // Identifiant String
        ))

        return modules
    }
}
```

### 2. Enregistrez dans Bootstrap.swift

```swift
enum Bootstrap {
    static func register() {
        // Scanners
        _ = SPMScanner._register
    }
}
```

## Creer une Regle

Les regles analysent les modules et retournent des donnees structurees avec des metadonnees pour le dashboard HTML.

### 1. Creez votre fichier regle

```swift
import Foundation

struct TestFrameworkRule: Rule {
    typealias Output = String

    static let name = "Test Framework"
    static let documentationFile = "test-framework.md"

    // Pattern d'auto-enregistrement
    static let _register: Void = {
        RulesRegistry.shared.registerTargetRule(metadata: metadata) { target, _ in
            let result = TestFrameworkRule().detect(in: target.path)
            return ["test_framework": result]
        }
    }()

    // Metadonnees pour le dashboard HTML
    static var metadata: FieldMetadata {
        FieldMetadata(
            id: "test_framework",
            label: "Tests",
            description: "Framework de test utilise dans le module",
            isFilterable: true,
            showInTable: true,
            showInChart: true,
            showInComparison: true,
            chartType: "line",
            chartColor: "#58a6ff",
            values: [
                "swift_testing": ValueMeta(
                    label: "Swift Testing",
                    color: "green",
                    description: "Framework Swift Testing moderne (macro @Test)"
                ),
                "xctest": ValueMeta(
                    label: "XCTest",
                    color: "orange",
                    description: "Framework XCTest legacy"
                ),
                "none": ValueMeta(
                    label: "Aucun",
                    color: "gray",
                    description: "Pas de tests trouves"
                )
            ]
        )
    }

    func detect(in path: URL) -> String {
        var hasSwiftTesting = false
        var hasXCTest = false

        SwiftFileEnumerator.enumerate(in: path) { _, content in
            if content.contains("import Testing") { hasSwiftTesting = true }
            if content.contains("import XCTest") { hasXCTest = true }
        }

        if hasSwiftTesting && hasXCTest { return "mixed" }
        if hasSwiftTesting { return "swift_testing" }
        if hasXCTest { return "xctest" }
        return "none"
    }
}
```

### 2. Enregistrez dans Bootstrap.swift

```swift
enum Bootstrap {
    static func register() {
        // Scanners
        _ = SPMScanner._register

        // Regles
        _ = TestFrameworkRule._register
    }
}
```

## Reference FieldMetadata

Chaque regle doit fournir `metadata` pour le dashboard HTML :

| Propriete | Type | Description |
|-----------|------|-------------|
| `id` | String | Identifiant unique du champ (snake_case) |
| `label` | String | Nom affiche dans l'interface |
| `description` | String | Affiche dans la modale au clic |
| `isFilterable` | Bool | Ajouter un filtre dropdown |
| `showInTable` | Bool | Afficher la colonne dans le tableau |
| `showInChart` | Bool | Generer un graphique d'evolution |
| `showInComparison` | Bool | Afficher dans la vue comparaison |
| `chartType` | String? | "line", "bar", ou "area" |
| `chartColor` | String? | Couleur hex pour le graphique |
| `values` | Dictionary | Valeurs possibles avec labels/couleurs |

### ValueMeta

Chaque valeur dans le dictionnaire `values` a :

| Propriete | Type | Description |
|-----------|------|-------------|
| `label` | String | Label affiche (ex: "Swift Testing") |
| `color` | String | Couleur du badge : green, yellow, orange, red, blue, gray, purple |
| `description` | String? | Explication affichee dans la modale |

## Utilitaires

### SwiftFileEnumerator

Scanner tous les fichiers Swift dans un repertoire :

```swift
SwiftFileEnumerator.enumerate(in: modulePath) { fileURL, content in
    if content.contains("import Testing") {
        // Trouve Swift Testing
    }
}

// Verifier si le chemin existe
if SwiftFileEnumerator.pathExists(modulePath) {
    // ...
}
```

## Sortie

- **JSON** : `Output/module-tracker.json` — Donnees brutes avec toutes les metriques
- **HTML** : `Output/index.html` — Dashboard interactif avec :
  - **Tableaux** : Listes de modules filtrables avec badges
  - **Graphiques** : Graphes d'evolution auto-generes depuis les regles `showInChart`
  - **Comparer** : Vue delta cote a cote entre snapshots
- **Historique** : `Output/history.json` — Snapshots pour suivi des tendances

## Developpement assiste par IA

Le dossier `doc_IA/` contient de la documentation concue pour les assistants IA. Quand vous travaillez avec une IA (Claude, GPT, Copilot, etc.), referencez ces fichiers :

```
"Lis doc_IA/add-rule.md et aide-moi a creer une regle qui detecte l'utilisation de Combine"
```

| Fichier | Description |
|---------|-------------|
| `doc_IA/add-rule.md` | Ajouter une regle de detection |
| `doc_IA/add-scanner.md` | Ajouter un scanner de modules |
| `doc_IA/add-chart.md` | Ajouter un graphique d'evolution |
| `doc_IA/add-snapshot-metric.md` | Ajouter une metrique suivie |
| `doc_IA/add-comparison.md` | Ajouter une ligne de comparaison |

## Demarrage (Resume)

1. Clonez ModuleTracker
2. Ajoutez vos scanners (implementez `scan() -> [ModuleInfo]` + `_register`)
3. Ajoutez vos regles (implementez `detect()` + `metadata` + `_register`)
4. Enregistrez tout dans `Bootstrap.swift`
5. Lancez `swift build && swift run`
6. Ouvrez `Output/index.html`

## Licence

MIT
