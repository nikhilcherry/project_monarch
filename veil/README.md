# Veil

> A modern, **anonymous** topic-board discussion app — a cleaner, better-moderated
> take on imageboards like 4chan / 2chan. Flutter (web + iOS + Android),
> Firebase backend.

No accounts. No names. You post anonymously, but within a single thread a
per-thread color + tag lets people follow a conversation — without ever
linking you across threads or exposing an identity.

> ⚠️ **Status:** early MVP scaffold. Currently lives as a subfolder of the
> `project_monarch` repo for convenience; it's self-contained and meant to be
> extracted into its own repo. See "Roadmap".

## Stack

- **Flutter** (Dart `>=3.4`) — one codebase → web + mobile
- **Riverpod** (`flutter_riverpod`) — state (manual providers/Notifiers, no codegen)
- **Firebase** — Cloud Firestore (data), Anonymous Auth (hidden per-device uid),
  Storage (post images, wired in rules + deps; upload UI is next)

## Architecture — strict layering

UI never touches Firebase; logic never lives in widgets.

```
lib/
├── main.dart            # boot: Firebase init + anonymous sign-in, ProviderScope
├── app.dart             # MaterialApp + theme
├── core/
│   ├── theme/           # AppTheme.dark
│   ├── constants/       # AppColors, seed boards
│   └── utils/           # AnonId (per-thread identity), relative time
├── models/              # Board, Thread, Post (Firestore (de)serialization)
├── repositories/        # the ONLY Firebase callers (board/thread/post)
├── controllers/         # Riverpod providers + composer orchestration
├── views/               # boards → threads → thread screens
└── widgets/             # AnonTag, tiles, PostCard, …
```

**Data flow:** `View` → watches a Riverpod provider → `Repository` →
Firestore. Writes (new thread / reply) go through a *composer* provider that
stamps the anonymous tag and runs a batched write that also bumps denormalized
counters.

### Firestore layout

```
boards/{boardId}                                  → { title, description, accentColor, order, threadCount, postCount }
boards/{boardId}/threads/{threadId}               → { title, body, authorHash, createdAt, bumpedAt, replyCount, lastReplyAt, imageUrl? }
boards/{boardId}/threads/{threadId}/posts/{postId}→ { body, authorHash, createdAt, replyTo?, imageUrl? }
```

Threads sort by `bumpedAt` (descending) so active discussions float up.

### Anonymous identity (the "trust without identity" layer)

`AnonId.forThread(uid, threadId)` = `sha256(uid + threadId + salt)` → a 6-hex
tag + a palette color. Same person in a thread = same tag; the **same person in
a different thread gets a different tag**, so posts can't be correlated across
the board. The OP additionally gets an `OP` badge. See
`lib/core/utils/anon_identity.dart` and its tests.

## Setup

```bash
cd veil
flutter pub get

# Connect your Firebase project (overwrites the committed placeholder
# lib/firebase_options.dart with real keys):
dart pub global activate flutterfire_cli
flutterfire configure        # enable Firestore, Anonymous Auth, Storage

flutter run -d chrome        # or an emulator / device
```

Until `flutterfire configure` is run, the app shows a friendly setup screen
instead of crashing (the committed `firebase_options.dart` is a placeholder).

Deploy the security rules + indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Testing

```bash
flutter test                 # unit tests (AnonId logic has no Firebase dep)
```

## Roadmap

- [x] Boards → threads → posts (read path, realtime)
- [x] Create thread + reply (write path, batched counter bumps)
- [x] Per-thread anonymous identity (tag + color, OP badge)
- [ ] Image uploads (Storage rules + deps are in; needs picker + compose UI)
- [ ] Moderation: server-side rate limits, spam scoring, report flow, AI
      content checks (Cloud Functions — see `firestore.rules` notes)
- [ ] `>>` reply threading / quote jumps
- [ ] Thread auto-archiving + pagination / infinite scroll
- [ ] Extract into a standalone repo
```
