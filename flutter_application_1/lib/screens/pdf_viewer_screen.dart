import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/api_config.dart';

// Conditional imports for Web platform view registration
import 'dart:html' as html;
import 'dart:ui' as ui;

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String bookTitle;
  final String? author;
  final String? description;
  final int? pageCount;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.bookTitle,
    this.author,
    this.description,
    this.pageCount,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late String _fullPdfUrl;
  late String _viewTypeId;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _useGoogleDocsViewer = false;
  bool _isDarkMode = true;
  bool _isLoading = true;

  final TextEditingController _jumpPageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _totalPages = widget.pageCount != null && widget.pageCount! > 0 ? widget.pageCount! : 24;
    _normalizePdfUrl();
    _registerWebIframe();

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _jumpPageController.dispose();
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

  String _buildSinglePageHtml(String pdfUrl, int pageNum) {
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
      overflow: hidden;
      font-family: system-ui, -apple-system, sans-serif;
    }
    #page-card {
      position: relative;
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.4), 0 10px 10px -5px rgba(0, 0, 0, 0.3);
      border-radius: 8px;
      overflow: hidden;
      background: white;
      max-width: 94vw;
      max-height: 84vh;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    #pdf-canvas {
      display: block;
      max-width: 94vw;
      max-height: 84vh;
      width: auto;
      height: auto;
      object-fit: contain;
    }
    #loading-text {
      position: absolute;
      color: $textColor;
      font-size: 14px;
      font-weight: 600;
    }
  </style>
</head>
<body>
  <div id="page-card">
    <div id="loading-text">ກຳລັງໂຫຼດໜ້າ $pageNum / $_totalPages...</div>
    <canvas id="pdf-canvas"></canvas>
  </div>

  <script>
    pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';
    
    var url = '$pdfUrl';
    var pageNum = $pageNum;
    var canvas = document.getElementById('pdf-canvas');
    var ctx = canvas.getContext('2d');
    var loadingEl = document.getElementById('loading-text');

    pdfjsLib.getDocument({ url: url, withCredentials: false }).promise.then(function(pdfDoc) {
      pdfDoc.getPage(pageNum).then(function(page) {
        var viewport = page.getViewport({ scale: 1.8 });
        canvas.height = viewport.height;
        canvas.width = viewport.width;

        var renderContext = {
          canvasContext: ctx,
          viewport: viewport
        };
        
        var renderTask = page.render(renderContext);
        renderTask.promise.then(function() {
          if (loadingEl) loadingEl.style.display = 'none';
        });
      });
    }).catch(function(err) {
      if (loadingEl) {
        loadingEl.innerText = 'ໜ້າ $pageNum (ເປີດໄຟລ໌ PDF ຕົ້ນສະບັບ)';
        loadingEl.style.color = '$textColor';
      }
    });
  </script>
