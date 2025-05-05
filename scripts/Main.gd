extends Node2D

# Konstanta game
const TOTAL_PETAK = 36
const PETAK_NEGARA = 20
const PETAK_LAIN = 16
const JUMLAH_PEMAIN = 4  # Jumlah pemain selalu 4

# Data petak (36 petak: 20 negara, 4 sudut, 6 kuis, 4 kesempatan, 2 penalti, 2 bonus)
var petak = [
	# Sisi bawah (kiri ke kanan): Start + 8 petak
	"Start", "Indonesia", "Malaysia", "Chance", "Thailand", "Airport", "Singapura", "Chance", "Vietnam",
	# Sisi kanan (bawah ke atas): Perpustakaan + 8 petak
	"Perpustakaan", "Filipina", "Brunei Darussalam", "Chance", "Laos", "Terminal", "Chance", "Myanmar", "Kamboja",
	# Sisi atas (kanan ke kiri): Masuk Penjara + 8 petak
	"Masuk Penjara", "Jepang", "Chance", "Korea", "Railway", "China", "India", "Chance", "Pakistan",
	# Sisi kiri (atas ke bawah): Kartu Perjalanan + 8 petak
	"Kartu Perjalanan", "Nepal", "Arab Saudi", "Chance", "Iran", "Harbor", "Chance", "Irak", "Turki"
]

# Soal edukasi (contoh)
var soal = [
	{
		"pertanyaan": "Apa sistem pemerintahan Indonesia?",
		"jawaban": ["Presidensial", "Parlementer", "Monarki", "Diktator"],
		"benar": 0
	},
	{
		"pertanyaan": "Negara mana yang memiliki monarki konstitusional?",
		"jawaban": ["Jepang", "Amerika Serikat", "Tiongkok", "India"],
		"benar": 0
	},
	# Tambahkan lebih banyak soal (minimal 20 untuk variasi)
]

# Data pemain
var pemain = []
var pemain_saat_ini = 0
var posisi_pemain = []
var skor_pemain = []
var di_penjara = [] # Untuk melacak status penjara

# Node UI (atur di editor)
@onready var tombol_dadu = $UI/TombolDadu
@onready var label_umpan_balik = $UI/LabelUmpanBalik
@onready var label_hasil_dadu = $UI/LabelHasilDadu
@onready var audio_lempar_dadu = $AudioLemparDadu
@onready var nama_pemain = [
	$UI/Player1/NamaPemain1,
	$UI/Player2/NamaPemain2,
	$UI/Player3/NamaPemain3,
	$UI/Player4/NamaPemain4
]
@onready var poin_pemain = [
	$UI/Player1/PoinPemain1,
	$UI/Player2/PoinPemain2,
	$UI/Player3/PoinPemain3,
	$UI/Player4/PoinPemain4
]

# Preload scene QuizPopup
var quiz_popup_scene = preload("res://scenes/QuizPopup.tscn")
var current_quiz_popup = null

# Sprite pion (4 pion untuk 4 pemain)
var sprite_pion = [
	"res://assets/flags/pion1.png",
	"res://assets/flags/pion2.png",
	"res://assets/flags/pion3.png",
	"res://assets/flags/pion4.png"
]

# Posisi petak (koordinat untuk tata letak persegi)
var posisi_petak = []

