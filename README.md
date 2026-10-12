# In-Class Activity 09 — Local Storage Part II

**Student:** Jihun Kim  
**Course:** Mobile Application Development  
**Section:** 2  
**Pathway:** Undergraduate

## 1. Project Overview

This project continues my Flutter SQLite application from In-Class Activity 08. In Part I, I created a Fall Festival Roster app that saves guest names and ages. In Part II, I kept the original roster and added a simple card collection feature.

Users can create folders, add cards to a folder, edit card information, and delete cards or folders. The data is saved in a local SQLite database, so it can still be available after the app is closed and reopened.

## 2. Development Environment

- **Framework:** Flutter
- **Language:** Dart
- **Database:** SQLite (`sqflite`)
- **Editor:** Visual Studio Code
- **Test device:** Android Emulator, Pixel 7 Pro (API 35)
- **Packages:** `sqflite`, `path_provider`, and `path`

To run the app:

```bash
flutter pub get
flutter run
```

To check the code:

```bash
flutter analyze
```

The final analyzer check showed **No issues found!** I saved the output in `evidence/analysis_output.txt`.

## 3. What I Kept from Activity 08

The original Fall Festival Roster is still part of the project. It uses the `my_table` table with the columns `_id`, `name`, and `age`.

The roster supports adding guests, viewing saved records, editing and canceling edits, deleting records with confirmation, refreshing the list, and validating names and ages. Valid ages are from 0 to 130. SQLite uses each guest's ID to identify the correct record, even when two guests have the same name.

In Part I, I tested these features:

| Test | What I checked | Result |
| --- | --- | --- |
| T1 | Empty roster and refresh | PASS |
| T2 | Two guests with the same name have different IDs | PASS |
| T3 | Edit, cancel, and save | PASS |
| T4 | Data stays after restarting the app | PASS |
| T5 | Delete confirmation | PASS |
| T6 | Invalid input and age limits | PASS |

The original screenshots are still included in the `evidence` folder, including `T1_empty.png`, `T3_save.png`, `T4_before.png`, `T4_after.png`, `T5_delete.png`, and `T6_invalid.png`.

## 4. Database Upgrade in Activity 09

I updated the SQLite database from **version 1 to version 2**. Instead of deleting the old database, the app uses an upgrade method to create the new tables while keeping the original `my_table` data.

Before the upgrade, I saved a screenshot showing three roster records: Alice (22), Bob (25), and Charlie (30). After the upgrade, those records were still present with the same IDs and information.

**Evidence:** `evidence/T1_before.png` and `evidence/T1_after.png` (the before screenshot may be inside a nested evidence folder in my working project).

### Database tables

**`my_table` — Original roster**

| Column | Purpose |
| --- | --- |
| `_id` | Unique guest ID |
| `name` | Guest name |
| `age` | Guest age |

**`folders` — Card folders**

| Column | Purpose |
| --- | --- |
| `id` | Unique folder ID |
| `name` | Folder name (must be unique) |
| `created_at` | Date and time the folder was created |

**`cards` — Cards saved inside folders**

| Column | Purpose |
| --- | --- |
| `id` | Unique card ID |
| `title` | Card title |
| `suit` | Card suit |
| `notes` | Optional notes |
| `image_ref` | Optional image reference |
| `folder_id` | ID of the folder containing the card |

The `folder_id` column is a foreign key connected to `folders.id`. The database also has an index on `cards.folder_id` to help find cards in a folder.

## 5. New Folder and Card Features

### Folder features

The **Card Folders** screen shows the saved folders and the number of cards in each one. I can add a new folder using the **+** button, open a folder to see its cards, refresh the list, or delete a folder after a confirmation message.

The folder name cannot be empty, and SQLite prevents duplicate folder names.

### Card features

Inside a folder, I can add a card with a title, suit, and notes. I can also edit an existing card or delete it. The card list updates after changes are saved.

During development, I had a Flutter red-screen error when saving or editing cards. I checked the code and tested the card screen again. After fixing the issue, I was able to save and edit cards normally.

## 6. Foreign Keys and Cascade Delete

I enabled SQLite foreign key support using `PRAGMA foreign_keys = ON`.

The `cards` table uses this relationship:

```sql
FOREIGN KEY (folder_id)
  REFERENCES folders(id)
  ON DELETE CASCADE
```

This means deleting a folder also deletes the cards inside that folder. It helps prevent cards from being left in the database without a valid folder.

I tested this by deleting a folder that contained a card. After the deletion, the folder was gone, and the card was no longer in the database. I also checked the database using SQLite commands. The foreign key information showed `ON DELETE CASCADE`.

**Evidence:** `evidence/cascade_before.png` and `evidence/cascade_after.png`.

## 7. Testing and Evidence

I tested the new features in the Android emulator and checked the database where needed.

| Test | What I checked | Result / Evidence |
| --- | --- | --- |
| Database migration | Existing roster data remains after upgrading to version 2 | PASS — `T1_before.png`, `T1_after.png` |
| Folder creation | A new folder can be saved and opened | PASS — tested in emulator |
| Card creation and editing | A card can be added and its notes can be changed | PASS — tested in emulator |
| Card deletion | Deleting a card removes it from the list | PASS — `card_before_delete.png`, `card_after_delete.png` |
| Cascade delete | Deleting a folder removes its cards | PASS — `cascade_before.png`, `cascade_after.png` |
| Static analysis | `flutter analyze` | PASS — `analysis_output.txt` |

I also used SQLite to inspect the `folders` and `cards` tables and check the foreign key relationship. The foreign key query confirmed that `cards.folder_id` refers to `folders.id` with cascade deletion.

## 8. Problems and What I Learned

One problem I had was a red Flutter error screen when saving a new card or editing an existing one. The folder screen worked, but the card form caused an error. I reviewed the card page, made changes, and tested it again until the save and edit actions worked.

I also learned that changing a database schema is different from creating a new database. A migration is important because it lets an app add features without losing information that users already saved.

The cascade delete test helped me understand foreign keys. A card belongs to a folder, so removing the folder should also remove its cards. Testing the database directly helped me confirm that this relationship worked.

## 9. AI Assistance Disclosure

I used ChatGPT as a learning and coding assistant during this activity. It helped me understand the assignment, plan the SQLite upgrade, write and review parts of the Flutter code, troubleshoot the card form error, and organize the testing steps and README.

I ran the application, checked the results in the Android emulator, used SQLite commands, and captured the evidence screenshots. The original database helper starter code was provided by the instructor.

## 10. Conclusion

In this activity, I extended my existing Flutter app without removing the original roster feature. I added folders and cards, upgraded the SQLite database to version 2, and tested the foreign key relationship and cascade delete behavior.

This project helped me better understand database migrations, relationships between tables, and why testing saved data is important in mobile applications.