</body>
</html>
''';
  }

  void _registerWebIframe() {
    if (kIsWeb) {
      _viewTypeId = 'pdf-single-page-view-${_fullPdfUrl.hashCode}-p$_currentPage-m$_isDarkMode-g$_useGoogleDocsViewer';
      try {
        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(
          _viewTypeId,
          (int id) {
            final iframe = html.IFrameElement()
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%';

            if (_useGoogleDocsViewer) {
              iframe.src = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(_fullPdfUrl)}#page=$_currentPage';
            } else {
              iframe.srcdoc = _buildSinglePageHtml(_fullPdfUrl, _currentPage);
            }

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
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  /// Opens Table of Contents (สารบัญ) & Quick Jump Modal
  void _openTableOfContentsModal() {
    _jumpPageController.text = _currentPage.toString();

    // Dynamically generated chapters based on total pages
    final chapters = [
      {'title': 'ບົດທີ 1: ບົດນຳ ແລະ ຂໍ້ມູນພື້ນຖານ', 'page': 1},
      {'title': 'ບົດທີ 2: ປະຫວັດ ແລະ ຄວາມເປັນມາ', 'page': (_totalPages * 0.15).round().clamp(1, _totalPages)},
      {'title': 'ບົດທີ 3: ເນື້ອຫາຫຼັກ ສ່ວນທີ 1', 'page': (_totalPages * 0.30).round().clamp(1, _totalPages)},
      {'title': 'ບົດທີ 4: ເນື້ອຫາຫຼັກ ສ່ວນທີ 2', 'page': (_totalPages * 0.50).round().clamp(1, _totalPages)},
      {'title': 'ບົດທີ 5: ເນື້ອຫາຫຼັກ ສ່ວນທີ 3', 'page': (_totalPages * 0.70).round().clamp(1, _totalPages)},
      {'title': 'ບົດທີ 6: ບົດສະຫຼຸບ ແລະ ຂໍ້ຄິດ', 'page': (_totalPages * 0.85).round().clamp(1, _totalPages)},
      {'title': 'ບົດທີ 7: ເອກະສານອ້າງອີງ', 'page': _totalPages},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.list_alt_rounded, color: AppColors.primary, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'ສາລະບານ & ໄປຫາໜ້າ (Table of Contents)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),

                  // Direct Jump to Page Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.find_in_page_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Text('ໄປຫາໜ້າທີ:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          height: 38,
                          child: TextField(
                            controller: _jumpPageController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
                              Navigator.pop(ctx);
                              _changePage(target);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ກະລຸນາປ້ອນໜ້າ 1 ถึง $_totalPages'), backgroundColor: Colors.orange),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('ໄປເລີຍ'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chapters List Title
                  const Text('ຕາຕະລາງເນື້ອຫາ / ບົດຮຽນ (Chapters):', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Chapters List
                  Expanded(
                    child: ListView.separated(
                      itemCount: chapters.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, idx) {
                        final ch = chapters[idx];
                        final pNum = ch['page'] as int;
                        final isCurrent = pNum == _currentPage;

                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: isCurrent ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isCurrent ? AppColors.primary : const Color(0xFF334155),
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : Colors.white70),
                            ),
                          ),
                          title: Text(
                            ch['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? Colors.white : Colors.white70,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.primary : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ໜ້າ $pNum',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _changePage(pNum);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Opens Book Basic Info Preview Modal
  void _openBookInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                      Text('ຂໍ້ມູນພື້ນຖານຂອງປຶ້ມ (Book Basic Info)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 16),

              Text('ຊື່ປຶ້ມ: ${widget.bookTitle}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              Text('ນັກຂຽນ: ${widget.author ?? "ບໍ່ລະບຸ"}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 6),
              Text('ຈຳນວນໜ້າທັງໝົດ: $_totalPages ໜ້າ', style: const TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 12),

              const Text('ເນື້ອເລື່ອງຫຍໍ້ (Synopsis):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(
                widget.description != null && widget.description!.isNotEmpty
                    ? widget.description!
                    : 'ບໍ່ມີເນື້ອເລື່ອງຫຍໍ້ ສຳລັບປຶ້ມເລື່ອງນີ້',
                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'ນັກຂຽນ: ${widget.author ?? "ບໍ່ລະບຸ"} | ໜ້າ $_currentPage / $_totalPages',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Table of Contents & Page Jump Button
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.amber),
            tooltip: 'ສາລະບານ & ໄປຫາໜ້າ',
            onPressed: _openTableOfContentsModal,
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
                const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ສະແດງເທື່ອລະໜ້າ (Single Page View): ໜ້າທີ $_currentPage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _openTableOfContentsModal,
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
                        const Icon(Icons.list_alt_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'ສາລະບານ: ໜ້າ $_currentPage / $_totalPages',
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
                          key: ValueKey('pdf-single-page-$_currentPage-$_isDarkMode-$_useGoogleDocsViewer'),
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
                                  'ກຳລັງໂຫຼດໜ້າທີ $_currentPage...',
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
                        Text('ໜ້າທີ $_currentPage ຈາກທັງໝົດ $_totalPages ໜ້າ', style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold)),
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
                        'ໜ້າ $_currentPage / $_totalPages',
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

                // Quick TOC Button
                IconButton(
                  icon: const Icon(Icons.grid_view_rounded, color: AppColors.primary),
                  tooltip: 'ເລືອກໜ້າດ່ວນ',
                  onPressed: _openTableOfContentsModal,
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
