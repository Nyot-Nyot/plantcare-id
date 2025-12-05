# Android Release Signing Configuration

## Membuat Keystore untuk Release Build

### 1. Generate Keystore

Jalankan perintah berikut untuk membuat keystore baru:

```bash
keytool -genkey -v -keystore ~/plantcare-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias plantcare-key
```

Anda akan diminta untuk memasukkan:

-   **Keystore password**: Password untuk keystore (simpan dengan aman!)
-   **Key password**: Password untuk key (bisa sama dengan keystore password)
-   **Distinguished Name fields**: Nama, organisasi, kota, dll.

### 2. Buat File key.properties

Buat file `key.properties` di folder `backend/android/`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=plantcare-key
storeFile=/path/to/your/plantcare-release-key.jks
```

**PENTING**:

-   File `key.properties` sudah ada di `.gitignore` dan **TIDAK BOLEH** di-commit ke git!
-   Simpan file ini dengan aman dan backup di tempat yang secure
-   Gunakan `key.properties.example` sebagai template

### 3. Update .gitignore

Pastikan file berikut ada di `.gitignore`:

```
# Android signing keys
backend/android/key.properties
*.jks
*.keystore
```

### 4. Build Release APK/AAB

Setelah konfigurasi selesai, Anda bisa build release:

```bash
# Build APK
flutter build apk --release

# Build App Bundle (untuk Google Play Store)
flutter build appbundle --release
```

## Keamanan Best Practices

1. **Jangan pernah commit keystore atau key.properties ke git**
2. **Backup keystore di tempat yang aman** (kehilangan keystore = tidak bisa update app di Play Store)
3. **Gunakan password yang kuat** untuk keystore dan key
4. **Simpan credentials di password manager**
5. **Untuk CI/CD**, encode keystore ke base64 dan simpan sebagai secret

## Untuk Development

Jika file `key.properties` tidak ada, build akan fallback ke debug signing dengan warning.
Ini aman untuk development, tapi **JANGAN** gunakan untuk production release.

## Troubleshooting

### Error: "Keystore file not found"

-   Periksa path di `storeFile` di `key.properties`
-   Gunakan absolute path atau relative path dari folder `android/`

### Error: "Invalid keystore format"

-   Pastikan menggunakan `.jks` format (bukan `.keystore` lama)
-   Regenerate keystore dengan perintah di atas

### Build masih menggunakan debug signing

-   Periksa apakah file `key.properties` ada di `backend/android/`
-   Periksa format dan isi file `key.properties`
-   Lihat log build untuk warning messages

## References

-   [Flutter Official Guide - Android Deployment](https://docs.flutter.dev/deployment/android)
-   [Android Studio - Sign Your App](https://developer.android.com/studio/publish/app-signing)

## Plugin Versions

Project menggunakan versi stabil:

-   **Android Gradle Plugin (AGP)**: 8.3.2
-   **Kotlin Plugin**: 1.9.23

Versi ini kompatibel dengan Flutter 3.22+ dan telah teruji untuk stabilitas production.
