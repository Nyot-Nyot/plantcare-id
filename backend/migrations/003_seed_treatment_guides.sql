-- Sprint 3: Seed Data for Treatment Guides
-- Inserts sample treatment guides for common plant issues

-- Guide 1: Leaf Spot Treatment
INSERT INTO treatment_guides (plant_id, disease_name, severity, guide_type, steps, materials, estimated_duration_minutes, estimated_duration_text)
VALUES (
    'general',
    'Leaf Spot',
    'medium',
    'disease_treatment',
    '[
        {
            "step_number": 1,
            "title": "Isolasi Tanaman",
            "description": "Pisahkan tanaman yang sakit dari tanaman lain untuk mencegah penyebaran penyakit. Letakkan di area terpisah dengan sirkulasi udara yang baik.",
            "image_url": "https://placehold.co/600x400/27AE60/white?text=Isolasi+Tanaman",
            "materials": ["sarung tangan", "pot terpisah"],
            "is_critical": true,
            "estimated_time": "5 menit"
        },
        {
            "step_number": 2,
            "title": "Buang Daun yang Terinfeksi",
            "description": "Gunakan gunting bersih dan steril untuk memotong semua daun yang menunjukkan tanda-tanda bercak. Potong sedikit di atas area yang terinfeksi.",
            "image_url": "https://placehold.co/600x400/27AE60/white?text=Buang+Daun",
            "materials": ["gunting steril", "alkohol 70%", "kantong plastik"],
            "is_critical": true,
            "estimated_time": "10 menit"
        },
        {
            "step_number": 3,
            "title": "Aplikasi Fungisida",
            "description": "Semprotkan fungisida organik atau kimia sesuai petunjuk pada label. Pastikan merata ke seluruh permukaan daun, batang, dan tanah.",
            "image_url": "https://placehold.co/600x400/27AE60/white?text=Fungisida",
            "materials": ["fungisida", "sprayer", "masker"],
            "is_critical": true,
            "estimated_time": "15 menit"
        },
        {
            "step_number": 4,
            "title": "Perbaiki Kondisi Lingkungan",
            "description": "Kurangi kelembaban dengan meningkatkan sirkulasi udara. Hindari menyiram dari atas, siram langsung ke media tanam.",
            "image_url": "https://placehold.co/600x400/27AE60/white?text=Sirkulasi+Udara",
            "materials": ["kipas kecil (opsional)"],
            "is_critical": false,
            "estimated_time": "5 menit"
        },
        {
            "step_number": 5,
            "title": "Monitor dan Ulangi",
            "description": "Periksa tanaman setiap 3 hari. Ulangi aplikasi fungisida setelah 7-10 hari jika diperlukan. Lanjutkan hingga tidak ada lagi bercak baru.",
            "image_url": "https://placehold.co/600x400/27AE60/white?text=Monitor",
            "materials": ["kalender", "catatan"],
            "is_critical": false,
            "estimated_time": "5 menit per check"
        }
    ]'::jsonb,
    '["sarung tangan", "gunting steril", "alkohol 70%", "kantong plastik", "fungisida", "sprayer", "masker"]'::jsonb,
    20160,
    '2-3 minggu'
);

