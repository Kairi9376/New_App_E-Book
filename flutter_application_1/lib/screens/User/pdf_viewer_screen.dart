import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_config.dart';
import '../../services/api_service.dart';

// Conditional imports for Web platform view registration
import 'dart:html' as html;
import 'dart:ui' as ui;

class PdfViewerScreen extends StatefulWidget {
  final String? bookId;
  final String pdfUrl;
  final String bookTitle;
  final String? author;
  final String? description;
  final int? pageCount;
  final int initialPage;

  const PdfViewerScreen({
    super.key,
    this.bookId,
    required this.pdfUrl,
    required this.bookTitle,
    this.author,
    this.description,
    this.pageCount,
    this.initialPage = 1,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late String _fullPdfUrl;
  late String _viewTypeId;
  int _currentPage = 1;
  int _totalPages = 1;
  double _zoomScale = 1.0; // Zoom multiplier (1.0 = 100%, 1.25 = 125%, 1.5 = 150%)
  bool _isDarkMode = true;
  bool _isLoading = true;

  StreamSubscription<html.MessageEvent>? _messageSubscription;
  final TextEditingController _jumpPageController = TextEditingController();
  final ScrollController _pageChipsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage > 0 ? widget.initialPage : 1;
    _totalPages = widget.pageCount != null && widget.pageCount! > 0 ? widget.pageCount! : 1;
    _normalizePdfUrl();
    _listenToWebMessages();
    _registerWebIframe();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _listenToWebMessages() {
    if (kIsWeb) {
      _messageSubscription = html.window.onMessage.listen((event) {
        if (event.data is Map) {
          final data = event.data as Map;
          if (data['type'] == 'pdf_page_count' && data['totalPages'] != null) {
            final realTotal = int.tryParse(data['totalPages'].toString());
            if (realTotal != null && realTotal > 0 && mounted) {
              setState(() {
                _totalPages = realTotal;
                if (_currentPage > _totalPages) {
                  _currentPage = _totalPages;
                }
              });
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _jumpPageController.dispose();
    _pageChipsScrollController.dispose();
    super.dispose();
  }

  void _normalizePdfUrl() {
    String url = widget.pdfUrl;
    if (url.isEmpty || url == 'assets/sample_book.pdf') {
      url = '${ApiConfig.uploadsBaseUrl}/sample_book.pdf';
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('uploads/') || url.startsWith('/uploads/')) {
        url = '${ApiConfig.uploadsBaseUrl}/${url.replaceAll(RegExp(r'^/?uploads/'), '')}';
      } else {
        url = '${ApiConfig.baseUrl}/$url';
      }
    }
    _fullPdfUrl = url;
  }

  String _buildSinglePageHtml(String pdfUrl, int pageNum, double zoomLevel) {
    final bgColor = _isDarkMode ? '#0F172A' : '#F8FAFC';
    final textColor = _isDarkMode ? '#94A3B8' : '#475569';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: $bgColor;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      width: 100vw;
      overflow: auto;
      font-family: system-ui, -apple-system, sans-serif;
    }
    #page-card {
      position: relative;
      box-shadow: 0 25px 30px -5px rgba(0, 0, 0, 0.4), 0 15px 15px -5px rgba(0, 0, 0, 0.3);
      border-radius: 8px;
      overflow: hidden;
      background: white;
      margin: auto;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    #pdf-canvas {
      display: block;
      margin: 0 auto;
      image-rendering: -webkit-optimize-contrast;
      image-rendering: crisp-edges;
      text-rendering: optimizeLegibility;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }
    #loading-text {
      position: absolute;
      color: $textColor;
      font-size: 14px;
      font-weight: 600;
      padding: 16px;
      text-align: center;
    }
    .error-box {
      color: #EF4444;
      font-size: 14px;
      text-align: center;
    }
  </style>
</head>
<body>
  <div id="page-card">
    <div id="loading-text">ກຳລັງໂຫຼດໜ້າ Ultra HD $pageNum...</div>
    <canvas id="pdf-canvas"></canvas>
  </div>

  <script>
    pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';
    
    var url = '$pdfUrl';
    var pageNum = $pageNum;
    var userZoom = $zoomLevel;
    var canvas = document.getElementById('pdf-canvas');
    var ctx = canvas.getContext('2d', { alpha: false });
    var loadingEl = document.getElementById('loading-text');

    pdfjsLib.getDocument({ url: url, withCredentials: false }).promise.then(function(pdfDoc) {
      try {
        window.parent.postMessage({ type: 'pdf_page_count', totalPages: pdfDoc.numPages, pageNum: pageNum }, '*');
      } catch (e) {}

      var targetPage = pageNum;
      if (targetPage > pdfDoc.numPages) targetPage = pdfDoc.numPages;
      if (targetPage < 1) targetPage = 1;

      pdfDoc.getPage(targetPage).then(function(page) {
        var dpr = window.devicePixelRatio || 1;
        
        // 1. Base unscaled page viewport (Scale 1.0)
        var unscaledViewport = page.getViewport({ scale: 1.0 });

        // 2. Responsive CSS display bounds to fit container perfectly
        var screenW = window.innerWidth || document.documentElement.clientWidth || 800;
        var screenH = window.innerHeight || document.documentElement.clientHeight || 900;
        var targetCssW = screenW * 0.94;
        var targetCssH = screenH * 0.86;

        var scaleX = targetCssW / unscaledViewport.width;
        var scaleY = targetCssH / unscaledViewport.height;
        var baseFitScale = Math.min(scaleX, scaleY);
        if (baseFitScale <= 0 || isNaN(baseFitScale)) baseFitScale = 1.0;

        // Apply zoom multiplier
        var cssScale = baseFitScale * userZoom;
        var cssViewport = page.getViewport({ scale: cssScale });

        // 3. Ultra HD Canvas Resolution Buffer (3.5x Multiplier for razor-sharp vector text rendering)
        var hdQualityMultiplier = Math.max(3.5, dpr * 3.0);
        var renderViewport = page.getViewport({ scale: cssScale * hdQualityMultiplier });

        // Set High-DPI canvas buffer resolution
        canvas.width = Math.floor(renderViewport.width);
        canvas.height = Math.floor(renderViewport.height);
        
        // Set CSS display dimensions
        canvas.style.width = Math.floor(cssViewport.width) + "px";
        canvas.style.height = Math.floor(cssViewport.height) + "px";

        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';

        var renderContext = {
          canvasContext: ctx,
          viewport: renderViewport
        };
        
        var renderTask = page.render(renderContext);
        renderTask.promise.then(function() {
          if (loadingEl) loadingEl.style.display = 'none';
        }).catch(function(err) {
          if (loadingEl) {
            loadingEl.className = 'error-box';
            loadingEl.innerText = 'ບໍ່ສາມາດສະແດງຜົນໜ້າ PDF ນີ້ໄດ້: ' + err.message;
          }
        });
      }).catch(function(err) {
        if (loadingEl) {
          loadingEl.className = 'error-box';
          loadingEl.innerText = 'ບໍ່ມີໜ້າທີ ' + pageNum + ' ໃນໄຟລ໌ PDF (ມີທັງໝົດ ' + pdfDoc.numPages + ' ໜ້າ)';
        }
      });
    }).catch(function(err) {
      if (loadingEl) {
        loadingEl.className = 'error-box';
        loadingEl.innerText = 'ບໍ່ສາມາດໂຫຼດໄຟລ໌ PDF ຕົ້ນສະບັບໄດ້ (' + err.message + ')';
      }
    });
  </script>
</body>
</html>
''';
  }

  void _registerWebIframe() {
    if (kIsWeb) {
      _viewTypeId = 'pdf-view-${DateTime.now().microsecondsSinceEpoch}';
      try {
        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(
          _viewTypeId,
          (int id) {
            final iframe = html.IFrameElement()
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%'
              ..style.pointerEvents = 'auto';

            iframe.srcdoc = _buildSinglePageHtml(_fullPdfUrl, _currentPage, _zoomScale);
            return iframe;
          },
        );
      } catch (e) {
        debugPrint('Platform view registration info: $e');
      }
    }
  }

  Future<void> _openExternalPdf() async {
    final uri = Uri.parse(_fullPdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ເປີດ URL: $_fullPdfUrl'), backgroundColor: AppColors.primary),
        );
      }
    }
  }

  void _changePage(int newPage) {
    if (newPage >= 1 && newPage <= _totalPages) {
      setState(() {
        _currentPage = newPage;
        _isLoading = true;
        _registerWebIframe();
      });

      // Record reading history in MySQL backend
      final targetBookId = widget.bookId ?? '1';
      ApiService.recordReadingHistory(
        bookId: targetBookId,
        lastPageRead: newPage,
        totalPages: _totalPages,
      );

      // Auto-scroll chip bar to current page
      if (_pageChipsScrollController.hasClients) {
        final double targetOffset = ((newPage - 1) * 65.0).clamp(0.0, _pageChipsScrollController.position.maxScrollExtent);
        _pageChipsScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  void _setZoom(double newZoom) {
    setState(() {
      _zoomScale = newZoom.clamp(0.75, 2.5);
      _isLoading = true;
      _registerWebIframe();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _setIframePointerEvents(bool enabled) {
    if (kIsWeb) {
      try {
        final iframes = html.document.querySelectorAll('iframe');
        for (var el in iframes) {
          (el as html.IFrameElement).style.pointerEvents = enabled ? 'auto' : 'none';
        }
      } catch (_) {}
    }
  }

  /// Opens Interactive Page Selector Dialog (ເລືອກໜ້າ Page 1, Page 2, Page 3 ... Page N ...)
  void _openPageSelectorModal() {
    _jumpPageController.text = _currentPage.toString();
    _setIframePointerEvents(false);

    int selectedTab = 0; // 0 = Page List (1..N), 1 = Page Grid

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E293B),
              elevation: 24,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 540,
                height: 520,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'ເລືອກໜ້າອ່ານ PDF (Page 1..N)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () {
                            _setIframePointerEvents(true);
                            Navigator.pop(dialogCtx);
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 16),

                    // Direct Jump Input Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.find_in_page_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          const Text('ໄປຫາໜ້າທີ:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 75,
                            height: 36,
                            child: TextField(
                              controller: _jumpPageController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                fillColor: const Color(0xFF0F172A),
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('/ $_totalPages', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              final target = int.tryParse(_jumpPageController.text.trim());
                              if (target != null && target >= 1 && target <= _totalPages) {
                                _setIframePointerEvents(true);
                                Navigator.pop(dialogCtx);
                                _changePage(target);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('ກະລຸນາປ້ອນໜ້າ 1 ຫາ $_totalPages'), backgroundColor: Colors.orange),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text('ໄປໜ້ານີ້'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // View Mode Switcher: List View vs Grid View
                    Row(
                      children: [
                        ChoiceChip(
                          selected: selectedTab == 0,
                          label: const Text('ລາຍການໜ້າ (List View)'),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: selectedTab == 0 ? Colors.white : Colors.white70, fontSize: 12),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedTab = 0);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          selected: selectedTab == 1,
                          label: const Text('ຕາຕະລາງໜ້າ (Grid View)'),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: selectedTab == 1 ? Colors.white : Colors.white70, fontSize: 12),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedTab = 1);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pages Content
                    Expanded(
                      child: selectedTab == 0
                          ? ListView.separated(
                              itemCount: _totalPages,
                              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                              itemBuilder: (ctx, idx) {
                                final pageNum = idx + 1;
                                final isCurrent = pageNum == _currentPage;

                                return ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  tileColor: isCurrent ? AppColors.primary.withOpacity(0.25) : Colors.transparent,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isCurrent ? AppColors.primary : const Color(0xFF334155),
                                    child: Text(
                                      '$pageNum',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : Colors.white70),
                                    ),
                                  ),
                                  title: Text(
                                    'ໜ້າທີ $pageNum ຂອງ PDF (Page $pageNum)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      color: isCurrent ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                  trailing: isCurrent
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                                          child: const Text('ໜ້າປະຈຸບັນ', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                        )
                                      : const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
                                  onTap: () {
                                    _setIframePointerEvents(true);
                                    Navigator.pop(dialogCtx);
                                    _changePage(pageNum);
                                  },
                                );
                              },
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                childAspectRatio: 1.3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _totalPages,
                              itemBuilder: (ctx, idx) {
                                final pageNum = idx + 1;
                                final isCurrent = pageNum == _currentPage;

                                return InkWell(
                                  onTap: () {
                                    _setIframePointerEvents(true);
                                    Navigator.pop(dialogCtx);
                                    _changePage(pageNum);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    decoration: BoxDecoration(
                                      color: isCurrent ? AppColors.primary : const Color(0xFF334155),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isCurrent ? Colors.white : Colors.transparent, width: 1.5),
                                      boxShadow: isCurrent
                                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$pageNum',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isCurrent ? Colors.white : Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            'ໜ້າ $pageNum',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: isCurrent ? Colors.white70 : Colors.white54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _setIframePointerEvents(true);
    });
  }

  /// Opens Book Basic Info Preview Modal
  void _openBookInfoModal() {
    _setIframePointerEvents(false);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 24,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: 8),
                        Text('ຂໍ້ມູນພື້ນຖານຂອງປຶ້ມ (Book Info)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () {
                        _setIframePointerEvents(true);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),

                Text('ຊື່ປຶ້ມ: ${widget.bookTitle}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('ນັກຂຽນ: ${widget.author ?? "ບໍ່ລະບຸ"}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 6),
                Text('ຈຳນວນໜ້າທັງໝົດໃນ PDF: $_totalPages ໜ້າ', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 14),

                const Text('ເນື້ອເລື່ອງຫຍໍ້ (Synopsis):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 6),
                Text(
                  widget.description != null && widget.description!.isNotEmpty
                      ? widget.description!
                      : 'ບໍ່ມີເນື້ອເລື່ອງຫຍໍ້ ສຳລັບປຶ້ມເລື່ອງນີ້',
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      _setIframePointerEvents(true);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('ປິດ'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _setIframePointerEvents(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final zoomPercent = (_zoomScale * 100).round();

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'ນັກຂຽນ: ${widget.author ?? "ບໍ່ລະບຸ"} | ໜ້າ PDF: $_currentPage / $_totalPages | HD $zoomPercent%',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Zoom Out Button
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded, color: Colors.white70),
            tooltip: 'ຍໍ້ໜ້າ PDF (Zoom Out)',
            onPressed: _zoomScale > 0.75 ? () => _setZoom(_zoomScale - 0.25) : null,
          ),
          // Zoom Level Indicator Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$zoomPercent%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // Zoom In Button
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded, color: Colors.white),
            tooltip: 'ຂະຫຍາຍໜ້າ PDF (Zoom In HD)',
            onPressed: _zoomScale < 2.5 ? () => _setZoom(_zoomScale + 0.25) : null,
          ),
          const SizedBox(width: 4),

          // Native Flutter Dropdown in AppBar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _currentPage > _totalPages ? _totalPages : _currentPage,
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.amber),
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                items: List.generate(_totalPages, (i) => i + 1).map((pNum) {
                  return DropdownMenuItem<int>(
                    value: pNum,
                    child: Text('ໜ້າ $pNum / $_totalPages', style: TextStyle(color: pNum == _currentPage ? Colors.amber : Colors.white, fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _changePage(val);
                },
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Select Page Modal Button
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Colors.amber),
            tooltip: 'ເລືອກໜ້າ PDF (Page 1..N)',
            onPressed: _openPageSelectorModal,
          ),
          // Book Info Preview Button
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent),
            tooltip: 'ຂໍ້ມູນພື້ນຖານປຶ້ມ',
            onPressed: _openBookInfoModal,
          ),
          // Dark/Light Theme Toggle
          IconButton(
            icon: Icon(_isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: Colors.white),
            tooltip: 'ປ່ຽນໂໝດມຶດ/ສະຫວ່າງ',
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
                _registerWebIframe();
              });
            },
          ),
          // Open Full PDF File
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
            tooltip: 'ເປີດໄຟລ໌ PDF ເຕັມ',
            onPressed: _openExternalPdf,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Reader Header Indicator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ສະແດງເນື້ອຫາໄຟລ໌ PDF (Ultra HD): ໜ້າທີ $_currentPage / $_totalPages',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _openPageSelectorModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grid_view_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'ເລືອກໜ້າ PDF: $_currentPage / $_totalPages',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Single-Page Viewport Canvas
          Expanded(
            child: kIsWeb
                ? Stack(
                    children: [
                      // HTML Canvas Single Page Viewer
                      SizedBox.expand(
                        child: HtmlElementView(
                          key: ValueKey(_viewTypeId),
                          viewType: _viewTypeId,
                        ),
                      ),
                      // Smooth Loading Overlay
                      if (_isLoading)
                        Container(
                          color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: AppColors.primary),
                                const SizedBox(height: 16),
                                Text(
                                  'ກຳລັງໂຫຼດໜ້າທີ $_currentPage (Ultra HD)...',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, size: 80, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(widget.bookTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87)),
                        const SizedBox(height: 8),
                        Text('ໜ້າທີ $_currentPage ຈາກທັງໝົດ $_totalPages ໜ້າ (PDF File)', style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _openExternalPdf,
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('ເປີດ PDF ໃນ Browser'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
          ),

          // ALWAYS-ACCESSIBLE HORIZONTAL PAGE CHIPS BAR
          Container(
            height: 44,
            color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              controller: _pageChipsScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _totalPages,
              itemBuilder: (context, index) {
                final pageNum = index + 1;
                final isCurrent = pageNum == _currentPage;

                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => _changePage(pageNum),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary : (_isDarkMode ? const Color(0xFF334155) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : (_isDarkMode ? Colors.white24 : Colors.grey.shade300),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'ໜ້າ $pageNum',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Single-Page Navigation Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              border: Border(top: BorderSide(color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Previous Page Button
                ElevatedButton.icon(
                  onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                  label: const Text('ໜ້າກ່ອນ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(width: 10),

                // Page Progress & Indicator
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ໜ້າ PDF: $_currentPage / $_totalPages ($zoomPercent%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _currentPage / _totalPages,
                          minHeight: 5,
                          backgroundColor: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Page Grid Selector Modal Trigger Button
                IconButton(
                  icon: const Icon(Icons.grid_view_rounded, color: AppColors.primary),
                  tooltip: 'ເລືອກໜ້າດ່ວນ (Page 1..N)',
                  onPressed: _openPageSelectorModal,
                ),
                const SizedBox(width: 6),

                // Next Page Button
                ElevatedButton.icon(
                  onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  label: const Text('ໜ້າຖັດໄປ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
