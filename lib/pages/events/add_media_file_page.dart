import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

class AddMediaFilePage extends StatefulWidget {
  const AddMediaFilePage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddMediaFilePage> createState() => _AddMediaFilePageState();
}

class _AddMediaFilePageState extends State<AddMediaFilePage> {
  final TextEditingController _tecSrc = TextEditingController();
  final RegExp _driveRegExp = RegExp(r"drive.google.com/file/d/([a-zA-Z0-9_-]+)");
  VideoPlayerController? _videoPlayerController;
  bool _canSave = false, _canTestSrc = false, _isVideo = false, _isTesting = false;
  String _src = '';
  File? _tmpFile;

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
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add media'),
          actions: [IconButton(onPressed: _showHelp, icon: const Icon(Icons.help))],
        ),
        body: _buildBody());
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildMediaTestSlot(),
        TextField(
          controller: _tecSrc,
          onChanged: _onSrcTextChange,
          decoration: InputDecoration(
              hintText: 'Web link e.g. ',
              label: const Text('Media web source'),
              suffixIcon: IconButton(onPressed: () => _tecSrc.clear(), icon: const Icon(Icons.clear))),
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
    Widget child = const Center(
        child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('Awaiting File...'),
    ));
    if (_isTesting) {
      child = _isVideo ? _buildVideoPlayerTest() : _buildImageTest();
    }

    return child;
  }

  Widget _buildImageTest() {
    if (_tmpFile != null && _canSave) {
      return Image.file(_tmpFile!);
    }
    return FutureBuilder(
        future: _fetchFile(true),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            _tmpFile = snap.data!;
            final size = _tmpFile!.lengthSync();
            final double sizeInKb = size / 1024;

            if (sizeInKb <= 100) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                setState(() {
                  _canSave = true;
                });
              });
              result = Image.file(_tmpFile!);
            } else {
              _canSave = false;
              result = Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          'This file is too large (${sizeInKb.toStringAsFixed(2)} KB)! Maximum image file size is 100 KB, so please compress it or use another image!',
                          textAlign: TextAlign.center),
                      TextButton(
                          onPressed: () => launchUrlString('https://imagecompressor.com'),
                          child: const Text('Online Image Compressor'))
                    ],
                  ));
            }
          } else if (snap.hasError) {
            debugPrint('something with fetching the file: ${snap.error}');
            result = const Center(child: Text('Something went wrong'));
          }

          return result;
        });
  }

  Widget _buildVideoPlayerTest() {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(_src));
    // video compressor - https://www.freeconvert.com/video-compressor

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
      _videoPlayerController!.value.aspectRatio;
    }

    return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio, child: VideoPlayer(_videoPlayerController!));
  }

  // * Logic

  Future<File> _fetchFile(final bool isImage) async {
    final dir = await getTemporaryDirectory();
    _src = _sanitiseSrc();
    final String type = isImage ? '.png' : '.mp4';
    final String tmpPath = '${dir.path}/tmp$type';
    final File tmp = File(tmpPath);
    final response = await http.get(Uri.parse(_src));
    return await tmp.writeAsBytes(response.bodyBytes);
  }

  void _onSaveClick() {
    DialogManager.showConfirmationDialog(context: context, title: 'Save Media', content: 'Are you sure?')
        .then((confirmation) {
      if (confirmation) {
        widget.eventContext.media.addMediaFile({'title': '', 'src': _src, 'type': _isVideo ? 'vid' : 'img'});
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
      _src = '';
      _tmpFile = null;
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
      DialogManager.showAlertDialog(
          context: context,
          title: 'Error',
          content:
              'That link does not work. Make sure to set file as video if you are expecting one, otherwise please check your link again.');
      setState(() {
        _canSave = false;
        _isTesting = false;
      });
    });
  }

  String _sanitiseSrc() {
    RegExpMatch? match = _driveRegExp.firstMatch(_tecSrc.text.trim());
    if (match != null) {
      String id = match.group(1)!;
      debugPrint('Link is a GoogleDrive Share link. Parsing now. ID is $id');
      return 'https://drive.google.com/uc?id=$id';
    }
    return _tecSrc.text.trim();
  }

  void _showHelp() {
    DialogManager.showAlertDialog(
        context: context,
        title: 'Adding Media Files',
        content:
            'Please provide web links to the media file you want.\n\nWhen providing specific/personal media file please upload these to your Google Drive, change the access to public (anyone with the link), and paste that link here\n\nMax image size is 100 KB and 128 MB for videos');
  }
}
