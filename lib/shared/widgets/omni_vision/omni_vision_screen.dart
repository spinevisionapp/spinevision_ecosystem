import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/data/repositories/book_repository.dart';
import 'package:spinevision_ecosystem/shared/services/storage_service.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

enum OmniVisionMode { focus, batch, spatial }

class OmniVisionScreen extends StatefulWidget {
  const OmniVisionScreen({super.key});

  @override
  State<OmniVisionScreen> createState() => _OmniVisionScreenState();
}

class _OmniVisionScreenState extends State<OmniVisionScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  OmniVisionMode _currentMode = OmniVisionMode.focus;
  
  // TTS State
  final FlutterTts _tts = FlutterTts();
  bool _isVoiceEnabled = false;
  
  // Filtering State (Spatial)
  bool _highProfitOnly = false;
  
  // Device & Camera State
  bool _isTorchOn = false;
  double _currentZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  
  // Session Metrics & History
  double _sessionProfit = 0.0;
  int _sessionScanCount = 0;
  int _totalScansThisMonth = 0;
  final int _milestoneTarget = 50; // Pro Trial Target
  final List<Map<String, dynamic>> _scanHistory = [];
  
  // Analysis State
  bool _isProcessing = false;
  String _statusMessage = '';
  Map<String, dynamic>? _lastRecommendation;
  Map<String, dynamic>? _lastMetadata;
  
  // Animation for Laser
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  // Focus Mode State
  AnalysisStatus _focusStatus = AnalysisStatus.none;
  String _focusRationale = '';
  double _focusNet = 0.0;
  
  // Spatial Mode State
  final List<DetectedSpine> _spatialDetections = [];
  final Random _random = Random();
  Timer? _spatialTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTTS();
    _loadUserStats();
    
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _laserAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserStats() async {
    final repository = RepositoryProvider.of<BookRepository>(context);
    final stats = await repository.getUserStats();
    if (mounted) {
      setState(() {
        _totalScansThisMonth = stats['scans_this_month'] ?? 0;
      });
    }
  }

  Future<void> _initializeTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller!.initialize();
    
    await _initializeControllerFuture;
    
    if (mounted) {
      _maxZoomLevel = await _controller!.getMaxZoomLevel();
      _minZoomLevel = await _controller!.getMinZoomLevel();
      setState(() {});
    }
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final newTorchState = !_isTorchOn;
      await _controller!.setFlashMode(newTorchState ? FlashMode.torch : FlashMode.off);
      setState(() => _isTorchOn = newTorchState);
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint("Torch error: $e");
    }
  }

  Future<void> _handleZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final double newZoom = zoom.clamp(_minZoomLevel, _maxZoomLevel);
    await _controller!.setZoomLevel(newZoom);
    setState(() => _currentZoomLevel = newZoom);
  }

  void _switchMode(OmniVisionMode mode) {
    if (mode == _currentMode) return;
    
    final repository = RepositoryProvider.of<BookRepository>(context);
    final tier = repository.currentTier;

    if (mode == OmniVisionMode.batch && tier == 'Hobbyist') {
      _showUpgradeDialog('Pro');
      return;
    }
    if (mode == OmniVisionMode.spatial && tier != 'Enterprise') {
      _showUpgradeDialog('Enterprise');
      return;
    }

    if (_currentMode == OmniVisionMode.spatial) {
      _spatialTimer?.cancel();
      _spatialDetections.clear();
    }

    setState(() {
      _currentMode = mode;
      _isProcessing = false;
      _statusMessage = '';
      _focusStatus = AnalysisStatus.none;
    });

    if (mode == OmniVisionMode.spatial) {
      _startSpatialLoop();
    }
  }

  void _showUpgradeDialog(String requiredTier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to $requiredTier', style: AppTextStyles.headlineMedium),
        content: Text('This feature is exclusive to our $requiredTier members. Elevate your sourcing game today!', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('LATER', style: AppTextStyles.labelLarge.copyWith(color: AppColors.secondaryText))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/paywall');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text('UPGRADE NOW', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFocusTap() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;
    
    final repository = RepositoryProvider.of<BookRepository>(context);
    final storage = RepositoryProvider.of<CloudStorageService>(context);

    HapticFeedback.lightImpact();
    setState(() {
      _isProcessing = true;
      _focusStatus = AnalysisStatus.analyzing;
    });

    try {
      final xFile = await _controller!.takePicture();
      final gcsUri = await storage.uploadImage(File(xFile.path));
      
      if (gcsUri == null) throw Exception('Upload failed');

      final metadataResponse = await repository.getRecommendation(gcsUri, {}); 

      final recommendation = await repository.getRecommendation(
        gcsUri, 
        {'min_profit': 10.0, 'max_rank': 500000}
      );

      if (mounted) {
        final double profit = (recommendation['estimated_profit'] as num?)?.toDouble() ?? 0.0;
        final bool isBuy = recommendation['decision'] == 'buy';
        
        _totalScansThisMonth++;
        _sessionScanCount++;

        if (isBuy) {
          HapticFeedback.heavyImpact();
          _sessionProfit += profit;
          if (_isVoiceEnabled) {
            final title = metadataResponse['title'] ?? "Book";
            _tts.speak("Buy detected. $title. Estimated profit, ${profit.toInt()} dollars.");
          }
        } else {
          HapticFeedback.mediumImpact();
          if (_isVoiceEnabled) _tts.speak("Skip.");
        }

        _scanHistory.insert(0, {
          'metadata': metadataResponse,
          'recommendation': recommendation,
        });
        if (_scanHistory.length > 5) _scanHistory.removeLast();

        setState(() {
          _isProcessing = false;
          _lastRecommendation = recommendation;
          _lastMetadata = metadataResponse;
          _focusStatus = isBuy ? AnalysisStatus.buy : AnalysisStatus.skip;
          _focusRationale = recommendation['reason'] ?? '';
          _focusNet = profit;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isProcessing = false; _focusStatus = AnalysisStatus.unknown; });
    }
  }

  Future<void> _saveToHub() async {
    if (_lastRecommendation == null) return;
    
    final repository = RepositoryProvider.of<BookRepository>(context);
    
    final book = BookModel(
      isbn: _lastMetadata?['isbn13'] ?? _lastMetadata?['isbn10'] ?? 'UNKNOWN',
      title: _lastMetadata?['title'] ?? 'Unknown Book',
      author: _lastMetadata?['author'] ?? 'Unknown Author',
      publisher: _lastMetadata?['publisher'],
      purchasePrice: 1.0, 
      salesRank: _lastRecommendation?['sales_rank'],
      scrapedData: ScrapedData(
        originalRetailPrice: (_lastRecommendation?['original_retail_price'] as num?)?.toDouble(),
        salesRank: _lastRecommendation?['sales_rank'],
      )
    );

    await repository.saveBook(book);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to VisionHub!'), backgroundColor: AppColors.secondary),
      );
      setState(() => _focusStatus = AnalysisStatus.none);
    }
  }

  Future<void> _handleBatchTap() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;
    
    final repository = RepositoryProvider.of<BookRepository>(context);
    final storage = RepositoryProvider.of<CloudStorageService>(context);

    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _statusMessage = 'ANALYZING BATCH...';
    });

    try {
      final xFile = await _controller!.takePicture();
      final gcsUri = await storage.uploadImage(File(xFile.path));
      
      if (gcsUri == null) throw Exception('Upload failed');

      final books = await repository.batchProcessShelf(gcsUri);

      if (mounted) {
        HapticFeedback.vibrate();
        context.pushReplacement('/review_vision', extra: books);
      }
    } catch (e) {
      if (mounted) setState(() { _isProcessing = false; _statusMessage = 'SCAN FAILED'; });
    }
  }

  void _startSpatialLoop() {
    _spatialTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (!mounted || _currentMode != OmniVisionMode.spatial) {
        timer.cancel();
        return;
      }
      _simulateDetection();
    });
  }

  void _simulateDetection() {
    setState(() {
      final typeRoll = _random.nextInt(10);
      AnalysisType spineType = typeRoll < 4 ? AnalysisType.pass : (typeRoll < 7 ? AnalysisType.buy : AnalysisType.setPiece);
      
      bool isWishMatch = _random.nextInt(20) == 0;
      
      String label = isWishMatch 
          ? 'WISHMATCH!' 
          : (spineType == AnalysisType.buy 
              ? 'BUY: \$${(15 + _random.nextInt(20))}.00' 
              : (spineType == AnalysisType.setPiece ? 'SERIES PIECE!' : 'LOW ROI'));

      if (isWishMatch) {
        spineType = AnalysisType.wishVision;
        HapticFeedback.vibrate();
        if (_isVoiceEnabled) _tts.speak("Wish match detected!");
      } else if (spineType == AnalysisType.buy || spineType == AnalysisType.setPiece) {
        HapticFeedback.selectionClick();
      }

      _spatialDetections.add(DetectedSpine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        x: 0.15 + _random.nextDouble() * 0.7,
        y: 0.2 + _random.nextDouble() * 0.5,
        type: spineType,
        label: label,
      ));

      if (_spatialDetections.length > 4) _spatialDetections.removeAt(0);
    });
  }

  @override
  void dispose() {
    _laserController.dispose();
    _spatialTimer?.cancel();
    _controller?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onScaleUpdate: (details) {
          if (details.scale != 1.0) {
            _handleZoom(_currentZoomLevel * details.scale);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller!);
                } else {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
              },
            ),

            if (_isProcessing || _currentMode == OmniVisionMode.spatial) 
              _buildScanningLaser(),

            if (_currentMode == OmniVisionMode.focus) _buildFocusOverlay(),
            if (_currentMode == OmniVisionMode.batch) _buildBatchOverlay(),
            if (_currentMode == OmniVisionMode.spatial) _buildSpatialOverlay(),

            _buildSessionHUD(),
            _buildScanHistoryRibbon(),

            _buildModeSwitcher(),
            _buildUtilityBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanHistoryRibbon() {
    if (_scanHistory.isEmpty) return const SizedBox.shrink();
    
    return Positioned(
      top: 110,
      left: 20,
      right: 150, 
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _scanHistory.length,
          itemBuilder: (context, index) {
            final scan = _scanHistory[index];
            final bool isBuy = scan['recommendation']?['decision'] == 'buy';
            final String? coverUrl = scan['metadata']?['cover_image_url'];
            final bool isHighVelocity = scan['recommendation']?['sales_velocity'] == 'High';

            return GestureDetector(
              onTap: () {
                setState(() {
                   _lastMetadata = scan['metadata'];
                   _lastRecommendation = scan['recommendation'];
                   _focusStatus = isBuy ? AnalysisStatus.buy : AnalysisStatus.skip;
                   _focusRationale = _lastRecommendation?['reason'] ?? '';
                   _focusNet = (_lastRecommendation?['estimated_profit'] as num?)?.toDouble() ?? 0.0;
                });
              },
              child: Stack(
                children: [
                  Container(
                    width: 45,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isBuy ? AppColors.secondary : AppColors.error.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: coverUrl != null 
                        ? Image.network(coverUrl, fit: BoxFit.cover)
                        : Center(child: Icon(Icons.book, size: 20, color: isBuy ? AppColors.secondary : Colors.white24)),
                    ),
                  ),
                  if (isHighVelocity)
                    const Positioned(
                      top: 2,
                      right: 12,
                      child: Icon(Icons.whatshot, color: Colors.orange, size: 14),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUtilityBar() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off, 
                    color: _isTorchOn ? Colors.amber : Colors.white, 
                    size: 24
                  ),
                  onPressed: _toggleTorch,
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: Icon(
                    _isVoiceEnabled ? Icons.volume_up : Icons.volume_off, 
                    color: _isVoiceEnabled ? AppColors.secondary : Colors.white, 
                    size: 24
                  ),
                  onPressed: () {
                    setState(() => _isVoiceEnabled = !_isVoiceEnabled);
                    HapticFeedback.mediumImpact();
                  },
                ),
              ),
            ],
          ),
          
          GestureDetector(
            onTap: () => _handleZoom(_currentZoomLevel > 1.0 ? 1.0 : 2.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
              child: Text('${_currentZoomLevel.toStringAsFixed(1)}x', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
            ),
          ),

          CircleAvatar(
            backgroundColor: Colors.black45,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHUD() {
    final double progress = (_totalScansThisMonth % _milestoneTarget) / _milestoneTarget;
    
    return Positioned(
      top: 110,
      right: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
          Container(
            width: 80,
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.alternate.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('PROFIT', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70, fontSize: 8)),
                Text('\$${_sessionProfit.toInt()}', style: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Positioned(
            bottom: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
              child: Text('${_totalScansThisMonth % _milestoneTarget}/$_milestoneTarget', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningLaser() {
    return AnimatedBuilder(
      animation: _laserAnimation,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.15 + 
               (MediaQuery.of(context).size.height * 0.6 * _laserAnimation.value),
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.8),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.secondary.withValues(alpha: 0.5),
                  AppColors.secondary,
                  AppColors.secondary.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFocusOverlay() {
    if (_focusStatus == AnalysisStatus.none) {
      return Center(
        child: GestureDetector(
          onTap: _handleFocusTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 1)
                  ],
                ),
                child: const Center(child: Icon(Icons.filter_center_focus, color: AppColors.primary, size: 60)),
              ),
              const SizedBox(height: 20),
              Text('TAP TO APPRAISE ITEM', style: AppTextStyles.labelLarge.copyWith(color: Colors.white, letterSpacing: 2)),
            ],
          ),
        ),
      );
    }

    if (_focusStatus == AnalysisStatus.analyzing) {
      return Container(
        color: Colors.black45,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.secondary),
              const SizedBox(height: 24),
              Text('NEURAL ENGINE ANALYZING...', 
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white, letterSpacing: 1.2)),
            ],
          ),
        ),
      );
    }

    Color color = _focusStatus == AnalysisStatus.buy ? AppColors.primary : Colors.black87;
    String msg = _focusStatus == AnalysisStatus.buy ? 'BUY' : 'SKIP';
    
    return Container(
      color: color.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(msg, style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 72)),
            if (_focusStatus == AnalysisStatus.buy)
              Text('EST. NET: \$${_focusNet.toStringAsFixed(2)}', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(_focusRationale, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
            ),
            const SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.inventory_2, 
                  label: 'SAVE TO HUB', 
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _saveToHub();
                  }
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  icon: Icons.list_alt, 
                  label: 'LIST NOW', 
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    context.push('/listing_vision', extra: _lastRecommendation);
                  }
                ),
              ],
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () => setState(() => _focusStatus = AnalysisStatus.none),
              child: Text('CONTINUE SCANNING', style: AppTextStyles.labelLarge.copyWith(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBatchOverlay() {
    return Center(
      child: GestureDetector(
        onTap: _handleBatchTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) ...[
              const CircularProgressIndicator(color: AppColors.secondary),
              const SizedBox(height: 20),
              Text(_statusMessage, style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.secondary, width: 3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.grid_view, color: AppColors.secondary, size: 80),
              ),
              const SizedBox(height: 24),
              Text('TAP TO SCAN ENTIRE BOX', style: AppTextStyles.labelLarge.copyWith(color: Colors.white, letterSpacing: 1.5)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSpatialOverlay() {
    return Stack(
      children: [
        Positioned(
          top: 210, // Lowered more to accommodate HUD/Ribbon
          left: 0,
          right: 0,
          child: Column(
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, color: AppColors.secondary, size: 16),
                      const SizedBox(width: 8),
                      Text('LIVE SPATIAL AI ACTIVE', style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() => _highProfitOnly = !_highProfitOnly);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _highProfitOnly ? AppColors.secondary : Colors.black45,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.secondary),
                  ),
                  child: Text(
                    _highProfitOnly ? 'HIGH PROFIT ONLY' : 'SHOW ALL ITEMS', 
                    style: TextStyle(
                      color: _highProfitOnly ? Colors.white : AppColors.secondary, 
                      fontSize: 8, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._spatialDetections.where((d) => !_highProfitOnly || d.type == AnalysisType.buy || d.type == AnalysisType.wishVision).map((d) => _buildARDetection(d)),
      ],
    );
  }

  Widget _buildARDetection(DetectedSpine d) {
    Color color = d.type == AnalysisType.buy ? AppColors.secondary : (d.type == AnalysisType.setPiece ? AppColors.tertiary : Colors.white);
    
    Gradient? gradient;
    if (d.type == AnalysisType.buy) gradient = AppColors.primaryGradient;
    if (d.type == AnalysisType.wishVision) gradient = AppColors.purpleCoral;

    return Positioned(
      left: MediaQuery.of(context).size.width * d.x,
      top: MediaQuery.of(context).size.height * d.y,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? color.withValues(alpha: 0.8) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: d.type == AnalysisType.wishVision ? [
            BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
          ] : null,
        ),
        child: Text(d.label, style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Positioned(
      bottom: 50,
      left: 30,
      right: 30,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeTab(OmniVisionMode.focus, Icons.center_focus_strong, 'THRIFT'),
            _buildModeTab(OmniVisionMode.batch, Icons.grid_view, 'SHELF'),
            _buildModeTab(OmniVisionMode.spatial, Icons.auto_awesome, 'SPATIAL'),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(OmniVisionMode mode, IconData icon, String label) {
    bool active = _currentMode == mode;
    final repository = RepositoryProvider.of<BookRepository>(context);
    final tier = repository.currentTier;
    
    bool isLocked = false;
    if (mode == OmniVisionMode.batch && tier == 'Hobbyist') isLocked = true;
    if (mode == OmniVisionMode.spatial && tier != 'Enterprise') isLocked = true;

    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(icon, color: active ? AppColors.secondary : Colors.white54, size: 24),
              if (isLocked)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.lock, color: Colors.amber, size: 10),
                ),
            ],
          ),
          Text(label, style: AppTextStyles.labelMedium.copyWith(color: active ? Colors.white : Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

enum AnalysisStatus { none, analyzing, buy, skip, unknown }
enum AnalysisType { buy, pass, setPiece, wishVision }
class DetectedSpine {
  final String id;
  final double x;
  final double y;
  final AnalysisType type;
  final String label;
  DetectedSpine({required this.id, required this.x, required this.y, required this.type, required this.label});
}