func _ready():
	# Inisialisasi posisi petak untuk tata letak persegi
	var board_pos = Vector2(340, 60) # Sudut kiri atas papan disesuaikan agar batas bawah mendekati 660
	var board_size = 600 # Ukuran papan 600x600 piksel
	var corner_size = 100 # Ukuran petak sudut: 100 piksel
	var regular_width = 62 # Lebar petak biasa untuk sisi bawah/atas: 62 piksel
	var regular_height = 100 # Tinggi petak biasa untuk sisi bawah/atas: 100 piksel
	var regular_width_side = 100 # Lebar petak biasa untuk sisi kiri/kanan: 100 piksel
	var regular_height_side = 62 # Tinggi petak biasa untuk sisi kiri/kanan: 62 piksel
	
	# Hitung total panjang sisi untuk memusatkan petak di papan
	var total_side_length_horizontal = corner_size + (regular_width * 9) # 100 + (62 * 8) = 596 piksel
	var total_side_length_vertical = corner_size + (regular_height_side * 9) # 100 + (62 * 8) = 596 piksel
	var offset_horizontal = (board_size - total_side_length_horizontal) / 2 # Margin: (600 - 596) / 2 = 2 piksel
	var offset_vertical = (board_size - total_side_length_vertical) / 2 # Margin: (600 - 596) / 2 = 2 piksel
	
	# Sisi bawah (kiri ke kanan): Start (sudut) + 8 petak biasa
	# Pastikan posisi lebih ke bawah
	posisi_petak.append(board_pos + Vector2(corner_size/2 + offset_horizontal, board_size - corner_size/2)) # Start
	for i in range(8):
		var x = corner_size + (regular_width * (i + 0.5)) + offset_horizontal
		var y = board_size - regular_height/2
		posisi_petak.append(board_pos + Vector2(x, y))
	
	# Sisi kanan (bawah ke atas): Perpustakaan (sudut) + 8 petak biasa
	posisi_petak.append(board_pos + Vector2(board_size - corner_size/2 - offset_horizontal, board_size - corner_size/2)) # Perpustakaan
	for i in range(8):
		var x = board_size - regular_width_side/2 - offset_horizontal
		var y = board_size - corner_size - (regular_height_side * (i + 0.5))
		posisi_petak.append(board_pos + Vector2(x, y))
	
	# Sisi atas (kanan ke kiri): Masuk Penjara (sudut) + 8 petak biasa
	posisi_petak.append(board_pos + Vector2(board_size - corner_size/2 - offset_horizontal, corner_size/2)) # Masuk Penjara
	for i in range(8):
		var x = board_size - corner_size - (regular_width * (i + 0.5)) - offset_horizontal
		var y = regular_height/2
		posisi_petak.append(board_pos + Vector2(x, y))
	
	# Sisi kiri (atas ke bawah): Kartu Perjalanan (sudut) + 8 petak biasa
	posisi_petak.append(board_pos + Vector2(corner_size/2 + offset_horizontal, corner_size/2)) # Kartu Perjalanan
	for i in range(8):
		var x = regular_width_side/2 + offset_horizontal
		var y = corner_size + (regular_height_side * (i + 0.5))
		posisi_petak.append(board_pos + Vector2(x, y))
	
	# Debug: Cetak semua posisi petak untuk verifikasi
	for i in range(posisi_petak.size()):
		print("Petak ", i, " (", petak[i], "): ", posisi_petak[i])
	
	# Acak soal
	soal = fisher_yates_shuffle(soal.duplicate())
	
	# Atur UI
	tombol_dadu.connect("pressed", Callable(self, "_on_dadu_dilepas"))
	tombol_dadu.connect("mouse_entered", Callable(self, "_on_tombol_dadu_mouse_entered"))
	tombol_dadu.connect("mouse_exited", Callable(self, "_on_tombol_dadu_mouse_exited"))
	
	# Langsung atur 4 pemain
	atur_pemain()

