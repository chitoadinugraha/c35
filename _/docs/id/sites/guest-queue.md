# Antrian tamu
path: both

Gunakan nomor antrian saat tamu menunggu dilayani di loket atau ruang — bukan antrian pesanan dapur.

## Kapan dipakai

Aktifkan untuk klinik, loket layanan, atau antrian di mana tamu ambil nomor dan staf memanggil berikutnya.

## Di chat

Tanyakan: "Aktifkan antrian tamu di site saya dan tambahkan blok antrian untuk loket."

Home memakai **inst.site.queue** untuk mengaktifkan fitur antrian, membuat antrian lewat `site.queue.put`, dan mengingatkan Anda untuk publish.

## Di layar

1. Buka site di **Sites** → **Settings** dan aktifkan **Queue** (antrian tamu).
2. Buka **Queue** di editor site. Tambah antrian, set awalan nomor, field formulir tamu, dan reset harian jika perlu.
3. Tambahkan blok **Queue** di layout halaman lalu **Publish**.
4. Staf buka **Queue** → pilih antrian → **Call next** dan tandai tiket selesai atau dilewati.
5. Tamu buka halaman yang sudah dipublish, tap blok antrian, isi formulir, dan bisa lacak nomor lewat link track.
