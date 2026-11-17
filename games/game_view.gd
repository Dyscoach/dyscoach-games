class_name GameView
extends Control
## Vue de base d'un jeu : présentation d'un item, émission des réponses.
## Toute la logique (feedback, adaptation, stats) vit dans le SessionRunner :
## une vue ne fait que de l'affichage et de l'interaction.

const AccessStyle := preload("res://ui/access_style.gd")

signal answer_submitted(answer: String)
signal hint_requested

var item: Resource = null


## Appelée par l'hôte à chaque nouvel item.
func present_item(p_item: Resource) -> void:
	item = p_item
	_apply_access_style(self)


## Texte à prononcer pour la consigne de l'item (surchargeable).
func spoken_prompt(p_item: Resource) -> String:
	return p_item.prompt_text


## Un choix tactile a été fait (les vues appellent cette méthode protégée).
func _on_answer_pressed(answer: String) -> void:
	answer_submitted.emit(answer)


func _on_hint_pressed() -> void:
	hint_requested.emit()


## Applique les réglages d'accessibilité à toute la sous-arborescence.
func _apply_access_style(node: Node) -> void:
	AccessStyle.apply(node)
