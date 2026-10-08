# In-Class Activity 08 — Local Storage Part 1

## Student Information

- **Name:** Jihun Kim
- **Course:** Mobile Application Development
- **Section:** 2
- **Pathway:** Undergraduate

## 1. Project Overview

**Fall Festival Roster** is a Flutter application developed to demonstrate persistent local storage using SQLite.

The application allows users to create, view, edit, and delete festival guest records. Each guest has a unique database ID, a name, and an age.

The main objective of this activity was to implement CRUD operations, understand the difference between temporary application state and persistent storage, and test the reliability of local database operations.

### Main Features

- Add new festival guests
- Display saved guests with their unique IDs
- Edit existing guest information
- Cancel editing without saving changes
- Delete guests using a confirmation dialog
- Refresh records from SQLite
- Display the total number of records
- Validate names and ages
- Accept ages between 0 and 130
- Preserve saved records after restarting the application

## 2. Development Environment

- **Framework:** Flutter
- **Programming Language:** Dart
- **Database:** SQLite
- **IDE:** Visual Studio Code
- **Testing Device:** Android Emulator — Pixel 7 Pro, API 35
- **Dependencies:** `sqflite`, `path_provider`, `path`

### Running the Application

```bash
flutter pub get
flutter run
```

### Static Analysis

The following command was used to check the project:

```bash
flutter analyze
```

**Result: PASS — No issues found!**

The analysis output is saved in `evidence/analysis_output.txt`.

## 3. Database Implementation

The application uses SQLite to store guest information locally.

**Database name:** `MyDatabase.db`

**Table name:** `my_table`

### Database Schema

| Column | Type | Description |
|---|---|---|
| `_id` | INTEGER PRIMARY KEY | Unique record identifier |
| `name` | TEXT NOT NULL | Guest name |
| `age` | INTEGER NOT NULL | Guest age |

Database initialization and CRUD methods are implemented in `lib/database_helper.dart`.

The Flutter user interface and input validation are implemented in `lib/main.dart`.

### CRUD Operations

**Create:** The Add button inserts a new guest into SQLite.

**Read:** The Refresh button retrieves saved records from the database.

**Update:** The Edit and Save buttons update the selected record using its unique ID.

**Delete:** The Delete button opens a confirmation dialog before removing the selected record.

Using unique IDs allows the application to manage records correctly even when multiple guests share the same name.

## 4. Manual Testing Results

### T1 — Empty Roster and Refresh

**Procedure:**

1. Removed all existing guest records.
2. Pressed Refresh.
3. Checked the record count and displayed list.

**Observed Results:**

- The record count displayed `Records: 0`.
- No guest records appeared.
- The empty roster message was displayed.

**Result: PASS**

**Evidence:** `evidence/T1_empty.png`

### T2 — Duplicate Names and Unique IDs

**Procedure:**

1. Added River, age 21.
2. Added another River, age 34.
3. Compared the database IDs.

**Observed Results:**

- Both guests were stored successfully.
- Each River record had a different ID.
- Both records appeared independently in the roster.

**Result: PASS**

The two River records are visible in the T4 screenshots with IDs 3 and 4.

This confirms that records are identified by their database IDs rather than their names.

### T3 — Edit, Cancel, and Save

**Procedure:**

1. Added River, age 34.
2. Selected Edit and changed the age to 99.
3. Selected Cancel Edit.
4. Confirmed that the saved age remained 34.
5. Selected Edit again.
6. Changed the age to 35.
7. Selected Save.

**Observed Results:**

- Cancel Edit preserved the original saved age.
- Save successfully updated River's age from 34 to 35.
- The database ID remained 1.
- The total record count remained 1.

**Result: PASS**

**Evidence:** `evidence/T3_save.png`

This test demonstrates that temporary editing changes are not written to SQLite until Save is selected.

### T4 — SQLite Persistence After Restart

**Prediction:**

Before restarting the application, I predicted that the guest records would remain available because SQLite stores data persistently on the device.

**Procedure:**

1. Displayed the saved guest records.
2. Captured a screenshot before restarting.
3. Stopped the application.
4. Reopened the application without clearing its stored data.
5. Refreshed the roster.
6. Compared the records before and after restarting.

**Observed Results:**

| ID | Name | Age Before | Age After |
|---|---|---|---|
| 3 | River | 34 | 34 |
| 4 | River | 21 | 21 |
| 5 | Acorn | 0 | 0 |
| 6 | Oak | 130 | 130 |

- **Before restart:** 4 records
- **After restart:** 4 records
- All guest names, ages, and IDs remained unchanged.

**Result: PASS**

**Evidence:**
- `evidence/T4_before.png`
- `evidence/T4_after.png`

**Conclusion:**

The application successfully preserved all four records after restarting. This confirms that guest information is stored in SQLite rather than only in temporary Flutter widget state.

### T5 — Delete Confirmation

**Procedure:**

1. Selected Delete for the River record.
2. Canceled the deletion.
3. Verified that the record remained in the roster.
4. Selected Delete again.
5. Confirmed the deletion.
6. Refreshed the roster.

**Observed Results:**

- Canceling deletion preserved the record.
- Confirming deletion removed River.
- The record count changed from 1 to 0.
- The empty roster message appeared.

**Result: PASS**

**Evidence:** `evidence/T5_delete.png`

The confirmation dialog helps prevent accidental record deletion.

### T6 — Input Validation and Boundary Testing

