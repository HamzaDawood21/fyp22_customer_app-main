import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/shims/dart_ui_real.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import '../Helper/vimeoplayer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../Helper/Session.dart';
import 'HomePage.dart';

class ProductPreview extends StatefulWidget {
  final int? pos, secPos, index;
  final bool? list, from;
  final String? id, video, videoType;
  final List<String?>? imgList;

  const ProductPreview(
      {Key? key,
      this.pos,
      this.secPos,
      this.index,
      this.list,
      this.id,
      this.imgList,
      this.video,
      this.videoType,
      this.from})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StatePreview();
}

class StatePreview extends State<ProductPreview> {
  int? curPos;
  YoutubePlayerController? _controller;
  VideoPlayerController? _videoController;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();

    if (widget.from! && widget.videoType == "youtube") {
      _controller = YoutubePlayerController(
        initialVideoId: YoutubePlayer.convertUrlToId(widget.video!)!,
        flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            forceHD: false,
            loop: false,
            disableDragSeek: true),
      );
    } else if (widget.from! &&
        widget.videoType == "self_hosted" &&
        widget.video != "") {
      _videoController = VideoPlayerController.network(
        widget.video!,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
        ),
      );

      _videoController!.addListener(() {
        setState(() {});
      });
      _videoController!.setLooping(false);
      _videoController!.initialize();
    }

    curPos = widget.pos;
    _pageController = PageController(initialPage: widget.pos!);
  }

  @override
  void dispose() {
    super.dispose();
    if (_controller != null) _controller!.dispose();
    if (_videoController != null) _videoController!.dispose();
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    if (_controller != null) _controller!.pause();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Hero(
      tag: widget.list!
          ? "${widget.id}"
          : "${sectionList[widget.secPos!].productList![widget.index!].id}${widget.secPos}${widget.index}",
      child: Stack(
        children: <Widget>[
          widget.video == ""
              ? Container(
                  child: PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    return PhotoViewGalleryPageOptions(
                        initialScale: PhotoViewComputedScale.covered,
                        minScale: PhotoViewComputedScale.contained * 0.9,
                        imageProvider: NetworkImage(widget.imgList![index]!));
                  },
                  itemCount: widget.imgList!.length,
                  loadingBuilder: (context, event) => Center(
                    child: SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        value: event == null
                            ? 0
                            : event.cumulativeBytesLoaded /
                                event.expectedTotalBytes!,
                      ),
                    ),
                  ),
                  backgroundDecoration:
                      BoxDecoration(color: Theme.of(context).colorScheme.white),
                  pageController: _pageController,
                  onPageChanged: (index) {
                    if (mounted)
                      setState(() {
                        curPos = index;
                      });
                  },
                ))
              : PageView.builder(
                  itemCount: widget.imgList!.length,
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (mounted)
                      setState(() {
                        curPos = index;
                      });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 1 &&
                        widget.from! &&
                        widget.videoType != null &&
                        widget.video != "") {
                      if (widget.videoType == "youtube") {
                        _controller!.reset();
                        return SafeArea(
                          child: YoutubePlayer(
                            controller: _controller!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor:
                                Theme.of(context).colorScheme.fontColor,
                            liveUIColor: colors.primary,
                          ),
                        );
                      } else if (widget.videoType == "vimeo") {
                        List<String> id =
                            widget.video!.split("https://vimeo.com/");
                        return SafeArea(
                          child: SizedBox(
                            width: double.maxFinite,
                            height: double.maxFinite,
                            child: Center(
                              child: VimeoPlayer(
                                id: id[1],
                                autoPlay: true,
                                looping: false,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: <Widget>[
                                    VideoPlayer(
                                      _videoController!,
                                    ),
                                    _ControlsOverlay(
                                      controller: _videoController,
                                    ),
                                    VideoProgressIndicator(
                                      _videoController!,
                                      allowScrubbing: true,
                                    ),
                                  ],
                                ),
                              )
                            : Container();
                      }
                    }

                    return PhotoView(
                        backgroundDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white),
                        initialScale: PhotoViewComputedScale.covered,
                        minScale: PhotoViewComputedScale.contained * 0.9,
                        gaplessPlayback: false,
                        customSize: MediaQuery.of(context).size,
                        imageProvider: NetworkImage(widget.imgList![index]!));
                  }),
          //
          //Back button
          Positioned.directional(
              textDirection: Directionality.of(context),
              top: 39.0,
              start: 11.0,
              child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x1a0400ff),
                                offset: Offset(0, 0),
                                blurRadius: 30)
                          ],
                          color: Theme.of(context).colorScheme.white,
                          borderRadius: BorderRadius.circular(7)),
                      width: 33,
                      height: 33,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ))),
          curPos != 0
              ? Positioned.directional(
                  start: 10,
                  top: MediaQuery.of(context).size.height * 0.45,
                  textDirection: Directionality.of(context),
                  child: ClipRRect(
                    clipBehavior: Clip.hardEdge,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10.0,
                        sigmaY: 10.0,
                      ),
                      child: Container(
                        height: 60,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: Colors.white.withOpacity(0.5),
                        ),
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_outlined),
                            onPressed: () {
                              setState(() {
                                _pageController!.animateToPage((curPos! - 1),
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.linear);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ))
              : Container(),
          curPos != (widget.imgList!.length - 1)
              ? Positioned.directional(
                  textDirection: Directionality.of(context),
                  end: 10,
                  top: MediaQuery.of(context).size.height * 0.45,
                  child: ClipRRect(
                    clipBehavior: Clip.hardEdge,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: 10.0,
                          sigmaY: 10.0,
                          ),
                      child: Container(
                        height: 60,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: Colors.white.withOpacity(0.5),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_outlined),
                          onPressed: () {
                            setState(() {
                              _pageController!.animateToPage((curPos! + 1),
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.linear);
                            });
                          },
                        ),
                      ),
                    ),
                  ))
              : Container(),
          Positioned.directional(
              textDirection: Directionality.of(context),
              bottom: 10.0,
              start: 25.0,
              end: 25.0,
              child: SelectedPhoto(
                numberOfDots: widget.imgList!.length,
                photoIndex: curPos,
              )),
        ],
      ),
    ));
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({Key? key, this.controller}) : super(key: key);

  static const _examplePlaybackRates = [
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller!.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller!.value.isPlaying
                ? controller!.pause()
                : controller!.play();
          },
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller!.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (speed) {
              controller!.setPlaybackSpeed(speed);
            },
            itemBuilder: (context) {
              return [
                for (final speed in _examplePlaybackRates)
                  PopupMenuItem(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller!.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}

class SelectedPhoto extends StatelessWidget {
  final int? numberOfDots;
  final int? photoIndex;

  SelectedPhoto({this.numberOfDots, this.photoIndex});

  Widget _inactivePhoto() {
    return Container(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 3.0, end: 3.0),
        child: Container(
          height: 8.0,
          width: 8.0,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  Widget _activePhoto() {
    return Container(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
        child: Container(
          height: 10.0,
          width: 10.0,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(5.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                spreadRadius: 0.0,
                blurRadius: 2.0,
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDots() {
    List<Widget> dots = [];
    for (int i = 0; i < numberOfDots!; i++) {
      dots.add(i == photoIndex ? _activePhoto() : _inactivePhoto());
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildDots(),
      ),
    );
  }
}