-- Guide 2: Root Rot Treatment
INSERT INTO treatment_guides (plant_id, disease_name, severity, guide_type, steps, materials, estimated_duration_minutes, estimated_duration_text)
VALUES (
    'general',
    'Root Rot',
    'high',
    'disease_treatment',
    '[
        {
            "step_number": 1,
            "title": "Keluarkan dari Pot",
            "description": "Hati-hati keluarkan tanaman dari pot. Bersihkan sebanyak mungkin media tanam lama dari akar. Periksa kondisi akar dengan teliti.",
            "image_url": "https://placehold.co/600x400/E74C3C/white?text=Keluarkan+Tanaman",
            "materials": ["sarung tangan", "koran bekas"],
            "is_critical": true,
            "estimated_time": "10 menit"
        },
        {
            "step_number": 2,
            "title": "Potong Akar Busuk",
            "description": "Gunakan gunting steril untuk memotong semua akar yang berwarna coklat, hitam, atau lembek. Sisakan hanya akar yang sehat (putih atau krem dan keras).",
            "image_url": "https://placehold.co/600x400/E74C3C/white?text=Potong+Akar",
            "materials": ["gunting steril", "alkohol 70%"],
            "is_critical": true,
            "estimated_time": "15 menit"
        },
        {
            "step_number": 3,
            "title": "Rendam dalam Fungisida",
            "description": "Rendam akar yang tersisa dalam larutan fungisida selama 15-30 menit. Ini akan membunuh spora jamur yang tersisa.",
            "image_url": "https://placehold.co/600x400/E74C3C/white?text=Rendam+Fungisida",
            "materials": ["fungisida sistemik", "wadah", "air"],
            "is_critical": true,
            "estimated_time": "30 menit"
        },
        {
            "step_number": 4,
            "title": "Tanam Ulang",
            "description": "Gunakan media tanam baru yang steril dan pot bersih. Pastikan pot memiliki lubang drainase yang baik. Jangan padatkan media terlalu keras.",
            "image_url": "https://placehold.co/600x400/E74C3C/white?text=Tanam+Ulang",
            "materials": ["pot baru", "media tanam steril", "kerikil drainase"],
            "is_critical": true,
            "estimated_time": "20 menit"
        }
    ]'::jsonb,
    '["sarung tangan", "gunting steril", "alkohol 70%", "fungisida sistemik", "wadah", "pot baru", "media tanam steril", "kerikil drainase"]'::jsonb,
    64800,
    '1-2 bulan recovery'
);

-- Guide 3: Pest Control - Aphids
INSERT INTO treatment_guides (plant_id, disease_name, severity, guide_type, steps, materials, estimated_duration_minutes, estimated_duration_text)
VALUES (
    'general',
    'Aphid Infestation',
    'medium',
    'disease_treatment',
    '[
        {
            "step_number": 1,
            "title": "Bilas dengan Air",
            "description": "Semprotkan air kuat ke seluruh bagian tanaman, terutama di bawah daun. Ini akan menghilangkan sebagian besar kutu daun.",
            "image_url": "https://placehold.co/600x400/F2C94C/white?text=Bilas+Air",
            "materials": ["selang air", "sprayer"],
            "is_critical": true,
            "estimated_time": "10 menit"
        },
        {
            "step_number": 2,
            "title": "Aplikasi Sabun Insektisida",
            "description": "Campurkan sabun insektisida atau sabun cuci piring (1 sendok per liter air). Semprotkan ke seluruh bagian tanaman hingga menetes.",
            "image_url": "https://placehold.co/600x400/F2C94C/white?text=Sabun+Insektisida",
            "materials": ["sabun insektisida", "sprayer", "air"],
            "is_critical": true,
            "estimated_time": "15 menit"
        },
        {
            "step_number": 3,
            "title": "Ulangi Perlakuan",
            "description": "Ulangi penyemprotan setiap 3-5 hari selama 2-3 minggu. Periksa setiap hari untuk infestasi baru, terutama di tunas muda.",
            "image_url": "https://placehold.co/600x400/F2C94C/white?text=Monitor",
            "materials": ["kalender"],
            "is_critical": false,
            "estimated_time": "10 menit per aplikasi"
        }
    ]'::jsonb,
    '["selang air", "sprayer", "sabun insektisida atau sabun cuci piring"]'::jsonb,
    20160,
    '2-3 minggu'
);

