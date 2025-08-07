extends Button

const backgrounds_folder = "res://assets/textures/table_backgrounds/"
var backgrounds: Array[Texture2D] = []
var current_index = 0

@export var table_sprite: TextureRect

func _ready():
	_load_background()
	pressed.connect(_change_background)

func _change_background():
	if table_sprite== null:
		print("Referência ao sprite da mesa não está configurada!")
		return
	if backgrounds.is_empty() or table_sprite == null:
		return
	table_sprite.texture = backgrounds[current_index]
	current_index = (current_index + 1) % backgrounds.size()
		
func _load_background():
	var dir = DirAccess.open(backgrounds_folder)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if not dir.current_is_dir() and file.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
				var caminho = backgrounds_folder + file
				var texture = load(caminho)
				if texture is Texture2D:
					backgrounds.append(texture)
			file = dir.get_next()
		dir.list_dir_end()
	if backgrounds.is_empty():
		push_error("Nenhuma textura encontrada em %s" % backgrounds_folder)
