# Architecture — Dyscoach Jeux (Godot 4.7)

## Vue d'ensemble

```
┌─────────────────────────── ui/ (écrans, composants) ──────────────────────────┐
│  home → profile_create → worlds → settings / dashboard                        │
│  ExerciseHost (games/) : UNE scène générique pour toutes les sessions          │
└──────────────┬────────────────────────────────────────────────────────────────┘
               │ signaux (answer_submitted, hint_requested)
┌──────────────▼─────────────── games/ (vues de jeux) ──────────────────────────┐
│  game_view.gd (base) → detective_sons, grapheme_phoneme, syllable_train,      │
│                        treasure_numbers, robot_guide                           │
└──────────────┬────────────────────────────────────────────────────────────────┘
               │ appelle uniquement le runner
┌──────────────▼─────────────── core/ (PUR, testé, sans autoload) ─────────────┐
│  exercise_definition / exercise_item   ← fiches normalisées (.tres)          │
│  session_runner    : machine à états d'une session (feedback progressif)     │
│  adaptive_engine   : niveaux 1..6, plancher/plafond, guidage                 │
│  spaced_repetition : planification des révisions (SM-2 adapté)               │
│  session_planner   : révision due → en cours → découverte                    │
│  content_catalog   : enregistrement validé, filtres âge/domaine/compétence   │
│  progress_store / skill_ledger : progression sérialisable                    │
│  child_profile     : agrégat profil (store + ledger + sr + préférences)      │
│  privacy_vault     : PIN adulte hashé (SHA-256 + sel)                        │
│  world_map / sr_types / access_style                                         │
└──────────────┬────────────────────────────────────────────────────────────────┘
               │ chargés/composés par
┌──────────────▼─────────────── autoload/ (services) ──────────────────────────┐
│  Access (accessibilité)  AudioMgr (TTS/sons)  Content (catalogue)            │
│  SR (révisions)  Progress (persistance user://)  App (session, pause)        │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Principes structurants

1. **Cœur pur / services minces.** Tout ce qui décide (adaptation, révisions,
   séquençage, validation) vit dans `core/` sous forme de classes sans
   dépendance aux autoloads → testables headless (58 tests). Les autoloads
   (`autoload/`) ne font qu'orchestrer et persister.
2. **Contenus ≠ code.** Les fiches pédagogiques sont des Resources `.tres`
   dans `content/`, validées à l'enregistrement (`validate()` : ids, domaines,
   indices obligatoires, doublons…). Ajouter un exercice ne touche pas le
   moteur (voir `ADDING_EXERCISES.md`).
3. **Une seule scène de session.** `ExerciseHost` porte progression, consigne,
   feedback, pause, abandon ; la mécanique visuelle est une vue interchangeable
   enregistrée dans `VIEW_SCENES`.
4. **Signaux > couplage.** Le runner expose `item_presented`, `feedback`,
   `item_completed`, `session_finished`, `hint_given` ; les vues n'émettent que
   `answer_submitted` / `hint_requested`.
5. **Accessibilité comme service.** `Access` centralise chaque réglage (§5 du
   cahier des charges) ; `AccessStyle.apply()` propage tailles/interlignes à
   toute sous-arborescence ; l'audio ne porte jamais seul l'information
   (sous-titres permanents, dégradation propre sans TTS).

## Moteur adaptatif (règles effectives)

- Réussite pondérée d'une session : `(auto + 0,5 × aidée) / items`.
- **Monter** : ≥ seuil (0,8 par défaut) **deux sessions de suite** → niveau +1
  (plafond 6). Une session mitigée remet les séries à zéro.
- **Descendre** : < seuil (0,4 par défaut) deux sessions de suite → niveau −1
  (plancher 1) + guidage renforcé.
- **Guidage** (prochaine session) : échecs ≥ 50 % → démonstration ; indices
  ≥ 30 % → guidé ; sinon autonomie.
- Le **temps de réponse n'est jamais** un critère (garde conceptuelle testée).
- Niveaux 1–2 → items facilités (delta ≤ 0) ; niveaux 5–6 → items exigeants
  (delta ≥ 0) ; sinon tous.

## Répétition espacée

Compétence → 3 phases : découverte (3 réussites autonomes consécutives pour
consolider), consolidation (intervalles 1 → 2 → 4 j), révision (intervalles
×ease, plafond 45 j). Échec → retour en consolidation à J+1, sans effacement.
`SessionPlanner` propose : révisions dues (les plus en retard d'abord) →
compétences en cours → découverte dans les domaines choisis.

## Confidentialité

- Stockage 100 % local (`user://profiles/*.json`), aucun réseau.
- Aucun champ diagnostic ; prénom facultatif ; suppression complète d'un profil.
- Espace adulte protégé par PIN hashé (SHA-256 + sel, jamais en clair).
- Les indicateurs du dashboard sont des indicateurs **dans l'application**
  (4 sessions solides consécutives = « maîtrisée »), pas des évaluations.

## Tests (portail : `tests/check.sh`)

1. **Unitaire** (`run_tests.gd`) : 58 tests / 3 372 assertions sur `core/`.
2. **Catalogue** (`check_content.gd`) : chaque fiche `.tres` charge et passe
   `validate()`.
3. **Fumée** (`smoke_app.tscn`, boot normal du projet) : les 5 écrans
   s'instancient, une session complète est jouée pour chaque exercice via le
   vrai `ExerciseHost`, la persistance écrit bien les fichiers.

Le portail échoue au moindre `SCRIPT ERROR` runtime (ils n'interrompent pas
GDScript sinon — leçon durement apprise pendant le développement).

## Limites actuelles (assumées)

- Sons d'interface générés (sinusoïdes) et TTS système : l'habillage sonore
  (voix enregistrées, banque de sons, musique douce) reste à produire.
- Art graphique de remplacement (emoji, aplats) : les univers visuels des
  mondes sont spécifiés mais pas encore illustrés.
- Tirage d'items uniforme ; la sélection intra-niveau pourrait pondérer par
  erreurs passées (les tags d'erreur sont déjà collectés).
- Une seule langue (français) ; les contenus sont pensés pour les
  particularités du français (accents significatifs, syllabation contrôlée).
