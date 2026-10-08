# Cara membuat chat bot di bawah 5 menit

path: ui

Panduan ini untuk wizard di layar **Bots**. Bagian **Lewat chat** ditulis terpisah.

## Lewat layar

1. Klik avatar di kanan atas.
2. Pilih **Bots**.
3. Tekan tombol **+**, lalu pilih **New Chat Bot**.
4. **Info bot** (langkah 1 dari 4)
   - Beri nama bot dan foto (opsional).
   - Pilih paket:
     - **Shared** memakai kuota Alien AI Anda (personal).
     - **Bot Lite** dan **Bot Small** punya kuota bot sendiri, harga bulanan lebih murah per pemakaian bot, dan tidak memakai kuota personal Anda.
   - Pesan sambutan: hanya bisa diatur pada paket bot berbayar (Shared memakai intro Alien AI).
5. **Channel** (langkah 2)
   - Pilih channel, misalnya:
     - **Telegram** — token dari @BotFather.
     - **WhatsApp Meta Cloud API** — kredensial Business API.
     - **WhatsApp Scan QR** — scan QR dari HP Anda.
6. **Asset** (langkah 3, opsional)
   - Jika punya sumber data (Google Sheet, Google Doc, Google Slides), tambahkan di sini agar bot menjawab sesuai data Anda.
   - **Read only** / **Read & write** diatur **per asset**, bukan per bot:
     - **Read only** — bot hanya membaca data (default untuk Doc/Slides).
     - **Read & write** — hanya untuk Google Sheet; bot bisa menambah atau mengubah baris lewat tool.
7. **Instruksi & perilaku** (langkah 4)
   - Tulis instruksi: apa yang boleh dan tidak boleh bot lakukan.
   - **Strict mode** — bot hanya menjawab topik yang relevan dengan instruksi; menolak obrolan di luar topik.
   - **Block Spammer Automatically** — muncul jika Strict mode aktif; memblokir pengguna yang mengirim banyak pesan tidak relevan (misalnya 10+).
   - **Web search** — bot bisa mencari dan membuka halaman web untuk jawaban faktual terkini.
8. Tekan **Finish & turn on** untuk menyimpan dan mengaktifkan bot.

## Catatan produk (jangan hapus dari outline)

- Wizard punya 4 langkah internal; urutan di atas menggabungkan navigasi app + langkah wizard.
- Menutup wizard setelah langkah 1 tetap menyimpan draft bot (nonaktif sampai Anda selesai).
