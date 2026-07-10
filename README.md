# MiniMe

Aplicatie personala de organizare (Flutter) - Faza 1: schelet proiect + model de date.

## Ce contine faza asta

- Model de date complet: `Category` (categorii + subcategorii), `PriorityTag`
  (this week/month/year, next month, custom), `NoteTask` (notite + to-do, cu
  durata, reminder, recurenta, tag Google Calendar), `BillItem` (bill/income/
  wanted), `HistoryEntry` (istoric actiuni).
- Baza de date locala SQLite (`lib/db/database_helper.dart`) cu toate
  tabelele si seed pentru categoriile principale (Home/Work/Personal) si
  tag-urile de prioritate implicite.
- Schelet de aplicatie (`lib/main.dart`) cu 4 tab-uri (Dashboard, Notes,
  Bills, Today) - continutul real vine in fazele urmatoare.
- Workflow GitHub Actions (`.github/workflows/build-apk.yml`) care compileaza
  automat un APK in cloud, fara sa ai nevoie de Flutter instalat pe calculator.

## Cum obtii APK-ul (fara sa instalezi nimic pe calculator)

1. Creeaza un cont gratuit pe github.com (daca nu ai deja).
2. Creeaza un repository nou, public, numit de exemplu `minime`.
3. Pe pagina repo-ului, foloseste "Add file -> Upload files" si trage tot
   continutul acestui folder (`minime/`) acolo. Apasa "Commit changes".
4. Mergi la tab-ul "Actions" al repo-ului - workflow-ul "Build MiniMe APK"
   porneste automat si dureaza cateva minute.
5. Cand se termina (bulina verde), mergi la tab-ul "Releases" (din pagina
   principala a repo-ului, coloana din dreapta) si descarca `app-release.apk`
   direct pe telefon (sau descarca pe calculator si transfera pe telefon).

## Cum instalezi APK-ul pe Oppo Reno 5 Lite (Android 12 / ColorOS)

1. Deschide fisierul `.apk` descarcat -> Android o sa ceara permisiunea
   "Install unknown apps" pentru aplicatia din care il deschizi (Files/
   Chrome) - accepta.
2. Dupa instalare, foarte important pentru ca notificarile sa fie fiabile:
   - Settings -> Battery -> App Battery Management -> MiniMe -> seteaza pe
     "Allow" / "No restrictions" (nu "Optimized" sau "Restricted").
   - Settings -> App Management -> App startup manager -> MiniMe -> comuta
     manual pe "Allow" (dezactiveaza auto-management).
   ColorOS omoara agresiv aplicatiile din fundal by default - fara pasii de
   mai sus, notificarile programate pot sa nu mai apara.

## Alternativa: compilezi local pe calculatorul tau

Daca preferi sa instalezi Flutter tu insuti (Windows/Mac/Linux) in loc sa
folosesti GitHub Actions, spune-mi si iti dau pasii exacti de instalare +
comenzile de rulat (`flutter create`, `flutter pub get`, `flutter build apk`).
Nu pot rula eu aceste comenzi direct pe calculatorul tau (nu am acces de
control la el), dar pot sa te ghidez pas cu pas.

## Urmatoarele faze

2. Dashboard + Notite/To-Do pe Home/Work/Personal + subcategorii
3. Bills/Income/Wanted tracker
4. Motor de prioritizare zilnica (calcul automat dupa durata)
5. Notificari (sunet + voce TTS, Snooze/Not Today/Move Tomorrow/Done) + istoric
6. Integrare Google Calendar
7. Polish (widget-uri, culori, iconite, teme)
8. Build final + instalare
