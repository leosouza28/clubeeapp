import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PDFViewerModal extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PDFViewerModal({
    super.key,
    required this.pdfUrl,
    this.title = 'Visualizar PDF',
  });

  @override
  State<PDFViewerModal> createState() => _PDFViewerModalState();
}

class _PDFViewerModalState extends State<PDFViewerModal> {
  String? localPath;
  bool isLoading = true;
  String? error;
  int? pages = 0;
  int currentPage = 0;
  bool isReady = false;
  PDFViewController? controller;

  @override
  void initState() {
    super.initState();
    _downloadAndOpenPDF();
  }

  Future<void> _downloadAndOpenPDF() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Baixa o PDF
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        // Obtém o diretório temporário
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_carteirinha.pdf');

        // Salva o arquivo
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Erro ao baixar o PDF: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erro ao processar o PDF: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          actions: [
            if (pages != null && pages! > 1)
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${currentPage + 1} / $pages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando PDF...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _downloadAndOpenPDF,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (localPath == null) {
      return const Center(child: Text('Erro ao carregar o PDF'));
    }

    return Container(
      color: Colors.grey.shade200,
      child: PDFView(
        filePath: localPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: true,
        pageSnap: true,
        defaultPage: currentPage,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
        onRender: (pages) {
          setState(() {
            this.pages = pages;
            isReady = true;
          });
        },
        onError: (error) {
          setState(() {
            this.error = 'Erro ao renderizar PDF: $error';
          });
        },
        onPageError: (page, error) {
          setState(() {
            this.error = 'Erro na página $page: $error';
          });
        },
        onViewCreated: (PDFViewController pdfViewController) {
          controller = pdfViewController;
        },
        onLinkHandler: (String? uri) {
          // Handle link clicks if needed
        },
        onPageChanged: (int? page, int? total) {
          setState(() {
            currentPage = page ?? 0;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    // Limpa o arquivo temporário
    if (localPath != null) {
      final file = File(localPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    super.dispose();
  }
}
