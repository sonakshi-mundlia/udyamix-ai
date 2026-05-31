import 'package:flutter/material.dart';

class ScrollSpyPage extends StatefulWidget {
  final String pageTitle;
  final List<String> titles;
  final List<Widget> sections;

  final int initialIndex; // 🔥 NEW

  const ScrollSpyPage({
    super.key,
    required this.pageTitle,
    required this.titles,
    required this.sections,
    this.initialIndex = 0, // 🔥 NEW
  });

  @override
  State<ScrollSpyPage> createState() => _ScrollSpyPageState();
}

class _ScrollSpyPageState extends State<ScrollSpyPage> {
  final ScrollController _controller = ScrollController();
  final List<GlobalKey> _keys = [];

  int activeIndex = 0;

  @override
  void initState() {
    super.initState();

    _keys.addAll(List.generate(widget.sections.length, (_) => GlobalKey()));
    _controller.addListener(_onScroll);

    /// 🔥 AUTO SCROLL TO SELECTED SECTION
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollTo(widget.initialIndex);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    for (int i = 0; i < _keys.length; i++) {
      final context = _keys[i].currentContext;

      if (context != null) {
        final box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero).dy;

        if (position < 150) {
          if (activeIndex != i) {
            setState(() {
              activeIndex = i;
            });
          }
        }
      }
    }
  }

  void _scrollTo(int index) {
    if (index < 0 || index >= _keys.length) return;

    final context = _keys[index].currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  /// 🔥 HEADER
  Widget _buildHeader(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(widget.titles.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("|",
                        style: TextStyle(color: Colors.grey)),
                  );
                } else {
                  final sectionIndex = index ~/ 2;
                  final isActive = activeIndex == sectionIndex;

                  return GestureDetector(
                    onTap: () => _scrollTo(sectionIndex),
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        widget.titles[sectionIndex],
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: isActive
                              ? Colors.blue
                              : Colors.black87,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          decoration: isActive
                              ? TextDecoration.underline
                              : null,
                          decorationColor: Colors.blue,
                        ),
                      ),
                    ),
                  );
                }
              }),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 SECTION
  Widget _buildSection(int index, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Container(
          key: _keys[index],
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            children: [
              if (index != 0)
                const Divider(height: 40, thickness: 1),
              widget.sections[index],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Scaffold(
      backgroundColor: Colors.white,

      /// 🔝 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.pageTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          /// 🔥 NAV HEADER
          _buildHeader(isMobile),

          const Divider(height: 1),

          /// 🔥 CONTENT
          Expanded(
            child: SingleChildScrollView(
              controller: _controller,
              child: Column(
                children: List.generate(
                  widget.sections.length,
                      (index) => _buildSection(index, isMobile),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
