# Product Requirements Document (PRD) – PlantCare.ID

**Versi:** 2.0
**Tanggal:** 6 November 2025
**Platform:** Flutter (Android & iOS)

---

## Daftar Isi

-   [Executive Summary](#executive-summary)
-   [Product Vision & Goals](#product-vision--goals)
-   [Target Users & Personas](#target-users--personas)
-   [Problem Statement](#problem-statement)
-   [Functional Requirements (FRs)](#functional-requirements-frs)
-   [Non-Functional Requirements (NFRs)](#non-functional-requirements-nfrs)
-   [Epics & User Stories](#epics--user-stories)
-   [User Flow Overview](#user-flow-overview)
-   [UI/UX Design Summary](#uiux-design-summary)
-   [Risks & Mitigation](#risks--mitigation)
-   [Kesimpulan](#kesimpulan)
-   [Referensi Dokumen Terkait](#referensi-dokumen-terkait)

---

## Executive Summary

**PlantCare.ID** adalah aplikasi _mobile cross-platform_ berbasis Flutter untuk membantu pengguna mendiagnosis dan merawat tanaman melalui gambar.
Tujuan utama: menjembatani _action gap_ — dari mengenali penyakit tanaman menjadi tindakan nyata yang mudah dipahami, cepat dilakukan, dan berbasis panduan visual.

---

## Product Vision & Goals

### Vision

Menjadi **asisten digital tanaman Indonesia** yang mempermudah siapa pun untuk merawat tanaman dengan panduan visual, praktis, dan terukur.

### Goals

1. Konversi hasil diagnosis menjadi **tindakan perawatan konkret**.

2. Menyajikan **informasi teknis** dalam format visual yang mudah dimengerti.

3. Meningkatkan **kemandirian pengguna** dalam merawat tanaman.

### Success Metrics

| Metric                   | Target      |
| ------------------------ | ----------- |
| SUS Score                | ≥ 75        |
| Task Completion Rate     | ≥ 90%       |
| Diagnosis-to-Action Time | ≤ 2 minutes |
| Active Monthly Users     | ≥ 60%       |
| Invalid Image Error Rate | < 10%       |

---

## Target Users & Personas

| Persona                                 | Deskripsi                                    | Tujuan                                | Pain Point                                  |
| --------------------------------------- | -------------------------------------------- | ------------------------------------- | ------------------------------------------- |
| **Sari – Ibu Rumah Tangga Urban (35)**  | Melek smartphone, menyukai berkebun di rumah | Mengetahui cara cepat merawat tanaman | Bingung setelah mengetahui tanaman “sakit”  |
| **Budi – Professional Millennial (28)** | Melek digital, kolektor tanaman hias         | Panduan spesifik dan ringkas          | Informasi daring terlalu kompleks           |
| **Joko – Petani Praktis (42)**          | Pengalaman tinggi, literasi digital rendah   | Diagnosis penyakit tanaman cepat      | Salah memilih obat akibat info teknis rumit |

---

## 4️⃣ Problem Statement

> Banyak pengguna dapat mengenali tanaman bermasalah, tetapi tidak tahu tindakan spesifik untuk memperbaikinya.

Tantangan:

1. Mengubah **diagnosis → aksi** tanpa kebingungan navigasi.

2. Menyajikan **informasi teknis dalam format visual**.

3. Memastikan **aksesibilitas lintas literasi digital**.

---

## 5️⃣ Functional Requirements (FRs)

| ID  | Fitur                              | Deskripsi                                                                   | Prioritas | Catatan                            |
| --- | ---------------------------------- | --------------------------------------------------------------------------- | --------- | ---------------------------------- |
| FR1 | **Identifikasi Tanaman**           | Mengidentifikasi jenis tanaman dari gambar dengan confidence score.         | High      | Basis untuk diagnosis.             |
| FR2 | **Health Assessment**              | Mengevaluasi kondisi kesehatan tanaman dan mendeteksi penyakit dari gambar. | High      | Plant.id API with health parameter |
| FR3 | **Panduan Perawatan Step-by-Step** | Menyediakan panduan visual ≤5 langkah setelah diagnosis.                    | Core      | Differentiator utama.              |
| FR4 | **Koleksi Tanaman Pribadi**        | Menyimpan riwayat identifikasi & perawatan.                                 | Medium    | Membentuk habit user.              |
| FR5 | **Autentikasi Sederhana**          | Login/Registrasi cepat + guest mode.                                        | High      | Minim friksi.                      |
| FR6 | **Notifikasi Perawatan**           | Reminder otomatis berdasarkan jenis tanaman.                                | Medium    | Meningkatkan engagement.           |
| FR7 | **Offline Mode**                   | Menyimpan data & panduan lokal saat offline.                                | Medium    | Penting untuk petani.              |

---

## Non-Functional Requirements (NFRs)

| ID   | Kategori                      | Spesifikasi                                                 | Rationale                    |
| ---- | ----------------------------- | ----------------------------------------------------------- | ---------------------------- |
| NFR1 | **Usability & Accessibility** | SUS ≥75, navigasi ≤3 level, learnability ≤5 menit           | Memastikan akses universal   |
| NFR2 | **Performance**               | Waktu respon ≤8 detik termasuk upload & analisis            | Menjaga UX responsif         |
| NFR3 | **Cognitive Load**            | ≤7±2 elemen per layar, _progressive disclosure_             | Mencegah kelebihan informasi |
| NFR4 | **Error Tolerance**           | Pesan kesalahan jelas + opsi retry                          | Menghindari frustrasi        |
| NFR5 | **Compatibility**             | Flutter SDK stable, Android ≥10, iOS ≥14                    | Stabil lintas platform       |
| NFR6 | **Security & Privacy**        | Enkripsi data lokal, tidak menyimpan gambar user tanpa izin | Keamanan pengguna            |
| NFR7 | **Localization**              | Bahasa Indonesia default, opsi multi-bahasa                 | Skalabilitas regional        |

---

## 7️⃣ Epics & User Stories

Epics mengelompokkan fitur besar (FRs) menjadi area pengembangan, kemudian dijabarkan dalam user stories untuk implementasi Agile (Scrum/Kanban).

---

### Epic 1: Plant Identification (FR1)

> Pengguna dapat mengidentifikasi tanaman dari gambar dengan hasil yang jelas dan akurat.

**User Stories:**

1. Sebagai **pengguna**, saya ingin **mengambil foto tanaman** melalui kamera aplikasi agar saya bisa mengidentifikasi jenis tanaman.

2. Sebagai **pengguna**, saya ingin **memilih foto dari galeri** agar saya bisa menggunakan foto yang sudah ada.

3. Sebagai **pengguna**, saya ingin **melihat hasil identifikasi dengan confidence score** agar saya tahu tingkat akurasi hasilnya.

4. Sebagai **pengguna**, saya ingin **melihat nama lokal & latin tanaman** agar saya mengenali tanaman tersebut dengan benar.

---

### Epic 2: Health Assessment (FR2)

> Pengguna dapat mendiagnosis kondisi kesehatan tanaman berdasarkan foto bagian yang sakit.

**User Stories:**

1. Sebagai **pengguna**, saya ingin **mengambil foto bagian tanaman yang rusak** agar sistem bisa menganalisis kondisi kesehatannya.

2. Sebagai **pengguna**, saya ingin **melihat deskripsi penyakit dalam bahasa sederhana** agar mudah dipahami.

3. Sebagai **pengguna**, saya ingin **melihat penyebab umum & tingkat keparahan penyakit** agar saya tahu tindakan yang tepat.

4. Sebagai **pengguna**, saya ingin **melihat status kesehatan tanaman (sehat/tidak sehat)** dengan probabilitas yang jelas.

**Technical Notes:**

-   Menggunakan Plant.id API dengan parameter `health: "all"` atau `health: "auto"`
-   Response mencakup `is_healthy` (binary + probability) dan `disease suggestions`
-   Health assessment memerlukan 2 credits (atau 1-2 dengan mode "auto")

---

### Epic 3: Treatment Guidance (FR3)

> Pengguna mendapat panduan tindakan perawatan langsung setelah diagnosis.

**User Stories:**

1. Sebagai **pengguna**, saya ingin **melihat langkah-langkah perawatan visual** agar mudah diikuti.

2. Sebagai **pengguna**, saya ingin **mengetahui bahan yang dibutuhkan untuk tiap langkah** agar bisa menyiapkan alat & bahan.

3. Sebagai **pengguna**, saya ingin **melihat progress bar langkah-langkah** agar tahu sejauh mana proses perawatan.

4. Sebagai **pengguna**, saya ingin **menandai langkah sebagai selesai** agar saya merasa ada progres nyata.

---

### Epic 4: Personal Plant Collection (FR4, FR6, FR7)

> Pengguna dapat menyimpan dan mengelola koleksi tanaman serta menerima pengingat.

**User Stories:**

1. Sebagai **pengguna terdaftar**, saya ingin **menyimpan hasil identifikasi ke koleksi pribadi** agar saya bisa melacak riwayatnya.

2. Sebagai **pengguna**, saya ingin **melihat daftar tanaman saya dalam grid dengan foto dan status** agar mudah dikelola.

3. Sebagai **pengguna**, saya ingin **mendapatkan notifikasi pengingat perawatan** agar tidak lupa merawat tanaman.

4. Sebagai **pengguna**, saya ingin **mengakses panduan meski sedang offline** agar tetap bisa merawat tanaman tanpa internet.

---

### Epic 5: Authentication & Access (FR5)

> Pengguna dapat mengakses aplikasi dengan cepat tanpa hambatan login kompleks.

**User Stories:**

1. Sebagai **pengguna baru**, saya ingin **mendaftar hanya dengan email dan password sederhana** agar prosesnya cepat.

2. Sebagai **pengguna**, saya ingin **masuk sebagai tamu (guest)** agar bisa mencoba tanpa mendaftar.

3. Sebagai **pengguna terdaftar**, saya ingin **logout dengan aman** agar data saya terlindungi.

---

## User Flow Overview

1. **Start App → Splash Screen → Login / Guest Mode**

2. **Choose Feature → Identify Plant / Detect Disease**

3. **Take / Upload Photo → Process via API → Display Result**

4. **Show Care Guide (Step-by-Step)**

5. **(Optional)** Save result → Add to collection → Receive care reminders

Focus: minimize the number of taps between **diagnosis → treatment** (goal ≤6 actions total).

---

## UI/UX Design Summary

| Aspek               | Prinsip                                                       |
| ------------------- | ------------------------------------------------------------- |
| **Desain Visual**   | Flat minimalistic, warna hijau natural (#27AE60)              |
| **Navigasi**        | Bottom Nav 5 ikon: Home, Identify, Collection, Guide, Profile |
| **Interaksi**       | CTA besar, gesture-friendly untuk ibu rumah tangga & petani   |
| **Feedback Sistem** | Animasi tanaman tumbuh saat loading                           |
| **Aksesibilitas**   | Font scalable, kontras ≥4.5:1, icon intuitif                  |

---

## Risks & Mitigation

| Risiko                            | Dampak             | Mitigasi                              |
| --------------------------------- | ------------------ | ------------------------------------- |
| Ketergantungan pada API eksternal | Identifikasi gagal | Sediakan fallback API & cache         |
| Kualitas foto buruk               | Diagnosis salah    | Tambahkan panduan pengambilan foto    |
| Koneksi buruk                     | Delay / error      | Offline-first architecture            |
| User churn karena kompleksitas    | Penggunaan menurun | UX testing + iterasi cepat            |
| Error input gambar                | Frustrasi pengguna | Error message edukatif & retry option |

---

# Kesimpulan

**PlantCare.ID** adalah aplikasi asisten tanaman visual yang menggabungkan teknologi identifikasi AI, panduan tindakan langkah demi langkah, dan desain berpusat pada pengguna.
Dokumen ini mencakup **FRs, NFRs, Epics, dan User Stories** untuk mendukung pengembangan berbasis _Agile_ di Flutter, menjadikannya siap untuk tahap **MVP implementation & usability testing.**

---

## Referensi Dokumen Terkait

-   [Product Brief](product-brief.md) - Ringkasan produk dan visi.
-   [Arsitektur Sistem](architect.md) - Detail arsitektur teknis dan keputusan teknologi.
-   [Spesifikasi Front-End](ux-spec.md) - Panduan UI/UX dan kontrak API dari perspektif front-end.
-   [Epics](epics.md) - Rancangan epics berdasarkan docs.
-   [Sprint Planning](sprint-planning.md) - Rencana sprint untuk development.
