import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AddMediaFilePage extends StatefulWidget {
  const AddMediaFilePage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddMediaFilePage> createState() => _AddMediaFilePageState();
}

class _AddMediaFilePageState extends State<AddMediaFilePage> {
  final TextEditingController _tecSrc = TextEditingController();
  VideoPlayerController? _videoPlayerController;
  bool _canSave = false, _isSaved = false, _canTestSrc = false, _isVideo = false, _isTesting = false;
  String _src = '';

  // * Test data
  // Image: https://i.pinimg.com/1200x/bb/12/03/bb12038681429c0e313c3001a973ef0f.jpg
  // Video: https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4
  // video: https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      debugPrint('Disposing the video player!');
      _videoPlayerController!.dispose();
    }
    _tecSrc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _isSaved ? () async => true : () => DialogManager.discardChanges(context: context),
        child: Scaffold(appBar: AppBar(title: const Text('Add media')), body: _buildBody()));
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildMediaTestSlot(),
        TextField(
          controller: _tecSrc,
          onChanged: _onSrcTextChange,
          decoration: const InputDecoration(hintText: 'Web link e.g. ', label: Text('Media web source')),
        ),
        SwitchListTile(value: _isVideo, onChanged: _onIsVideoChange, title: const Text('Video File')),
        _buildTestSrcButton(),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildTestSrcButton() {
    return ElevatedButton(onPressed: _canTestSrc ? _onTestSrcClick : null, child: const Text('Test Source'));
  }

  Widget _buildSaveButton() {
    return ElevatedButton(onPressed: _canSave ? _onSaveClick : null, child: const Text('Save'));
  }

  Widget _buildMediaTestSlot() {
    Widget child = const Center(child: Text('Awaiting File...'));
    if (_isTesting) {
      child = _isVideo ? _buildVideoPlayerTest() : _buildImageTest();
    }

    return AspectRatio(aspectRatio: 16 / 9, child: child);
  }

  Widget _buildImageTest() {
    _src = _sanitiseSrc();
    return Image.network(_src, errorBuilder: (_, __, ___) {
      _onSrcTestError();
      return const Center(child: Text('Image did not work! 😢'));
    });
  }

  Widget _buildVideoPlayerTest() {
    _src = _sanitiseSrc();
    _videoPlayerController = VideoPlayerController.network(_src);

    return FutureBuilder(
        future: _videoPlayerController!.initialize().onError((error, stackTrace) {
          debugPrint('On error of the initialise');
          _onSrcTestError();
        }),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (!snap.hasData || snap.hasData) {
            result = _buildVideoPlayer();
          } else if (snap.hasError) {
            // can we ever get here?
            debugPrint('Something wrong with the video fetching: ${snap.error}');
            result = const Center(child: Text('Video did not work! 😢'));
          }

          return result;
        });
  }

  Widget _buildVideoPlayer() {
    if (_videoPlayerController!.value.isInitialized) {
      debugPrint('We are initialised!');
      _videoPlayerController!.play();
      _videoPlayerController!.setLooping(true);
      //  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      //   _videoPlayerController!.play();
      //   _videoPlayerController!.setLooping(true);
      // });
    }

    return VideoPlayer(_videoPlayerController!);
  }

  // * Logic

  void _onSaveClick() {
    DialogManager.showConfirmationDialog(context: context, title: 'Save Media', content: 'Are you sure?')
        .then((confirmation) {
      if (confirmation) {
        widget.eventContext.media.addMediaFile({'title': '', 'src': _src, 'type': _isVideo ? 'vid' : 'img'});
        _isSaved = true;
        Navigator.of(context).pop();
      }
    });
  }

  void _onTestSrcClick() {
    setState(() {
      if (_videoPlayerController != null) {
        _videoPlayerController!.pause();
        _videoPlayerController = null;
      }
      _canSave = true;
      _isTesting = true;
    });
  }

  void _onSrcTextChange(String newText) {
    if (_canTestSrc && newText.trim().isEmpty) {
      setState(() {
        _canTestSrc = false;
      });
    } else if (!_canTestSrc) {
      setState(() {
        _canTestSrc = true;
      });
    }
  }

  void _onIsVideoChange(bool newState) {
    setState(() {
      _isVideo = newState;
    });
  }

  void _onSrcTestError() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        _canSave = false;
        _isTesting = false;
      });
    });
  }

  String _sanitiseSrc() {
    // ! remember those google stuff
    return _tecSrc.text.trim();
  }
}
