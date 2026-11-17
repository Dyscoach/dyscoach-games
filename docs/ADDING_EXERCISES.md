# Ajouter un nouvel exercice

Un exercice = **une fiche** (données pédagogiques) + **une vue** (mécanique de
jeu) si la mécanique est nouvelle. Le moteur central n'est **jamais** modifié.

## 1. Réutiliser une mécanique existante (le cas le plus fréquent)

Si votre exercice utilise une interaction déjà présente (QCM binaire, choix
parmi N, assemblage de syllabes, comparaison, séquence d'ordres), vous n'avez
besoin que d'une nouvelle fiche `.tres` dans `content/`.

### Anatomie d'une fiche

```ini
[gd_resource type="Resource" script_class="ExerciseDefinition" load_steps=N format=3]

[ext_resource type="Script" path="res://core/exercise_definition.gd" id="1"]
[ext_resource type="Script" path="res://core/exercise_item.gd" id="2"]

[sub_resource type="Resource" id="Item1"]
script = ExtResource("2")            # TOUJOURS la première ligne du bloc
item_id = "unique_dans_la_fiche"
prompt_text = "..."
answers = ["bonne_reponse"]          # normalisation : espaces + casse ignorés,
                                     # accents PRESERVÉS (orthographe française)
distractors = ["leurre1", "leurre2"] # optionnel (choix multiples)
hints = ["indice léger", "indice appuyé"]   # OBLIGATOIRE : progression d'aide
feedback_correct = ["..."]           # valorise la démarche
feedback_error = ["..."]             # explique sans culpabiliser
segments = ["cha", "t"]              # découpage pédagogique (si pertinent)
difficulty_delta = -1                # -1 facilité, 0 nominal, +1 exigence
tags = ["son_a"]
metadata = { "emoji": "🐱" }        # données libres de la vue

[resource]
script = ExtResource("1")
exercise_id = "domaine.nom_du_jeu"   # minuscules, sans espace, unique
display_name = "Le nom lisible"
description = "Objectif pédagogique en une phrase."
domain = "langage_ecrit"             # un des 6 domaines (voir ci-dessous)
skill = "reconnaissance_sons"        # clé de progression (voir SKILL_LABELS)
prerequisites = []                   # compétences supposées acquises
base_level = 2                       # 1..6 (1 découverte … 6 réinvestissement)
age_min = 5
age_max = 7
instruction_text = "Consigne courte, une seule idée."
scene_path = "res://games/detective_sons.tscn"   # la vue à réutiliser
interaction = "listen"               # tap | drag | listen | type | sequence
duration_minutes = 4
adaptive_params = { "items_per_session": 6, "max_attempts_per_item": 2 }
source_note = "Référence pédagogique ou scientifique."
evidence_level = "etabli"            # etabli | prometteur | experimental
validation_status = "brouillon"      # brouillon | revu | valide (spécialiste)
items = [SubResource("Item1"), SubResource("Item2")]
```

**Règles de validation (bloquantes, voir `ExerciseDefinition.validate()`)** :
`exercise_id` unique et bien formé, domaine connu, consigne présente, scène
présente, au moins un item, chaque item avec id unique + prompt + réponse +
au moins un indice, aucun distracteur égal à une réponse.

**Domaines** : `langage_ecrit`, `orthographe`, `mathematiques`,
`coordination_espace`, `langage_oral`, `attention_executive`.

**Niveaux** : 1 découverte (démonstration) · 2 guidé · 3 autonome simple ·
4 intermédiaire · 5 complexe · 6 réinvestissement. Le moteur adaptatif fait
varier le niveau autour de `base_level` : prévoyez des items
`difficulty_delta = -1` (mobilisables aux niveaux 1–2) et `+1` (niveaux 5–6).

**Variante** : même mécanique, autre contenu → remplir `variant_of` avec
l'id de la fiche d'origine.

## 2. Créer une nouvelle mécanique de jeu

1. Écrire la vue : `games/mon_jeu.gd` héritant de `"res://games/game_view.gd"`,
   plus sa scène `.tscn` minimale. Contrat :
   - `present_item(item)` : afficher l'item ;
   - émettre `answer_submitted(reponse)` quand l'enfant répond ;
   - émettre `hint_requested` sur le bouton d'indice ;
   - `spoken_prompt(item)` : phrase prononcée (l'audio ne porte jamais
     seul l'information) ;
   - appeler `AccessStyle.apply(self)` après toute construction dynamique.
2. Enregistrer la scène dans `VIEW_SCENES` (`games/exercise_host.gd`) :
   une ligne `"domaine.nom_du_jeu": "res://games/mon_jeu.tscn"`.
3. Créer la fiche `.tres` comme ci-dessus avec `scene_path` pointant la vue.
4. Vérifier : `./tests/check.sh` (la fumée joue automatiquement une session
   de CHAQUE exercice du catalogue).

## 3. Contrôles qualité avant fusion

- `./tests/check.sh` vert (unitaire + catalogue + fumée).
- Consignes : une seule idée, écoutable, sous-titrée.
- Feedbacks : jamais humiliants ; l'erreur est expliquée.
- `evidence_level` honnête (cf. §12 du cahier des charges) : « etabli »
  uniquement si le mécanisme repose sur des preuves solides.
- Faire relire la fiche par un professionnel compétent avant de passer
  `validation_status` à `valide_par_specialiste`.

## 4. Ce que le moteur fait déjà pour vous

- Tirage des items de la session (nombre, mélange, filtre par niveau adaptatif).
- Feedback progressif : erreur → indice → solution montrée après
  `max_attempts_per_item`, sans pénalité.
- Stats de session → adaptation du niveau, répétition espacée, dashboard adulte.
- Pause, abandon, réécoute de consigne, réglages d'accessibilité.
