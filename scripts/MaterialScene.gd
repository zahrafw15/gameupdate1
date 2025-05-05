extends CanvasLayer

@onready var tombol_kembali = $BackButton as Button

# Data bab dan materi
var chapters = {
	1: {
		"title": "Bentuk Negara",
		"materials": [
			{"content": "Pizza pertama kali dibuat di Napoli, Italia pada abad ke-18.", "video": "res://assets/video1.webm"},
			{"content": "Pizza awalnya adalah roti sederhana dengan tomat.", "video": "res://assets/video2.webm"},
			{"content": "Pizza mulai populer di seluruh dunia pada abad ke-20.", "video": "res://assets/video3.webm"}
		]
	},
	2: {
		"title": "Bentuk Pemerintahan",
		"materials": [
			{"content": "Pizza Margherita dibuat pada 1889 untuk Ratu Margherita.", "video": "res://assets/video4.webm"},
			{"content": "Warna bendera Italia: merah (tomat), putih (mozzarella), hijau (basil).", "video": "res://assets/video5.webm"}
		]
	},
	3: {
		"title": "Sistem Pemerintahan",
		"materials": [
			{"content": "Adonan pizza harus diuleni selama 10 menit.", "video": "res://assets/video6.webm"},
			{"content": "Suhu oven ideal untuk pizza adalah 250°C.", "video": "res://assets/video7.webm"}
		]
	}
}
var current_chapter = 1

# Node references (diasumsikan sudah ada di scene)
@onready var chapter_buttons = $LeftPanel/ChapterList.get_children()

func _ready():
	
	# Inisialisasi tombol bab
	for i in range(chapter_buttons.size()):
		var button = chapter_buttons[i]
		button.text = "Bab %d: %s" % [i + 1, chapters[i + 1]["title"]]
		button.connect("pressed", _on_chapter_selected.bind(i + 1))
	
	# Mulai dengan materi awal
	update_content()
	
	tombol_kembali.button_down.connect(on_kembali_pressed)

func update_content():
	# Hapus konten lama (diasumsikan ada logika untuk ini di scene)
	var materials = chapters[current_chapter]["materials"]
	for material in materials:
		# Buat teks dan video (logika sederhana)
		var label = Label.new()
		label.text = material["content"]
		var video_player = VideoStreamPlayer.new()
		if material["video"] != "":
			var video_resource = load(material["video"])
			if video_resource != null:
				video_player.stream = video_resource
				video_player.play()
			else:
				print("File video tidak ditemukan: ", material["video"])
				label.text += "\n(Video tidak tersedia)"

func _on_chapter_selected(chapter_id):
	# Pilih bab baru dan perbarui konten
	current_chapter = chapter_id
	update_content()

func on_kembali_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
