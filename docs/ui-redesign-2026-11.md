# UI redesign, November 2026

Part of a page-by-page pass so SMARTTT, Smart Attendance and the Timetable
Generator look and read as one platform. Colours already came from SMARTTT's
`app_theme.dart`; this pass is about **layout, wording and removing clutter**.
No API or data changes. The web apps' pages are documented in
`ATTENDANCE_fronted/docs/ui-redesign-2026-11.md` and
`Timetable-Generator/docs/ui-redesign-2026-11.md`.

## Student Class Schedule (`schedule_screen.dart`, 12 Nov 2026)

| Before | After |
|---|---|
| A full-width **Add to Calendar** button, then *Current Sem*, *Units* and *Conflicts* cards, before any class | **Classes first.** The calendar is an icon in the top bar (next to *Your Class Groups*); term, units and clashes are one compact line that wraps |
| Day chips **Mon–Sun** with tick marks, wrapping onto two rows on a small phone | **Mon–Fri** only (teaching days) as five equal buttons on one row; on a weekend the screen opens on Monday |
| *Current Sem* card cut the term name to one line (`…`) | The full term name, wrapping if needed |
| *Conflicts: 0* always shown | A red **"1 clash" / "N clashes"** badge only when there are any |
| Offline banner in hard-coded amber | Shared warning colours (`AppTheme.getWarning`, `getWarningSoft`, same values as the web apps), text "Offline: showing your saved timetable" |
| Group banner tinted with a border | Shared brand-soft colour (`AppTheme.getBrandSoft`) |
| Class card: unit code chip beside the title, squeezing long titles | Time and code on the top line (a long code such as `BITE 131/COSC 130` wraps), the title below at full width, lecturer and room with icons |
| "Room TBA" | "Room to be announced" |

**No name is ever cut off on a phone.** Unit titles, codes, lecturer and room
names wrap instead of ending in "…". The same fix was applied to the home
screen's class card (lecturer and room), the lecturer's timetable (unit name)
and the student preferences list (course name). Checked at 360 px wide with long
sample names.

Files: `lib/features/schedule/presentation/schedule_screen.dart`, `lib/core/theme/app_theme.dart`,
`lib/features/home/presentation/widgets/timetable_card.dart`,
`lib/features/lecturer/presentation/screens/lecturer_schedule_tab.dart`,
`lib/features/schedule/presentation/student_preferences_screen.dart`.


## Theme button everywhere (12 Nov 2026)

The light / dark / system theme button was only in the signed-in headers (and, in
the SMARTTT app, only on the Profile screens). It is now on every screen people land on:
sign-in, Home, Class Schedule, Exams and Alerts (students) and the Schedule, Exams and Notifications tabs (lecturers), as well as both Profile screens as before (`widgets/theme_cycle_button.dart`).
