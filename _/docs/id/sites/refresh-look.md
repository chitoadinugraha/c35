# Perbarui tampilan situs Anda
path: both

Gunakan panduan ini jika situs publik Anda masih terlihat seperti template lama, atau setelah Alien AI merilis pembaruan guest renderer.

## Di chat (prompt)

Tanyakan: **"Terapkan tampilan modern storefront ke situs saya."**

Anda akan melihat radius kartu, tipografi, dan tata letak link yang diperbarui di **Preview**. Lalu minta **publish** agar pengunjung mendapat HTML yang sama.

## Di layar (editor)

1. Buka situs Anda di aplikasi dan buka **Design**.
2. Di **Cards** atau **Theme**, ketuk **Modern storefront**.
3. Buka **Preview** dan periksa hub, produk, dan bar keranjang.
4. Ketuk **Publish** ketika siap untuk URL live.

## Setelah pembaruan renderer platform

Alien AI kadang menaikkan **guest renderer** (HTML publik yang dikompilasi). Anda tidak mengubah angka itu sendiri.

| Yang Anda lakukan | Yang dilihat pengunjung |
|-------------------|-------------------------|
| Hanya menyimpan draft | Halaman publik lama sampai Anda **Publish** |
| **Publish** setelah mengubah theme | Theme baru di situs live |
| Renderer dinaikkan di cluster | HTML lama sampai kunjungan pertama recompile, atau Anda **Publish** |

Kebanyakan situs yang sudah publish akan refresh pada **kunjungan pertama** setelah renderer naik. Pemilik juga bisa **Publish** untuk memaksa compile terbaru segera.
