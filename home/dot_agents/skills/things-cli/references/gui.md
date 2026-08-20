# How the user sees Things (the app GUI)

Curated rendering facts — the bench loop may compress or relocate these but must never add or change their meaning without Mike's approval (bench/CONSTITUTION.md).

<!-- STATUS: v0 seeded from Mike's description 2026-07-17; awaiting his review pass. -->

- **Sidebar**: top-level views (Inbox, Today, Upcoming, Anytime, Someday, Logbook, Trash), then each **area** with its active **projects** nested beneath it — in the same order this CLI/API reports them. Reordering areas or projects changes what the user sees there.
- **List rows are compact**: a to-do in any list shows its checkbox/status, title, tags, deadline, and small marker chips — the Today ★, This Evening ⏾, and (in the Today view only) the provisional `•` "new item" pip, plus has-notes / reminder / checklist glyphs (`things legend` names them all). The **notes TEXT and checklist CONTENTS are invisible until the user opens the item**. Put must-see-at-a-glance information in the title; supporting detail belongs in notes. Projects carry the same Today ★ / This Evening ⏾ pips as to-dos. Why some chips vanish once a row's date goes stale — the reminder bell, the This-Evening section, and the provisional pip — is in [banner.md](banner.md).
- **Project notes** are likewise visible only when the project itself is opened in project view — in lists, a project is just its title (and progress ring).
- **Today** shows the day's scheduled items, with **This Evening** as a separate section beneath. **Upcoming** is a forward-looking date-ordered calendar of scheduled items. **Logbook** is where completed/canceled items go — after completing something for the user, that's where they'll find it.
- When telling the user where something landed, name the container and view ("in project P under area A"; "it'll show in Today this evening").
