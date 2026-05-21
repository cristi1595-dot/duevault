# Comenzi pentru Build Production (APK de dimensiune redusă)

Pentru a genera fișiere de instalare cât mai mici ca dimensiune (APK-uri optimizate sau Android App Bundle), folosește una dintre următoarele comenzi în terminalul proiectului:

---

## 1. Split APK per ABI (Recomandat pentru instalare manuală directă)
Această comandă împarte APK-ul în 3 fișiere distincte, fiecare fiind optimizat pentru o anumită arhitectură de procesor (ARM de 64 de biți, ARM de 32 de biți și x86). Fiecare APK rezultat va fi mult mai mic decât un APK universal (care conține resursele pentru toate arhitecturile la un loc).

```bash
flutter build apk --release --split-per-abi
```

### Unde se salvează rezultatele:
După compilare, vei găsi fișierele în:
`build/app/outputs/flutter-apk/`

* **`app-armeabi-v7a-release.apk`** — optimizat pentru telefoane Android mai vechi (32-bit).
* **`app-arm64-v8a-release.apk`** — optimizat pentru telefoanele Android moderne (64-bit). **Acesta este cel mai probabil cel de care ai nevoie.**
* **`app-x86_64-release.apk`** — optimizat pentru tablete sau emulatoare pe arhitectură Intel/AMD.

---

## 2. Android App Bundle (Recomandat pentru publicarea în Google Play Console)
Pentru a publica aplicația în magazinul Google Play, trebuie să generezi un format modern `.aab`. Google Play va folosi acest fișier pentru a genera automat APK-uri personalizate și ultra-comprimare pentru fiecare utilizator în funcție de specificațiile telefonului său.

```bash
flutter build appbundle --release
```

### Unde se salvează rezultatul:
După compilare, fișierul se va găsi în:
`build/app/outputs/bundle/release/app-release.aab`