func fisher_yates_shuffle(array):
	var n = array.size()
	for i in range(n - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp
	return array

func atur_pemain():
	pemain.clear()
	posisi_pemain.clear()
	skor_pemain.clear()
	di_penjara.clear()
	
	# Langsung atur 4 pemain dengan nama default dan pion yang sudah ditentukan
	for i in range(JUMLAH_PEMAIN):
		pemain.append({
			"nama": "Pemain " + str(i + 1),
			"pion": sprite_pion[i],
			"node": buat_pion(sprite_pion[i], i)
		})
		posisi_pemain.append(0) # Mulai di petak 0 (Start)
		skor_pemain.append(0) # Mulai dengan 0 poin
		di_penjara.append(false) # Tidak di penjara saat awal
	
	# Perbarui UI untuk giliran pertama
	perbarui_ui_giliran()

func buat_pion(sprite_path, idx_pemain):
	var pion = Sprite2D.new()
	pion.texture = load(sprite_path)
	# Ukuran pion
	pion.scale = Vector2(0.7, 0.7)
	# Sesuaikan offset agar pion terlihat jelas di tengah petak
	var offset_x = (idx_pemain % 2) * 10 - 5  # Kurangi offset: Pemain 0 & 2: -5, Pemain 1 & 3: +5
	var offset_y = (idx_pemain / 2) * 10 - 5  # Kurangi offset: Pemain 0 & 1: -5, Pemain 2 & 3: +5
	pion.position = posisi_petak[0] + Vector2(offset_x, offset_y)
	pion.z_index = 1
	add_child(pion)
	# Debug: Cetak posisi awal pion
	print("Pion Pemain ", idx_pemain + 1, " posisi awal: ", pion.position)
	return pion

func _on_tombol_dadu_mouse_entered():
	tombol_dadu.modulate = Color(0.8, 0.8, 0.8)

func _on_tombol_dadu_mouse_exited():
	tombol_dadu.modulate = Color(1, 1, 1)

func _on_dadu_dilepas():
	# Cek apakah pemain sedang di penjara
	if di_penjara[pemain_saat_ini]:
		label_umpan_balik.text = "Di Penjara! Giliran dilewati."
		di_penjara[pemain_saat_ini] = false
		await get_tree().create_timer(2.0).timeout
		giliran_berikutnya()
		return
	
	# Mainkan suara lempar dadu
	if audio_lempar_dadu:
		audio_lempar_dadu.play()
	
	# Animasi tombol saat ditekan
	var tween = create_tween()
	tween.tween_property(tombol_dadu, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(tombol_dadu, "scale", Vector2(1, 1), 0.1)
	
	# Nonaktifkan tombol dadu selama animasi atau pop-up
	tombol_dadu.disabled = true
	
	# Simulasikan lempar dadu (1 sampai 6) dengan Fisher-Yates shuffle
	var opsi_dadu = [1, 2, 3, 4, 5, 6]
	opsi_dadu = fisher_yates_shuffle(opsi_dadu)
	var hasil = opsi_dadu[0]
	
	# Tampilkan hasil dadu
	label_hasil_dadu.text = "Hasil Dadu: " + str(hasil)
	
	# Gerakkan pemain dengan animasi langkah demi langkah
	var posisi_lama = posisi_pemain[pemain_saat_ini]
	var posisi_baru = (posisi_lama + hasil) % TOTAL_PETAK
	var pion = pemain[pemain_saat_ini]["node"]
	
	# Offset yang sama seperti saat inisialisasi
	var offset_x = (pemain_saat_ini % 2) * 10 - 5
	var offset_y = (pemain_saat_ini / 2) * 10 - 5
	
	# Animasi bergerak melalui setiap petak
	var current_pos = posisi_lama
	for step in range(hasil):
		current_pos = (current_pos + 1) % TOTAL_PETAK
		var posisi_tujuan = posisi_petak[current_pos] + Vector2(offset_x, offset_y)
		var tween_pion = create_tween()
		tween_pion.tween_property(pion, "position", posisi_tujuan, 0.3).set_ease(Tween.EASE_IN_OUT)
		await tween_pion.finished
		# Debug: Cetak posisi sementara
		print("Pemain ", pemain_saat_ini + 1, " langkah ", step + 1, " ke petak ", current_pos, " (", petak[current_pos], "): ", pion.position)
	
	# Perbarui posisi pemain
	posisi_pemain[pemain_saat_ini] = posisi_baru
	
	# Pastikan posisi akhir benar-benar sesuai dengan petak tujuan
	var posisi_akhir = posisi_petak[posisi_baru] + Vector2(offset_x, offset_y)
	pion.position = posisi_akhir
	# Debug: Cetak posisi akhir
	print("Pemain ", pemain_saat_ini + 1, " posisi akhir: ", pion.position)
	
	# Tampilkan keterangan di petak mana pemain berhenti
	var nama_petak = petak[posisi_baru]
	label_umpan_balik.text = "Berhenti di: " + nama_petak
	await get_tree().create_timer(1.0).timeout
	
	# Tangani aksi petak
	await tangani_aksi_petak(posisi_baru)

func tangani_aksi_petak(idx_petak):
	var petak_saat_ini = petak[idx_petak]
	if petak_saat_ini in ["Start", "Masuk Penjara", "Perpustakaan", "Kartu Perjalanan", "Airport", "Terminal", "Railway", "Harbor"]:
		# Petak sudut: Bonus atau aksi khusus
		if petak_saat_ini == "Start":
			skor_pemain[pemain_saat_ini] += 50
			label_umpan_balik.text = "Lewat Start: +50 poin!"
		elif petak_saat_ini == "Masuk Penjara":
			label_umpan_balik.text = "Di Penjara! Lewati 1 giliran."
			di_penjara[pemain_saat_ini] = true
		else:
			skor_pemain[pemain_saat_ini] += 20
			label_umpan_balik.text = petak_saat_ini + ": +20 poin!"
	elif petak_saat_ini in ["Indonesia", "Malaysia", "Singapura", "Thailand", "Filipina", "Vietnam", "Brunei Darussalam", "Myanmar", "Kamboja", "Laos", "Jepang", "Korea", "China", "India", "Pakistan", "Nepal", "Arab Saudi", "Iran", "Irak", "Turki"]:
		# Petak negara: Tampilkan pop-up pertanyaan edukasi
		var jawaban_benar = await tampilkan_pertanyaan()
		if jawaban_benar:
			skor_pemain[pemain_saat_ini] += 100
			label_umpan_balik.text = "Benar! +100 poin!"
		else:
			label_umpan_balik.text = "Jawaban salah."
	elif petak_saat_ini == "Chance":
		# Petak Chance: Berikan poin acak atau aksi khusus
		var poin_acak = randi() % 50 + 10
		if randf() > 0.5:
			skor_pemain[pemain_saat_ini] += poin_acak
			label_umpan_balik.text = "Chance: +" + str(poin_acak) + " poin!"
		else:
			skor_pemain[pemain_saat_ini] -= poin_acak
			label_umpan_balik.text = "Chance: -" + str(poin_acak) + " poin!"
	
	# Tunggu sebentar untuk menampilkan umpan balik
	await get_tree().create_timer(2.0).timeout
	giliran_berikutnya()

func tampilkan_pertanyaan():
	if soal.size() == 0:
		label_umpan_balik.text = "Tidak ada soal lagi!"
		return false
	
	# Ambil soal
	var s = soal.pop_front()
	
	# Acak opsi jawaban
	var jawaban_acak = fisher_yates_shuffle(s.jawaban.duplicate())
	var idx_benar = jawaban_acak.find(s.jawaban[s.benar])
	
	# Instansiasi pop-up
	current_quiz_popup = quiz_popup_scene.instantiate()
	add_child(current_quiz_popup)
	current_quiz_popup.setup(s.pertanyaan, jawaban_acak, idx_benar)
	
	# Tunggu jawaban dari pop-up
	var jawaban_benar = await current_quiz_popup.quiz_answered
	
	# Hapus pop-up setelah jawaban dipilih
	current_quiz_popup.queue_free()
	current_quiz_popup = null
	
	return jawaban_benar

func giliran_berikutnya():
	pemain_saat_ini = (pemain_saat_ini + 1) % JUMLAH_PEMAIN
	label_umpan_balik.text = ""
	label_hasil_dadu.text = ""
	perbarui_ui_giliran()
	# Aktifkan kembali tombol dadu
	tombol_dadu.disabled = false

func perbarui_ui_giliran():
	tombol_dadu.text = pemain[pemain_saat_ini]["nama"] + ": Lempar Dadu"
	for i in range(JUMLAH_PEMAIN):
		nama_pemain[i].text = pemain[i]["nama"]
		poin_pemain[i].text = "Poin: " + str(skor_pemain[i])
