import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/board_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/thread_repository.dart';

/// ---- Firebase singletons ----
final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

/// ---- Repositories ----
final boardRepositoryProvider = Provider<BoardRepository>(
  (ref) => BoardRepository(ref.watch(firebaseFirestoreProvider)),
);
final threadRepositoryProvider = Provider<ThreadRepository>(
  (ref) => ThreadRepository(ref.watch(firebaseFirestoreProvider)),
);
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(firebaseFirestoreProvider)),
);

/// ---- Auth (anonymous) ----
/// Each device gets a hidden uid we use only for per-thread identity hashing
/// and (later) server-side rate limiting. No name, email, or profile.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.uid,
);
