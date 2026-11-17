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
grep -v '^Godot Engine' "$OUT"
ERRS=$(grep -c 'SCRIPT ERROR' "$OUT" || true)
rm -f "$OUT"
if [ "$ERRS" -gt 0 ]; then
  echo "PORTAIL : $ERRS SCRIPT ERROR(s) détecté(s) → ÉCHEC"
  exit 1
fi
exit $EC
