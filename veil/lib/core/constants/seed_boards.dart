import '../../models/board.dart';

/// Default boards created on first run when the `boards` collection is empty.
/// (MVP convenience — later this moves to an admin-only seed/Cloud Function.)
const List<Board> kSeedBoards = <Board>[
  Board(
    id: 'tech',
    title: 'Technology',
    description: 'Software, hardware, the future. Show your build.',
    accentColor: 0xFF5BB8FF,
    order: 0,
  ),
  Board(
    id: 'art',
    title: 'Art & Design',
    description: 'Drawings, generative art, type, anything visual.',
    accentColor: 0xFFFF7AB6,
    order: 1,
  ),
  Board(
    id: 'random',
    title: 'Random',
    description: 'The off-topic catch-all. Anything goes (within reason).',
    accentColor: 0xFF4EC29A,
    order: 2,
  ),
  Board(
    id: 'ask',
    title: 'Ask',
    description: 'Questions and discussion. No bad questions here.',
    accentColor: 0xFFFF9E64,
    order: 3,
  ),
  Board(
    id: 'meta',
    title: 'Meta',
    description: 'Feedback, rules, and talk about Veil itself.',
    accentColor: 0xFF8B7CFF,
    order: 4,
  ),
];
