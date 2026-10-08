# StudyDoc Design System

## 1. Identity
Preserve the existing quiet, academic Material 3 interface in `lib/colors.dart`
and the shared document, search, badge, and empty-state widgets. Cloud is a
separate library, not a redesign or automatic synchronization of local SQLite.

## 2. Color
Use `Theme.of(context).colorScheme`, never a cloud-specific palette.
Existing primary: slate indigo `#1E3A8A` (light), `#60A5FA` (dark).
Surfaces: `#FFFFFF` / `#1E293B`; scaffold: `#F8FAFC` / `#0F172A`.
Use `onSurface` for text, `outline` for neutral card edges,
`primaryContainer` for tonal actions, `tertiaryContainer` for emulator warnings,
and `errorContainer` / `onErrorContainer` for failures. Pair status with text
and a Material icon; do not mark selection with an accent border.

## 3. Typography
Retain Flutter's existing platform Material font and `TextTheme` scale:
`headlineSmall` (page heading), `titleLarge` (section), `titleMedium` (card),
`titleSmall` (subheading), `bodyLarge` (form/content), `bodyMedium` (explanation),
and `labelLarge` (actions). No new fonts. Keep Home's original 17px title and
11px architecture subtitle verbatim; ellipsize them instead of overflowing.

## 4. Spacing And Layout
Extract the existing 4px grid as `CloudUi`: tight 4, small 8, medium 12,
standard 16, section 24. Controls retain Material's 48px minimum target.
Cloud content has a 960px desktop maximum; forms have a 640px maximum;
compact navigation starts below 600px. Use wrapping action groups and a
single vertical body scroll within `SafeArea`, below a fixed `AppBar`.
This adapts the [scroll-body-shell pattern](https://github.com/changeroa/StyleGallery/blob/main/patterns/viewport-shell/scroll-body-shell.md)
to Flutter's bounded `Scaffold` body. Bottom sheets own their list scroll.

## 5. Primitives
Reuse themed `Card`, `TextFormField`, `FilledButton`, `OutlinedButton`,
`IconButton`, `AlertDialog`, `LinearProgressIndicator`, and `EmptyStateView`.
`CloudPanel` groups a heading and content using standard padding.
`CloudMessage` provides selectable explanation/error text and a status icon.
`CloudScaffold` supplies the shared width limiter, safe area, scrolling, and
busy back-navigation guard. Forms label every input and show validation
beside it. Document cards wrap filename/subject and separate download from
edit/delete actions. Standard Material controls own focus/press/disabled states.

## 6. Interaction
Keep standard Material transitions; add no decorative animation. Busy actions
disable repeat submissions and exit/signout until completion. Upload progress
comes from Storage events; 100% bytes still means metadata is being saved.
Auth subtrees and document streams are keyed by UID. Forms hide stale content
on session change and check identity again after asynchronous work.

## 7. Depth
Use the existing zero-elevation cards, neutral 1px outline, 16px card radius,
12px input radius, and normal Material dialog/sheet elevation. Tonal containers
communicate emulator mode and errors in both themes, without new shadows.

## 8. Accessibility And Scope
Keep visible labels, tooltips on icon actions, selectable email/UID/project ID,
keyboard-accessible Material controls, safe areas, and wrapping long content.
Cloud supports web/Android only and requires connectivity; unavailable/error
states reference `HUONG_DAN_FIREBASE_VA_DEMO.md`. Emulator is explicitly not
real Google/Cloud. Search filters at most 100 newest streamed demo entries on
the client, not server full-text; the service may stream the full small demo
collection. Local selection copies only title/subject/note and clears any old
file selection: the user must choose actual bytes. No download/share URLs.
Existing local compact typography and unrelated widgets remain out of scope;
no new design debt is accepted here. Real cloud credentials and browser QA
remain separate verification requirements, not implied by widget tests.
