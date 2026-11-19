# Dyscoach Jeux — moteur de jeux éducatifs (Godot 4.7)

> ⚠️ **DÉPRÉCIÉ — remplacé par `dyscoach_games` (dépôt séparé).**
> Depuis le 18/11/2026, la page Jouer de dyscoach.com sert le NOUVEAU moteur
> sans état piloté par JSON (protocole DPP v1, `dyscoach.github.io/dyscoach_games`).
> Ce dépôt n'est plus déployé ; il reste en ligne pour l'historique et pour un
> rollback d'urgence (bascule `GAMES_ORIGIN` dans `src/app.ts` de dyscoach).
> Sauvegarde disque : `profiles/dyscoach/cache/scratch/dyscoach-games-archive-2026-11-18.tar.gz` (SHA256 9f0d94d1301ce7eb…).
> Le pont de progression `GET/POST /api/play/godot-progress` reste compatible des deux moteurs.

Bibliothèque modulaire de jeux éducatifs courts pour enfants présentant des
troubles DYS. **Outil d'accompagnement pédagogique** : cette application n'est
ni un outil de diagnostic, ni un traitement.

## Lancer

```bash
godot --path .                    # jeu (éditeur ou binaire)
godot --headless --path . -s tests/run_tests.gd   # suite de tests complète
```

## Organisation

| Dossier | Rôle |
| --- | --- |
| `core/` | Cœur pur, sans dépendance aux autoloads : données (`exercise_data.gd`), runner de session (`session_runner.gd`), adaptation (`adaptive_engine.gd`), révision espacée (`spaced_repetition.gd`) |
| `autoload/` | Services singletons (accessibilité, audio, contenus, progression, app) |
| `content/` | Catalogues pédagogiques : fiches ExerciseDefinition en `.tres` + items |
| `games/` | Mécaniques propres à chaque jeu (vues interchangeables) |
| `ui/` | Écrans (accueil, carte des mondes, session, réglages) et composants |
| `tests/` | Suite de tests headless (`run_tests.gd`) |
| `docs/` | Architecture et guide « ajouter un exercice » |

## Conventions

- GDScript **typé** obligatoire (`: Type` sur signatures et membres).
- Le cœur ne connaît jamais les autoloads : il reçoit ses dépendances par
  paramètre.
- Les contenus pédagogiques vivent dans `content/` (Resources `.tres`),
  jamais dans le code des jeux.
- Ajouter un exercice = écrire une fiche + ses items : **aucune modification du
  moteur central** (voir `docs/ADDING_EXERCISES.md`).

## Tests

Tests unitaires et d'intégration headless, sans rendu graphique :

```bash
godot --headless --path . -s tests/run_tests.gd
```

Toute la logique métier (adaptation, révision espacée, séquençage de session,
catalogue, progression) est couverte par ces tests.

## Avertissements scientifiques

- Progression explicite, systématique et cumulative (lecture) ; répétition
  espacée et récupération active pour la consolidation.
- Aucune affirmation thérapeutique : les jeux ne « soignent » pas la dyslexie,
  la dyspraxie ou le TDAH. Les résultats sont des indicateurs dans l'app.
- Validation par des professionnels (orthophonistes, ergothérapeutes,
  enseignants spécialisés, neuropsychologues) requise avant diffusion : chaque
  fiche porte un champ `validation_status`.

Projet issu de Dyscoach — code sous la même licence que le dépôt principal.
