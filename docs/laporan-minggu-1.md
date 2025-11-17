Laporan Kemajuan Mingguan Proyek IMK
Minggu ke: 1 Tanggal Pelaporan: 2025-11-16 Nama Anggota Tim:

Developer A

Developer B

Designer

QA

Nama Proyek:
PlantCare.ID

1. Target/Rencana Minggu Ini (Goal)
   Pada minggu ini tim berfokus untuk menyelesaikan cakupan Sprint 1 sebagaimana tertulis di perencanaan sprint, yaitu menyiapkan infrastruktur dasar proyek dan membangun fondasi autentikasi serta antarmuka dasar. Secara lebih terperinci target yang direncanakan meliputi: men-setup proyek Flutter dengan manajemen state menggunakan Riverpod dan pengaplikasian ProviderScope di `main.dart`; mengintegrasikan Supabase untuk mekanisme autentikasi dan persiapan koneksi ke database; menyiapkan kerangka backend ringan menggunakan FastAPI dengan endpoint dasar (termasuk endpoint health check); mendefinisikan design tokens untuk warna dan tipografi lalu menerapkannya ke `AppTheme.lightTheme`; membuat tampilan awal berupa splash screen dan tulang navigasi bawah (bottom navigation) dengan empat tab sementara; serta mengimplementasikan flow login, registrasi dan guest mode menggunakan Supabase sehingga pengguna dapat masuk dan diarahkan ke area aplikasi. Rencana ini sesuai dengan daftar tugas Sprint 1 pada `docs/sprint-planning.md` yang mengalokasikan 25 story points untuk sprint awal. Kami memulai minggu ini dengan merancang sprint planning berdasarkan analisis kebutuhan pada tahap sebelumnya sehingga dibuat sprint dalam 4 tahap (Sprint 1 sampai Sprint 4) dengan target menyelesaikan Sprint 1 pada minggu ini sebagai pijakan untuk pengembangan fitur inti berikutnya.

2. Kemajuan yang Dicapai (Achievements)
   Dalam periode pelaporan ini tim berhasil menyelesaikan sejumlah deliverable teknis inti sesuai checklist Sprint 1. Semua pekerjaan setup awal telah direalisasikan: proyek Flutter dibuat dan dikonfigurasi dengan riverpod (ketergantungan `flutter_riverpod` ditambahkan dan `ProviderScope` dipasang di `main.dart`), Supabase client diintegrasikan serta provider autentikasi awal dibuat, dan backend minimal berbasis FastAPI ditambahkan dengan endpoint dasar dan dokumentasi pendukung. Di sisi UI, design tokens untuk warna dan tipografi telah didefinisikan dan `AppTheme.lightTheme` diimplementasikan sehingga konsistensi visual tersedia untuk seluruh komponen yang ada; splash screen dengan animasi fade-in dan navigasi ke `AuthScreen` selesai dibuat; kerangka bottom navigation dengan empat tab (Home, Identify, Collection, Profile) juga disusun menggunakan `IndexedStack` untuk mempertahankan state antar tab; serta layar login/register/guest mode dengan integrasi Supabase signIn/signUp telah ditambahkan. Bukti kegiatan ini tampak dalam riwayat commit proyek: beberapa commit terakhir yang relevan antara lain:

```
4f6a0af 2025-11-11 Sprint1 task7 (#7)
290fb00 2025-11-11 Sprint1 task6 (#6)
c416bde 2025-11-11 feat(sprint1): themed splash, dotenv safety, and theme wiring (#5)
f95aff0 2025-11-11 feat(theme): add design tokens and AppTheme (Task 4) (#4)
5fbd2bb 2025-11-10 feat(backend): add FastAPI skeleton and docs (Task 3) (#3)
306188a 2025-11-10 feat(supabase): integrate supabase client, provider and docs (#2)
4ae0e1c 2025-11-10 chore: setup Riverpod and update sprint1 todo (#1)
```

Commit-commit tersebut merepresentasikan garis besar pekerjaan: mulai dari konfigurasi state management dan integrasi Supabase, pembuatan skeleton backend FastAPI, sampai penambahan design tokens dan wiring tema serta penyempurnaan splash screen dengan pengamanan dotenv. Selain itu, file `docs/sprint1/todo.md` mencatat berbagai item yang sudah ditandai selesai seperti setup Riverpod, integrasi Supabase, tema, dan splash screen, sehingga capaian ini terverifikasi baik pada kode maupun dokumentasi sprint internal.

