import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../utility/app_context.dart';
import '../utility/network_image_helper.dart';

class MyUserAvatar extends StatefulWidget {
  const MyUserAvatar(this.user, {super.key, this.radius, this.tmpImageSrc});

  final User user;
  final double? radius;
  final String? tmpImageSrc;

  @override
  State<MyUserAvatar> createState() => _MyUserAvatarState();
}

class _MyUserAvatarState extends State<MyUserAvatar> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(covariant MyUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id ||
        oldWidget.user.imgSrc != widget.user.imgSrc ||
        oldWidget.tmpImageSrc != widget.tmpImageSrc) {
      _imageFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.tmpImageSrc != null || widget.user.imgSrc.isNotEmpty;
    if (!hasImage || _imageFailed) {
      return _buildTextAvatar();
    }
    return _buildImageAvatar(context);
  }

  Widget _buildImageAvatar(final BuildContext context) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final String? appDir = appContext.appDir;

    if (widget.tmpImageSrc != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(
          NetworkImageHelper.getImageUrl(widget.tmpImageSrc!),
        ),
        radius: widget.radius,
        onBackgroundImageError: _onImageError,
      );
    }

    if (appDir != null &&
        (appContext.currentUser.id != widget.user.id ||
            !appContext.useUserImageSrc)) {
      return _buildFileImage(appDir);
    }

    return CircleAvatar(
      backgroundImage: NetworkImage(
        NetworkImageHelper.getImageUrl(widget.user.imgSrc),
      ),
      radius: widget.radius,
      onBackgroundImageError: _onImageError,
    );
  }

  Widget _buildFileImage(final String appDir) {
    final double size = (widget.radius ?? 20) * 2;
    return FutureBuilder(
      future: _fetchFileImage(appDir),
      builder: (_, snap) {
        if (snap.hasData) {
          return CircleAvatar(
            backgroundImage: FileImage(snap.data!),
            radius: widget.radius,
            onBackgroundImageError: (exception, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _deleteFile(appDir);
              });
              _onImageError(exception, stackTrace);
            },
          );
        }
        if (snap.hasError) {
          debugPrint('ID ${widget.user.id} - user image error: ${snap.error}');
          _onImageError(snap.error!, snap.stackTrace);
          return _buildTextAvatar();
        }
        return SizedBox(
          width: size,
          height: size,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  Widget _buildTextAvatar() {
    return CircleAvatar(
      radius: widget.radius,
      child: Text(
        widget.user.initials,
        style: TextStyle(
          fontSize: widget.radius == null ? null : (widget.radius! * 0.7),
        ),
      ),
    );
  }

  void _onImageError(Object exception, StackTrace? stackTrace) {
    debugPrint('broken user image - ID ${widget.user.id}: $exception');
    if (!mounted || _imageFailed) return;
    // Defer setState — CircleAvatar may call this during layout/paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_imageFailed) {
        setState(() => _imageFailed = true);
      }
    });
  }

  Future<File> _fetchFileImage(final String appDir) async {
    final String filePath = '$appDir/user_imgs/${widget.user.id}.png';
    final File imgFile = File(filePath);

    if (!await imgFile.exists()) {
      debugPrint(
          'attempting to fetch image for user: ${widget.user.id} with file: $filePath');
      final response = await http.get(Uri.parse(widget.user.imgSrc));
      return await imgFile.writeAsBytes(response.bodyBytes);
    }
    return imgFile;
  }

  Future<void> _deleteFile(final String appDir) async {
    final String filePath = '$appDir/user_imgs/${widget.user.id}.png';
    final File imgFile = File(filePath);
    if (await imgFile.exists()) {
      debugPrint('deleting broken user image file - ID ${widget.user.id}');
      await imgFile.delete();
    }
  }
}
