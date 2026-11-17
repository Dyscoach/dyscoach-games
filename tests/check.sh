#!/usr/bin/env bash
# Portail de tests Dyscoach Jeux.
# Les erreurs runtime Godot (SCRIPT ERROR) n'interrompent pas GDScript :
# ce portail garantit qu'aucune ne passe inaperçue → échec si une seule apparaît.
set -u
GODOT="${GODOT:-/opt/data/tools/godot}"
cd "$(dirname "$0")/.."
OUT="$(mktemp)"
"$GODOT" --headless --path . -s tests/run_tests.gd > "$OUT" 2>&1
EC=$?
grep -v '^Godot Engine' "$OUT"
ERRS=$(grep -c 'SCRIPT ERROR' "$OUT" || true)
if [ "$ERRS" -gt 0 ]; then
  echo "PORTAIL : $ERRS SCRIPT ERROR(s) en tests unitaires → ÉCHEC"
  rm -f "$OUT"; exit 1
fi
# Validation du catalogue pédagogique (fiches .tres).
rm -f "$OUT"
"$GODOT" --headless --path . -s tests/check_content.gd > "$OUT" 2>&1
EC2=$?
grep -E '^(OK|ECHEC|CATALOGUE|⚠)' "$OUT" || true
if [ "$EC2" -ne 0 ]; then
  echo "PORTAIL : catalogue invalide → ÉCHEC"
  rm -f "$OUT"; exit 1
fi
# Fumée applicative : écrans réels + sessions de jeu (boot normal du projet).
rm -f "$OUT"
"$GODOT" --headless --path . res://tests/smoke_app.tscn > "$OUT" 2>&1
EC3=$?
grep -E '^(SMOKE)' "$OUT" || true
SERR=$(grep -c 'SCRIPT ERROR' "$OUT" || true)
if [ "$EC3" -ne 0 ] || [ "$SERR" -gt 0 ]; then
  echo "PORTAIL : fumée applicative en échec ($SERR erreurs) → ÉCHEC"
  cat "$OUT"; rm -f "$OUT"; exit 1
fi
rm -f "$OUT"
echo "PORTAIL : UNITAIRE + CATALOGUE + FUMEE → OK"
exit 0