Halaman yang Sudah Selesai dan Penempatan Placeholder Screenshot
Secara fungsional beberapa halaman/screen sudah disiapkan sebagai bagian dari Sprint 1 dan dapat dianggap selesai pada tingkat skeleton atau implementasi awal. Halaman-halaman tersebut meliputi: splash screen (`lib/screens/splash_screen.dart`) dengan animasi fade-in yang mengarahkan ke layar autentikasi; layar autentikasi utama (`lib/screens/auth/auth_screen.dart`) dan layar login (`lib/screens/auth/login_screen.dart`) dengan field email/password serta opsi register dan guest mode; kerangka bottom navigation (`lib/widgets/bottom_nav.dart`) beserta empat tab placeholder yang diimplementasikan sebagai file terpisah di `lib/screens/tabs/` yaitu `home_tab.dart`, `identify_tab.dart`, `collection_tab.dart`, dan `profile_tab.dart`; serta backend health endpoint (`backend/main.py`) untuk pengecekan layanan. Untuk memudahkan dokumentasi visual, berikut tempat placeholder untuk menaruh screenshot; ganti path dengan file gambar yang sesuai ketika screenshot diambil:

```
![Screenshot Splash Screen](assets/screenshots/splash_placeholder.png)
![Screenshot Auth Screen](assets/screenshots/auth_placeholder.png)
![Screenshot Login Screen](assets/screenshots/login_placeholder.png)
![Screenshot Bottom Navigation - Home](assets/screenshots/home_placeholder.png)
![Screenshot Bottom Navigation - Identify](assets/screenshots/identify_placeholder.png)
![Screenshot Bottom Navigation - Collection](assets/screenshots/collection_placeholder.png)
![Screenshot Bottom Navigation - Profile](assets/screenshots/profile_placeholder.png)
```

Potongan Kode yang Relevan
Untuk memudahkan peninjauan teknis dan sebagai panduan integrasi, berikut dua potongan kode singkat yang merepresentasikan pola implementasi utama: pemasangan `ProviderScope` di `main.dart` dan contoh pemanggilan Supabase sign-in di provider auth.

ProviderScope di `main.dart`:

```
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
   const MyApp({super.key});
   @override
   Widget build(BuildContext context) {
      return MaterialApp(
         title: 'PlantCare.ID',
         theme: AppTheme.lightTheme,
         home: const SplashScreen(),
      );
   }
}
```

Contoh panggilan Supabase sign-in (di `auth_provider.dart` atau di layar login):

```
final supabase = Supabase.instance.client;

Future<void> signIn(String email, String password) async {
   final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
   );
   if (res.session == null) {
      throw Exception('Gagal login: ${res.error?.message ?? 'unknown'}');
   }
}
```

Implementasi dan Alur Kerja di GitHub
Kode sumber proyek di-host di repository GitHub publik tim pada alamat `https://github.com/Nyot-Nyot/plantcare-id`. Semua perubahan dikembangkan di branch terpisah dan diajukan melalui Pull Request (PR) untuk ditinjau sebelum digabungkan ke branch utama. Pola kerja yang digunakan saat ini adalah: membuat branch fitur/issue dari branch `sprint1-task8` atau sesuai nomor tugas, commit lokal secara atomik dengan pesan yang menjelaskan konteks (contoh: `feat(theme): add design tokens and AppTheme (Task 4)`), lalu mendorong branch ke remote, membuat PR dan menunggu review. Commit yang tercantum pada lampiran diambil dari riwayat Git lokal dan mewakili PR yang telah dibuat dan digabungkan ke cabang utama pengembangan. Untuk integrasi berkelanjutan disarankan membuat GitHub Actions workflow minimal `.github/workflows/build.yml` yang menjalankan langkah: checkout, setup Flutter, install dependencies, dan build APK debug; ini memudahkan verifikasi build setelah PR dan sebelum merge.

    Secara praktis, implementasi GitHub memfasilitasi: pelacakan perubahan (commit history), kolaborasi melalui PR + komentar review, dan rencana integrasi CI/CD. Jika tim ingin, saya dapat membuat skeleton workflow GitHub Actions yang hanya membangun debug APK sebagai proof-of-concept minggu depan.

3. Kendala dan Tantangan (Obstacles)
   Selama pelaksanaan ada beberapa kendala baik teknis maupun non-teknis yang mempengaruhi laju penyelesaian tugas. Pertama, integrasi kunci konfigurasi (seperti Supabase project URL dan anon key) memerlukan penanganan aman lewat environment variables, sehingga diperlukan penyesuaian pada mekanisme loading konfigurasi dan dokumentasi untuk lingkungan pengembangan; ini menambah overhead saat verifikasi karena tidak boleh menyimpan kunci sensitif langsung di repo. Kedua, sinkronisasi antara pekerjaan front-end (tema dan navigasi) dan provider autentikasi memerlukan koordinasi sehingga transisi antar layar (mis. splash -> auth -> home) harus diuji ulang untuk berbagai skenario login/guest; ini mengungkap beberapa edge-case alur navigasi yang harus ditangani. Ketiga, ketiadaan aset logo final memaksa penggunaan placeholder `FlutterLogo` pada splash yang menunda integrasi branding visual sampai aset tersedia. Keempat, karena tim relatif kecil dan sebagian tugas awal bersifat infrastruktur, beberapa tugas penerapan fitur UI lain seperti `home_screen.dart` dan `profile_screen.dart` masih tertunda—item-item ini terlihat di `docs/sprint1/todo.md` sebagai belum selesai.

