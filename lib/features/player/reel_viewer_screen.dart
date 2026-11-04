import 'package:flutter/material.dart';
import '../../api/models/models.dart';
import '../../theme/app_theme.dart';
import 'video_reel_item.dart';

class ReelViewerScreen extends StatefulWidget {
  final List<VideoJob> videos;
  final int initialIndex;

  const ReelViewerScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  @override
  State<ReelViewerScreen> createState() => _ReelViewerScreenState();
}

class _ReelViewerScreenState extends State<ReelViewerScreen> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextVideo() {
    if (_currentPage + 1 < widget.videos.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.reelBackground,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final isWithinRange = (index - _currentPage).abs() <= 1;
              if (!isWithinRange) {
                return Container(color: AppColors.reelBackground);
              }
              return VideoReelItem(
                key: ValueKey(widget.videos[index].jobId),
                video: widget.videos[index],
                isActive: TickerMode.valuesOf(context).enabled &&
                    index == _currentPage,
                hasNextVideo: index < widget.videos.length - 1,
                onNextVideo: _goToNextVideo,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
