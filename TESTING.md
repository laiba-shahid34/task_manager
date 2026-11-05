# Testing Report

Tested on a Samsung Galaxy phone (Android) with the release APK.

## Automated tests
Run with `flutter test`. File: `test/task_logic_test.dart`.

| Area | What is checked |
|---|---|
| Task model | Saving to and loading from the database format keeps all fields; clone is independent; overdue detection |
| Progress | 0% / 100% without subtasks, percentage with subtasks |
| Repeat | Labels, next date for daily tasks, next date for selected weekdays |
| Dates | `sameDay` and `dayOnly` helpers |

## Manual test cases

| # | Feature | Steps | Expected result | Result |
|---|---|---|---|---|
| 1 | Add task | Tap +, fill title and date, Save | Task appears in the list | Pass |
| 2 | Edit task | Open task, edit title, Save | Changes are shown | Pass |
| 3 | Delete task | Swipe a task | Task disappears; Undo brings it back | Pass |
| 4 | Complete task | Tap the circle | Task moves to Completed | Pass |
| 5 | Today view | Add a task for today | Visible under Today | Pass |
| 6 | Repeat daily | Complete a daily task | Copy in Completed, task moves to next day | Pass |
| 7 | Repeat weekdays | Complete a weekly task | Task moves to the next chosen weekday | Pass |
| 8 | Subtasks | Add 4 subtasks, tick 2 | Progress shows 50% | Pass |
| 9 | Theme | Settings > Dark | App switches to dark mode | Pass |
| 10 | Sound | Select a sound | Preview plays | Pass |
| 11 | Notification | Set a task 2 minutes ahead | Notification arrives | Pass |
| 12 | Closed app | Close the app, wait for the time | Notification arrives | Pass |
| 13 | Follow-up | Leave task incomplete for 10 min | "Still pending" notification | Pass |
| 14 | Loud alarm | Choose Loud alarm, run test | Alarm rings until dismissed | Pass |
| 15 | Export CSV / PDF | Settings > Export | File is shared | Pass |
| 16 | Email | Settings > Send by email | Share sheet, Gmail can be selected | Pass |
| 17 | Persistence | Close and reopen the app | All tasks are still there | Pass |
| 18 | Small / large screens | Rotate phone, change font size | No overflow, layout fits | Pass |

> Update the "Result" column with what you actually saw on your phone before submitting.
