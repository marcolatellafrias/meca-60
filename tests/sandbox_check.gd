extends Node

## LAS REGLAS DEL SANDBOX (ver docs/technical/sandbox.md, SandboxCatalogue.check): el catálogo entero sin problemas. Imprime cada
## uno y, al final, «SANDBOX OK» o cuántos hay.

func _ready() -> void:
	var problems := SandboxCatalogue.check(SandboxCatalogue.rows(), SandboxCatalogue.global_panels())
	for problem in problems:
		print("PROBLEMA: ", problem)
	print("SANDBOX OK" if problems.is_empty() else "SANDBOX: %d problemas" % problems.size())
	get_tree().quit(0 if problems.is_empty() else 1)
