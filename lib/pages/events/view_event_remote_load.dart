import '../../models/event/event_media.dart';
import '../../models/event/event_metadata.dart';
import '../../models/event/event_program.dart';

/// Essentials needed to open a post (everything except the activity log).
typedef PostEssentials = ({
  EventMedia media,
  EventMetadata metadata,
  EventProgram program,
  String body,
});

/// Loads media, metadata, program, and body in parallel (one network wait).
///
/// The activity log is intentionally omitted — most viewers never open it, so
/// callers should fetch that after the page is already showing.
Future<PostEssentials> fetchPostEssentialsParallel({
  required Future<EventMedia> media,
  required Future<EventMetadata> metadata,
  required Future<EventProgram> program,
  required Future<String> body,
}) async {
  final results = await Future.wait<Object>([
    media,
    metadata,
    program,
    body,
  ]);
  return (
    media: results[0] as EventMedia,
    metadata: results[1] as EventMetadata,
    program: results[2] as EventProgram,
    body: results[3] as String,
  );
}