4. Solusi dan Tindakan Korektif (Solutions)
   Untuk menangani kendala terkait konfigurasi sensitif kita menerapkan pola dotenv yang aman dan menambahkan pemeriksaan safety sehingga aplikasi tidak akan gagal secara keras ketika variabel lingkungan belum diset; hal ini juga didokumentasikan di `docs/setup_supabase.md`. Untuk masalah transisi dan edge-case navigasi, tim melakukan sesi testing fungsional singkat di emulator untuk jalur login, registrasi, dan guest mode, serta memperbaiki wiring state sehingga perubahan auth state mendorong navigasi yang konsisten. Untuk branding, keputusan sementara adalah tetap menggunakan placeholder dan menambahkan catatan tugas dalam backlog desain agar aset logo final diunggah ketika tersedia—langkah ini meminimalkan blocking pada integrasi teknis. Untuk backlog pekerjaan UI yang tertunda, tim telah menjadwalkan prioritas kerja pada minggu berikutnya: menyelesaikan `home_screen.dart`, `profile_screen.dart`, serta menambah penanganan error dan unit test dasar untuk auth provider. Selain itu, dokumentasi internal (todo dan sprint planning) diperbarui agar alur kerja lebih transparan bagi semua anggota.

5. Rencana Minggu Depan (Next Steps)
   Fokus utama minggu depan adalah menyelesaikan item yang masih tertunda dalam Sprint 1 dan mempersiapkan kode agar siap digunakan sebagai pijakan Sprint 2. Secara konkret, prioritas adalah: melengkapi tampilan Home Dashboard (`lib/screens/home_screen.dart`) dengan placeholder tiles untuk fitur utama, menyusun dan menambahkan `profile_screen.dart` beserta tombol logout dan tampilan info pengguna berbasis provider yang sudah ada, menambahkan penanganan error yang lebih robust pada metode autentikasi (try-catch dan menampilkan pesan kesalahan terperinci), serta membuat beberapa unit test untuk auth provider (happy path login dan skenario gagal). Selain itu, akan disiapkan checklist untuk CI/CD dasar (pembuatan file workflow GitHub Actions minimal) sehingga build Android dapat diotomasi pada push ke main, walau konfigurasi final signing akan dibuat setelah fase prototyping selesai.

Catatan/Kesimpulan Tambahan
Secara keseluruhan confidence tim terhadap timeline sprint awal cukup tinggi karena infrastruktur inti sudah terpasang dan banyak pekerjaan setup yang bersifat sekali jalan telah diselesaikan. Namun, beberapa kebutuhan masih perlu perhatian: (1) penyediaan asset branding (logo, ikon) untuk menggantikan placeholder, (2) perluasan tes otomatis untuk auth dan navigasi dasar, dan (3) penyusunan workflow CI yang teruji pada runner GitHub Actions untuk Android build. Rekomendasi jangka pendek adalah: alokasikan satu sesi desain singkat dengan designer untuk menyerahkan aset logo, tambahkan dua unit test kecil pada auth provider minggu depan, dan buat skeleton GitHub Actions yang hanya melakukan checkout, setup Flutter, dan build debug APK sebagai proof-of-concept. Untuk referensi implementasi dan bukti pekerjaan teknis, ringkasan commit relevan dimasukkan di bagian kemajuan di atas.

Lampiran (potongan riwayat commit relevan):

```
4f6a0af 2025-11-11 Sprint1 task7 (#7)
290fb00 2025-11-11 Sprint1 task6 (#6)
c416bde 2025-11-11 feat(sprint1): themed splash, dotenv safety, and theme wiring (#5)
f95aff0 2025-11-11 feat(theme): add design tokens and AppTheme (Task 4) (#4)
5fbd2bb 2025-11-10 feat(backend): add FastAPI skeleton and docs (Task 3) (#3)
306188a 2025-11-10 feat(supabase): integrate supabase client, provider and docs (#2)
4ae0e1c 2025-11-10 chore: setup Riverpod and update sprint1 todo (#1)
```

Dokument ini dibuat berdasarkan `docs/sprint-planning.md`, `docs/sprint1/todo.md`, dan riwayat commit lokal repository pada saat pelaporan. Jika diinginkan, saya dapat memperluas lampiran dengan diff file tertentu (mis. `lib/main.dart` atau `lib/theme/app_theme.dart`) atau menambahkan hasil pengujian singkat (screenshot emulator atau log unit test) sebagai bukti verifikasi lebih lanjut.
