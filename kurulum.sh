#!/usr/bin/env bash
# Eğitim Takip - tek seferlik kurulum betiği (macOS / Linux / Windows Git Bash)
# Önce README.md içindeki 1-3. adımları yapın (Flutter, Firebase CLI, Firebase projesi).
set -e

echo ">> Android proje dosyaları oluşturuluyor (mevcut lib/ dosyalarına dokunulmaz)..."
flutter create --platforms=android --org com.egitimtakip --project-name egitim_takip .

echo ">> Paketler güncel sürümlere yükseltiliyor..."
flutter pub upgrade --major-versions

echo ">> minSdk 23 ayarlanıyor (Firebase gereksinimi)..."
GRADLE_KTS="android/app/build.gradle.kts"
GRADLE_GROOVY="android/app/build.gradle"
if [ -f "$GRADLE_KTS" ]; then
  sed -i.bak -E 's/minSdk = flutter\.minSdkVersion/minSdk = 23/' "$GRADLE_KTS" && rm -f "$GRADLE_KTS.bak"
elif [ -f "$GRADLE_GROOVY" ]; then
  sed -i.bak -E 's/minSdkVersion flutter\.minSdkVersion/minSdkVersion 23/; s/minSdk = flutter\.minSdkVersion/minSdk = 23/' "$GRADLE_GROOVY" && rm -f "$GRADLE_GROOVY.bak"
fi

echo ">> Uygulama adı 'Eğitim Takip' yapılıyor..."
MANIFEST="android/app/src/main/AndroidManifest.xml"
sed -i.bak -E 's/android:label="[^"]*"/android:label="Eğitim Takip"/' "$MANIFEST" && rm -f "$MANIFEST.bak"

echo ">> Firebase bağlantısı yapılıyor (Firebase projenizi seçin, platform olarak sadece android)..."
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android

echo ">> Firestore güvenlik kuralları yükleniyor..."
read -r -p "Firebase proje kimliğinizi yazın (ör. egitim-takip-1234): " PROJECT_ID
firebase deploy --only firestore:rules --project "$PROJECT_ID"

echo ""
echo "Kurulum tamam. Telefonu USB ile bağlayıp:  flutter run"
echo "Paylaşılabilir APK için:                   flutter build apk --release"
