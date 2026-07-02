import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/theme/app_theme.dart';

class ShelfVisionProScreen extends StatefulWidget {
  const ShelfVisionProScreen({super.key});

  @override
  State<ShelfVisionProScreen> createState() => _ShelfVisionProScreenState();
}

class _ShelfVisionProScreenState extends State<ShelfVisionProScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;
  List<dynamic> _detectedBooks = [];

  Future<void> _captureAndProcess() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048, // Higher res for batch detection
      imageQuality: 90,
    );

    if (image == null) return;

    setState(() {
      _isScanning = true;
      _detectedBooks = [];
    });

    try {
      final repository = context.read<BookRepository>();
      // In a real scenario, you'd upload the file to GCS first.
      // For now, we pass the local path as the URI.
      final results = await repository.batchProcessShelf(image.path);

      setState(() {
        _detectedBooks = results;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch scan failed: $e')),
        );
      }
    }
  }

  Future<void> _saveAll() async {
    if (_detectedBooks.isEmpty) return;

    final repository = context.read<BookRepository>();
    final List<BookModel> booksToSave = _detectedBooks.map((data) {
      return BookModel(
        isbn: data['isbn'] ?? 'Unknown',
        title: data['title'] ?? 'Untitled Detected Book',
        author: data['author'] ?? 'Unknown',
        dateSourced: DateTime.now(),
      );
    }).toList();

    await repository.saveBooks(booksToSave);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${booksToSave.length} books to Library')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShelfVision Pro: Batch Scan'),
        backgroundColor: AppTheme.primaryPurple,
        actions: [
          if (_detectedBooks.isNotEmpty)
            TextButton(
              onPressed: _saveAll,
              child: const Text(
                'SAVE ALL',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isScanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.secondaryTeal),
                  SizedBox(height: 16),
                  Text('AI is detecting spines... please wait.'),
                ],
              ),
            )
          : _detectedBooks.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
      floatingActionButton: !_isScanning
          ? FloatingActionButton.large(
              onPressed: _captureAndProcess,
              backgroundColor: AppTheme.secondaryTeal,
              child: const Icon(Icons.camera_enhance, size: 40),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_module, size: 80, color: AppTheme.secondaryTeal),
            const SizedBox(height: 20),
            Text(
              'Scan hundreds of spines in a single photo.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'AI Object Detection Active. Capture the whole shelf to begin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _detectedBooks.length,
      itemBuilder: (context, index) {
        final book = _detectedBooks[index];
        return ListTile(
          leading: const Icon(Icons.book, color: AppTheme.primaryPurple),
          title: Text(book['title'] ?? 'Unknown Title'),
          subtitle: Text(book['author'] ?? 'Unknown Author'),
          trailing: const Icon(Icons.check_circle_outline, color: AppTheme.secondaryTeal),
        );
      },
    );
  }
}