---
title: "Product Brief — PlantCare.ID"
date: "2025-11-06"
context: "Greenfield - Mobile (Flutter)"
---

# Product Brief: PlantCare.ID

**Tanggal:** 2025-11-06
**Konteks:** Greenfield – Aplikasi Mobile (Flutter)

---

## Daftar Isi

-   [Executive Summary](#executive-summary)
-   [Core Vision](#core-vision)
-   [Target Users](#target-users)
-   [Success Metrics](#success-metrics)
-   [MVP Scope](#mvp-scope)
-   [Market & Context (ringkas)](#market--context-ringkas)
-   [Technical Preferences](#technical-preferences)
-   [Risks & Assumptions](#risks--assumptions)
-   [Timeline (tingkat awal)](#timeline-tingkat-awal)
-   [Supporting Materials](#supporting-materials)

---

## Executive Summary

PlantCare.ID adalah aplikasi mobile cross-platform berbasis Flutter yang membantu pengguna mendiagnosis dan merawat tanaman menggunakan foto. Aplikasi ini mengubah hasil diagnosis menjadi panduan perawatan praktis dan visual sehingga pengguna—from penghobi hingga petani—bisa mengambil tindakan nyata dengan cepat.

---

## Core Vision

### Problem Statement

Banyak pengguna dapat mengenali tanaman bermasalah namun tidak tahu tindakan spesifik untuk memperbaikinya — menghasilkan kebingungan dan hasil perawatan yang tidak konsisten.

### Proposed Solution

Menyediakan alur cepat: ambil foto → identifikasi tanaman & penyakit → terima panduan perawatan step-by-step (≤5 langkah) dengan bahan dan tindakan yang jelas. Fokus pada konversi diagnosis → aksi, dengan fallback offline dan dukungan API identifikasi (Plant.id primary, PlantNet fallback).

### Key Differentiators

-   Panduan treatment visual dan terstruktur (langkah ≤5) yang langsung bisa dipraktekkan.
-   Offline-first support untuk akses panduan tanpa koneksi.
-   Pendekatan multi-API untuk identifikasi guna meningkatkan ketersediaan dan akurasi.

---

## Target Users

### Primary Users

-   Ibu rumah tangga urban yang ingin merawat tanaman di rumah (contoh: Sari, 35) — pengguna yang menginginkan panduan yang simpel dan visual.
-   Kolektor tanaman muda yang menginginkan hasil identifikasi cepat dan tindakan praktis (contoh: Budi, 28).

### Secondary Users

-   Petani skala kecil yang butuh panduan yang dapat diakses offline dan bersifat praktis (contoh: Joko, 42).

---

## Success Metrics

-   SUS Score ≥ 75
-   Task Completion Rate ≥ 90% (dari diagnosis → menandai langkah selesai)
-   Diagnosis-to-Action Time ≤ 2 menit
-   Active Monthly Users ≥ 60% (dari pengguna terdaftar)

---

## MVP Scope

### Core Features (MVP)

1. Identifikasi Tanaman (upload / camera) dengan confidence score (FR1)
2. Deteksi Penyakit dari foto (FR2)
3. Panduan Perawatan Step-by-Step ≤5 langkah, bahan & gambar (FR3)
4. Koleksi Tanaman pribadi & history (FR4)
5. Autentikasi sederhana + Guest mode (FR5)

### Out of Scope for MVP

-   Fitur enterprise/tenant management dan compliance tingkat lanjut
-   Integrasi deep analytics dan monetisasi lanjutan

---

## Market & Context (ringkas)

Fokus awal adalah pasar Indonesia — pengguna mobile yang mencari solusi cepat dan ramah untuk masalah tanaman rumah. Kompetitor umum menyediakan identifikasi atau komunitas, namun seringkali gagal menutup gap antara diagnosis dan tindakan praktis; PlantCare.ID menonjol karena panduan tindakan terstruktur dan dukungan offline.

---

## Technical Preferences

-   Client: Flutter (single codebase Android/iOS)
-   Backend rekomendasi: FastAPI (Python) untuk orchestration + PostgreSQL + S3-compatible storage
-   AI integration: Plant.id primary, PlantNet fallback; caching identifikasi untuk hemat biaya

---

## Risks & Assumptions

-   Ketergantungan pada layanan identifikasi pihak ketiga → mitigasi: caching, fallback multi-API
-   Kualitas foto buruk → mitigasi: image-quality validator & tips pada camera view
-   Keterbatasan konektivitas pengguna pedesaan → mitigasi: offline-first guide cache

---

## Timeline (tingkat awal)

-   Sprint 0 (2 minggu): scaffolding Flutter app, camera flow, basic UI
-   MVP (8–12 minggu): identifikasi basic, guide flow, collection, simple auth

---

## Supporting Materials

-   [PRD](prd.md)
-   [UX Spec](ux-spec.md)
-   [Architecture](architect.md)

---

## Referensi Dokumen Terkait

-   [Product Requirements Document (PRD)](prd.md) - Detail persyaratan produk.
-   [Arsitektur Sistem](architect.md) - Arsitektur teknis.
-   [Spesifikasi Front-End](ux-spec.md) - Spesifikasi UI/UX.
-   [Epics](epics.md) - Rancangan epics berdasarkan docs.
-   [Sprint Planning](sprint-planning.md) - Rencana sprint untuk development.
