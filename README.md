Kesimpulan

- `soal-1/`: ERD, DDL PostgreSQL, kontrol double-entry, analisis 3NF.
- `soal-2/`: schema dan trigger persediaan, uji, penjelasan concurrency.
- `soal-3/`: prototype voucher kas keluar, Supabase RPC/schema, prompt log AI.
- `prompt/`: prompt yang digunakan untuk mencari yang dibutuhkan

## Tools
VS Code disarankan untuk semua nomor. PostgreSQL diperlukan untuk menguji SQL nomor 1 dan 2. Supabase adalah pilihan cloud yang disebut di nomor 3. Gemini Canvas dan NotebookLM diminta khusus nomor 3.1. Simpan bukti dan hasil AI yang benar-benar diperoleh, jangan mengarang log.

Supabase: isi URL dan anon/publishable key di `soal-3/supabase-config.js`, lalu aktifkan `USE_SUPABASE`. Jangan pernah memakai `service_role` key di frontend. RLS pada contoh adalah demo, bukan konfigurasi produksi.

## Kesimpulan
Secara keseluruhan, proyek UTS ini berhasil menunjukkan bagaimana sistem akuntansi dan inventory dapat dibangun dengan pendekatan yang konsisten, aman, dan sesuai prinsip basis data relasional. Pada soal 1, rancangan data dibuat dengan pendekatan double-entry accounting yang mengikuti prinsip 3NF, sehingga data jurnal, akun, dan detail transaksi terpisah dengan jelas serta memiliki jejak audit yang lebih terkontrol. Pendekatan ini membantu mencegah duplikasi data, menjaga integritas relasi, dan mempermudah proses audit ke depan.

Pada soal 2, penggunaan trigger berbasis `SELECT ... FOR UPDATE` membuktikan bahwa validasi stok dan kontrol transaksi dapat dilakukan secara transactional untuk mencegah race condition dan overselling. Dengan cara ini, ketika dua transaksi mencoba mengakses stok yang sama secara bersamaan, satu transaksi akan menunggu hingga transaksi sebelumnya selesai, sehingga saldo stok tetap konsisten dan data tidak rusak.

Pada soal 3, prototype voucher kas keluar yang dikembangkan dengan Supabase menunjukkan bahwa transaksi akuntansi dapat divalidasi di sisi aplikasi maupun database melalui pengecekan keseimbangan debit dan kredit, serta pembatasan posting agar data tidak dapat diubah atau dihapus setelah diposkan. Ini menegaskan pentingnya kombinasi antara validasi frontend, logika backend, dan peraturan data agar sistem akuntansi dapat dipercaya.

Kesimpulannya, proyek ini menekankan bahwa keberhasilan sistem akuntansi digital tidak hanya ditentukan oleh tampilan antarmuka, tetapi juga oleh integritas data, konsistensi transaksi, dan penerapan prinsip akuntansi yang benar. Dengan desain data yang baik dan kontrol transaksi yang kuat, sistem akuntansi dapat berjalan secara handal, aman, dan siap dikembangkan lebih lanjut menjadi solusi yang lebih kompleks.