-- Guide 4: General Plant Care - Monstera
INSERT INTO treatment_guides (plant_id, disease_name, severity, guide_type, steps, materials, estimated_duration_minutes, estimated_duration_text)
VALUES (
    'monstera_deliciosa',
    NULL,
    'low',
    'identification',
    '[
        {
            "step_number": 1,
            "title": "Penyiraman Rutin",
            "description": "Siram ketika 2-3 cm lapisan atas media tanam sudah kering. Biasanya 1-2 kali per minggu tergantung kondisi ruangan.",
            "image_url": "https://placehold.co/600x400/27AE60/white?text=Penyiraman",
            "materials": ["kaleng penyiram"],
            "is_critical": true,
            "estimated_time": "5 menit"
        },
        {
            "step_number": 2,
            "title": "Cahaya Tidak Langsung",
            "description": "Letakkan di lokasi dengan cahaya terang tidak langsung. Hindari sinar matahari langsung yang dapat membakar daun.",
            "image_url": "https://placehold.co/600x400/27AE60/white?text=Cahaya",
            "materials": [],
            "is_critical": true,
            "estimated_time": "5 menit setup"
        },
        {
            "step_number": 3,
            "title": "Pupuk Bulanan",
            "description": "Berikan pupuk cair balanced (NPK 20-20-20) setiap 2-4 minggu selama musim tumbuh (spring-summer). Kurangi di musim dingin.",
            "image_url": "https://placehold.co/600x400/27AE60/white?text=Pupuk",
            "materials": ["pupuk NPK cair"],
            "is_critical": false,
            "estimated_time": "5 menit"
        }
    ]'::jsonb,
    '["kaleng penyiram", "pupuk NPK cair"]'::jsonb,
    NULL,
    'ongoing care'
);

-- Guide 5: Yellowing Leaves Treatment
INSERT INTO treatment_guides (plant_id, disease_name, severity, guide_type, steps, materials, estimated_duration_minutes, estimated_duration_text)
VALUES (
    'general',
    'Yellowing Leaves',
    'low',
    'disease_treatment',
    '[
        {
            "step_number": 1,
            "title": "Identifikasi Penyebab",
            "description": "Periksa pola menguning: seluruh daun (overwatering), daun bawah (wajar), daun atas (nutrisi). Cek kelembaban media tanam.",
            "image_url": "https://placehold.co/600x400/F2C94C/white?text=Check+Pattern",
            "materials": ["soil moisture meter (opsional)"],
            "is_critical": true,
            "estimated_time": "5 menit"
        },
        {
            "step_number": 2,
            "title": "Sesuaikan Penyiraman",
            "description": "Jika overwatering: kurangi frekuensi dan pastikan drainase baik. Jika underwatering: tingkatkan frekuensi penyiraman secara bertahap.",
            "image_url": "https://placehold.co/600x400/F2C94C/white?text=Adjust+Water",
            "materials": [],
            "is_critical": true,
            "estimated_time": "2 menit"
        },
        {
            "step_number": 3,
            "title": "Tambah Nutrisi",
            "description": "Jika defisiensi nutrisi, aplikasikan pupuk cair sesuai dosis. Untuk nitrogen (N) gunakan pupuk tinggi N. Untuk magnesium, gunakan garam Epsom.",
            "image_url": "https://placehold.co/600x400/F2C94C/white?text=Fertilize",
            "materials": ["pupuk cair", "garam epsom (jika perlu)"],
            "is_critical": false,
            "estimated_time": "10 menit"
        },
        {
            "step_number": 4,
            "title": "Buang Daun Mati",
            "description": "Potong daun yang sudah kuning sempurna dengan gunting steril. Ini membantu tanaman fokus energi ke daun sehat.",
            "image_url": "https://placehold.co/600x400/F2C94C/white?text=Prune",
            "materials": ["gunting steril"],
            "is_critical": false,
            "estimated_time": "5 menit"
        }
    ]'::jsonb,
    '["gunting steril", "pupuk cair", "garam epsom (opsional)", "soil moisture meter (opsional)"]'::jsonb,
    10080,
    '1-2 minggu'
);

-- Verify insertion
SELECT
    id,
    plant_id,
    disease_name,
    severity,
    guide_type,
    jsonb_array_length(steps) as step_count,
    estimated_duration_minutes,
    estimated_duration_text
FROM treatment_guides
ORDER BY created_at DESC;
