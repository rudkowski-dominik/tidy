# Tidy — Minimalist macOS System Cleaner

<p align="center">
  <strong>Prosta, szybka i uczciwa alternatywa dla płatnych programów czyszczących na macOS.</strong><br>
  Zbudowana w 100% w natywnym <strong>Swift 6</strong> i <strong>SwiftUI</strong>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014%2B-blue.svg" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License MIT">
  <img src="https://img.shields.io/badge/Full%20Disk%20Access-Ready-brightgreen.svg" alt="FDA Ready">
</p>

---

## 🌟 Filozofia Tidy

- **Zero ściemy:** Żadnych "optymalizatorów RAM", fałszywych alarmów ani straszenia użytkownika.
- **Zero procesów w tle:** Aplikacja działa tylko wtedy, gdy jest otwarta. Po zamknięciu nie obciąża systemu żadnymi daemonami ani agentami.
- **Zero subskrypcji i telemetrii:** Bez logowania, bez zbierania danych, bez reklam.
- **Bezpieczeństwo przede wszystkim:** Domyślnie wszystkie operacje przenoszą pliki do systemowego Kosza (`FileManager.trashItem`), a nie kasują ich trwale.

---

## 🚀 Główne funkcje

1. **Pulpit i przegląd dysku:**
   - Animowany pierścień zajętości dysku, stan wolnego i zajętego miejsca.
   - Szybkie skanowanie wszystkich modułów za jednym kliknięciem (`⌘R`).

2. **Śmieci systemowe i aplikacji:**
   - Pamięć podręczna użytkownika (`~/Library/Caches`).
   - Dzienniki i crash reporty (`~/Library/Logs`, `DiagnosticReports`).
   - Pliki tymczasowe (`/tmp`, `$TMPDIR`).
   - Stare instalatory w Pobranych (`.dmg`, `.pkg`, `.iso`).
   - Pozostałości po Xcode (`DerivedData`, `Archives`, `iOS DeviceSupport`).
   - Pamięć podręczna przeglądarek: Safari, Chrome, Firefox, Arc.
   - Kosz systemowy (`~/.Trash`) z podglądem i możliwością opróżnienia.
   - Przycisk **„Zaznacz wszystkie / Odznacz wszystkie”** (`⌘A`).

3. **Wyszukiwarka duplikatów:**
   - Wieloetapowy, bezpieczny algorytm: grupowanie po rozmiarze → częściowy hash (pierwsze i ostatnie 8 KB) → pełny hash SHA-256 z CryptoKit.
   - Automatyczna rekomendacja zachowania oryginału (według starszej daty lub lokalizacji w Dokumentach).
   - Pomijanie pakietów systemowych, bibliotek Photos i dowiązań symbolicznych.

4. **Duże i nieużywane pliki:**
   - Regulowany suwak progu rozmiaru (np. > 100 MB).
   - Filtrowanie po typie: Wideo, Archiwa, Dokumenty, Audio, Inne.
   - Wykrywanie programów nieotwieranych od 1, 3, 6 miesięcy lub roku.

5. **Aplikacje i pozostałości:**
   - Kompletny deinstalator programów wraz z powiązanymi plikami z `~/Library` (Application Support, Caches, Preferences, Containers, LaunchAgents).
   - **Wykrywacz pozostałości:** Wyszukuje porzucone foldery w Bibliotece po programach, które zostały usunięte ręcznie w przeszłości.

6. **Interaktywna mapa dysku (Treemap):**
   - Wizualizacja struktury katalogów w stylu DaisyDisk (algorytm squarified treemap).
   - Klikalny drill-down, okruszki nawigacyjne (breadcrumbs) oraz menu kontekstowe z przenoszeniem do Kosza i podglądem w Finderze.

7. **Dziennik operacji (Audit Log) i Tryb próbny:**
   - Lokalny rejestr operacji zapisywany w formacie JSON (`audit_log.json`).
   - **Tryb próbny (Dry Run):** Pozwala przetestować działanie i sprawdzić, ile miejsca zostałoby zwolnione, bez usuwania żadnych plików.

---

## 🛡️ Twarde reguły bezpieczeństwa (Protected Paths)

Tidy posiada niezmienną listę ścieżek, których **nigdy nie modyfikuje**:
- `/System`, `/usr`, `/bin`, `/sbin`, `/etc`, `/private/var/db`, `/Library`
- `~/Library/Mobile Documents` (iCloud Drive — ochrona przed skasowaniem danych w chmurze)
- `~/Library/Keychains`, `~/Library/Messages`, `~/Library/Mail`
- Wszystkie pakiety biblioteki zdjęć (`*.photoslibrary`)
- Główne foldery użytkownika (`~`, Desktop, Documents, Downloads — nie można usunąć samego folderu)

---

## 🛠️ Budowanie ze źródeł

### Wymagania:
- macOS 14.0 Sonoma lub nowszy
- Xcode 15.0+ z obsługą Swift 6

### Szybka kompilacja:
```bash
git clone https://github.com/rudkowski-dominik/tidy.git
cd tidy
./build_app.sh
```
Aplikacja zostanie skompilowana i umieszczona w katalogu `dist/Tidy.app`.

### Uruchomienie testów jednostkowych:
```bash
swift test
```

---

## 📄 Licencja

Projekt udostępniany na warunkach licencji [MIT](LICENSE).
