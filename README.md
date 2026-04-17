Init script: create_all_script.sql

# AB2 Beadandó – Oracle PL/SQL Projekt Menedzsment Adatbázis

> **Adatbázisok 2. beadandó munka**  
> Készítette: **Trunk Péter** (JD2DT3)

---

## Projektleírás

Ez a projekt egy **projekt menedzsment alkalmazás** Oracle PL/SQL alapú adatbázis backendját valósítja meg. A rendszer lefedi a projektek teljes életciklusát: felhasználókezeléstől kezdve a board/task struktúrán át egészen a Git integráció automatikus feldolgozásáig.

Az adatbázis tervrajza a [dbdiagram.io](https://dbdiagram.io) eszközzel készült.

---

## Adatbázis felépítése

A séma az alábbi entitásokat tartalmazza:

| Entitáscsoport | Táblák |
|---|---|
| Felhasználók | `Users`, `Roles` |
| Projekt struktúra | `Projects`, `Boards`, `Columns`, `Tasks` |
| Tevékenység & kommunikáció | `Activity`, `Label`, `Comment` |
| Git integráció | `Git_Integration`, `Commit`, `Pull_Request` |

---

## Mappastruktúra

```
    AB2_Beadando/
    00_scripts/          # Telepítési és utility szkriptek (create_all_script.sql)
    01_tables/           # Tábladefiníciók (CREATE TABLE utasítások)
    02_packages/         # PL/SQL csomagok (spec + body)
    03_procedures/       # Önálló procedúrák
        Arhivalt/        # Archivált, már nem használt procedúrák
    04_functions/        # Önálló függvények
        Arhivalt/        # Archivált függvények
    05_triggers/         # Triggerek
    06_types/            # Oracle objektumtípusok
    07_test_data/        # Teszt adatok betöltéséhez szükséges szkriptek
    08_tests/            # Tesztek
    10_bemutato/         # Projekt bemutató (prezentáció)
```

---

## Főbb csomagok (Packages)

A rendszer szinte minden adatbázis táblához külön kezelő csomaggal rendelkezik, amelyek általános CRUD-ot helyettesítő procedúrákat és speciális funkcionalitást tartalmaznak.

### Kezelő csomagok

| Csomag | Felelősség |
|---|---|
| `pkg_exceptions` | Egyéni kivételek definíciója |
| `err_log_pkg` | Hibák naplózása |
| `activity_log_mgmt_pkg` | Tevékenységnapló kezelése |
| `sprint_mgmt_pkg` | Sprint életciklus kezelése |
| `board_mgmt_pkg` | Board műveletek |
| `column_mgmt_pkg` | Oszlopkezelés boardokon belül |
| `task_mgmt_pkg` | Task CRUD és üzleti logika |
| `task_overview_pkg` | Task összesítő lekérdezések |

### `projekt_mgmt_pkg` – Projekt létrehozás

Projekt létrehozásakor automatikusan létrejönnek a projekthez tartozó **Oracle szekvenciák**, így minden projektnek saját, független számlálója van a taskokhoz.

- A task azonosítók formátuma: `PMA-0012` (**Task_Key**)
- Segédcsomagok: `util_pkg`
  - `build_next_task_key_fnc` – következő Task_Key előállítása
  - `build_task_seq_name_fnc` – szekvencia nevének generálása

---

## Git Webhook Integráció

A rendszer képes Git commit és pull request üzenetek automatikus feldolgozására.

**`git_integration_mgmt_pkg.process_git_message_fnc`** végzi:
1. Az esemény típusának azonosítását (commit / PR)
2. A Task_Key kinyerését az üzenetből **reguláris kifejezéssel**
3. Ellenőrzést, hogy létezik-e az adott task
4. Sikeres egyezés esetén az esemény rögzítését az adatbázisban

**Érvényes Task_Key példa:** `PMA-0012`  
**Érvénytelen eset:** nem létező `proj_key` vagy task -> kivétel kiváltása

---

## Auditáció és Historizáció

Az `audit_util_pkg` csomag **dinamikus SQL** segítségével automatikusan biztosítja:

- Auditációs mezők automatikus kezelését minden táblán:
  - `MOD_USER`, `DML_FLAG`, `LAST_MODIFIED`, `VERSION`
- `<Tábla_Név>_H` history táblák automatikus létrehozását
- History triggerek és auto-ID triggerek generálását

**Kulcs procedúrák:**

```sql
audit_util_pkg.create_auto_id_created_trg_prc(...)
audit_util_pkg.create_historisation_for_table(...)
```

> **Ismert korlátok:** Az implementáció nem kezeli az utólagos tábla módosításokat (ALTER), és nem teljesen automatizált. Meglévő `_H` tábla adatai esetén újrafuttatás problémás lehet.

---

## Oracle Típushierarchia

A board áttekintő lekérdezések komplex Oracle objektumtípus-hierarchiára épülnek:

```
Ty_Board_Overview
    Ty_Column_Overview_L  (lista típus)
        Ty_Column_Overview
            Ty_Task_Overview_L  (lista típus)
                Ty_Task_Overview
```

A `get_board_overview_fnc` függvény visszaad egy `Ty_Board_Overview` objektumot, amely egy board teljes, aktuális állapotát tartalmazza aggregált formában.

---

## Telepítés

1. Klónozd le a repót:
   ```bash
   git clone https://github.com/PeterTrunk/AB2_Beadando.git
   ```

2. Futtasd le a fő telepítő szkriptet:
   ```sql
   @00_scripts/create_all_script.sql
   ```

3. (Opcionális) Töltsd be a teszt adatokat:
   ```sql
   -- Lásd: 07_test_data/
   ```

---

## Tesztek

A tesztek a `08_tests/` mappában találhatók.

---

## Technológiák

- **Oracle Database** (PL/SQL)
- **dbdiagram.io** – adatbázis séma tervezés
- **Git webhook** – automatikus integráció

---

## Licence

### Megjegyzés: ###
Az Oracle Database kereskedelmi használatra fizetős, licencköteles szoftver. Ez a projekt fejlesztése során Oracle tanulási célú licenc került felhasználásra. 