**Objective:**

Verify that the application validates user input and supports the required age range.

### Validation Rules

**Name Validation:**
- Empty names are rejected.
- Names containing only whitespace are rejected.

**Age Validation:**
- Age must be a whole number.
- Minimum accepted age: 0.
- Maximum accepted age: 130.
- Nonnumeric, negative, decimal, and out-of-range values are rejected.

### Test Results

| Input | Expected Result | Observed Result |
|---|---|---|
| Acorn, age `abc` | Reject | Rejected |
| Acorn, age `0` | Accept | Accepted |
| Oak, age `130` | Accept | Accepted |

**Observed Results:**

- The application displayed an error message for the invalid age `abc`.
- Acorn with age 0 was successfully saved.
- Oak with age 130 was successfully saved.
- Both valid boundary records appeared in the roster.

**Result: PASS**

**Evidence:**
- `evidence/T6_invalid.png`
- `evidence/T4_before.png`
- `evidence/T4_after.png`

The validation logic also checks for empty names, whitespace-only names, decimal ages, negative ages, and ages above 130.

## 5. Testing Summary

| Test | Description | Result |
|---|---|---|
| T1 | Empty roster and refresh | PASS |
| T2 | Duplicate names and unique IDs | PASS |
| T3 | Edit, cancel, and save | PASS |
| T4 | Persistent data after restart | PASS |
| T5 | Delete cancellation and confirmation | PASS |
| T6 | Input validation and age boundaries | PASS |
| Static Analysis | Flutter analyzer | PASS |

The completed tests demonstrate the core functionality of the Fall Festival Roster application.

## 6. Critical Thinking Questions

### Question 1 — The Disappearing-Data Mystery

**What did you predict would happen after restarting the application? What actually happened?**

Before restarting the application, I predicted that the saved guest records would remain available because SQLite stores data persistently on the device.

After restarting the application, all four guest records were still present. Their IDs, names, ages, and the total record count remained unchanged.

This confirmed my prediction.

SQLite data is different from temporary Flutter widget state. Widget state may be lost when an application closes, but data stored in SQLite can be retrieved again when the application starts.

The T4 screenshots demonstrate that the application successfully retrieved the previously saved records.

### Question 2 — Two Rivers, One Wrong Edit

**Why are unique IDs important when two guests have the same name?**

Two guests can have identical names, so names should not be used as unique identifiers for database operations.

In this application, two guests named River were stored with different IDs.

When a user selects Edit, the application uses the selected record's unique ID to identify which database row should be updated.

This prevents the application from accidentally updating the wrong guest.

The Cancel Edit feature also shows the difference between temporary form state and saved database information. Canceling an edit does not modify the stored record.

Using unique primary keys makes database operations more reliable and accurate.

### Question 3 — Usability Walkthrough

**How does the interface help users manage data, and what could be improved?**

The application provides a simple interface for managing festival guests.

Users can add guests using the name and age fields, view saved records, edit existing information, and delete records.

The Refresh button retrieves the latest data from SQLite, while the record count shows how many guests are currently stored.

The Edit and Cancel Edit buttons allow users to make changes without accidentally saving unwanted information.

The Delete confirmation dialog helps prevent accidental deletion.

Input validation prevents invalid guest information from being saved.

One possible improvement would be to display more specific error messages for different invalid inputs. Another improvement would be to add search and sorting functionality for larger guest lists.

Overall, the interface provides the essential features needed for a simple local database application.

## 7. Evidence Files

The `evidence` folder contains the screenshots and analysis results collected during testing.

| File | Description |
|---|---|
| `T1_empty.png` | Empty roster and zero record count |
| `T3_save.png` | Successful update of River's age |
| `T4_before.png` | Guest records before restarting |
| `T4_after.png` | Guest records after restarting |
| `T5_delete.png` | Empty roster after confirmed deletion |
| `T6_invalid.png` | Invalid age validation message |
| `analysis_output.txt` | Flutter static analysis output |

## 8. Challenges and Lessons Learned

One challenge was implementing input validation correctly.

The age validation logic was updated to accept the required range from 0 through 130 while rejecting unsupported values.

Testing confirmed that both boundary ages could be saved successfully.

Another important lesson was understanding the difference between temporary application state and persistent database storage.

The restart test showed that SQLite can preserve records after the application is closed and reopened.

I also learned why database operations should use unique primary keys rather than guest names.

This activity provided practical experience with Flutter interfaces, asynchronous database operations, CRUD functionality, and local data persistence.

## 9. AI Assistance Disclosure

ChatGPT was used as a learning and development assistant during this activity.

AI assistance included:

- Explaining Flutter and SQLite concepts
- Interpreting assignment requirements
- Helping implement and troubleshoot the user interface
- Improving input validation logic
- Explaining CRUD operations and persistent storage
- Guiding manual testing procedures
- Organizing and proofreading the README documentation

The database helper starter code was provided by the instructor.

Application execution, manual testing, and screenshots were performed by the student.

## 10. Conclusion

The Fall Festival Roster application demonstrates how Flutter can use SQLite for persistent local data storage.

The application supports creating, reading, updating, and deleting guest records. It also demonstrates unique record identification, input validation, edit cancellation, delete confirmation, and data persistence after restarting.

The manual tests confirmed the core CRUD functionality, and Flutter static analysis completed without issues.

This activity improved my understanding of how local databases work in Flutter applications and why persistent storage is important for managing structured data.