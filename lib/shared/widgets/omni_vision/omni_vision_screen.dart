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
  final int _milestoneTarget = 50; 
  final List<Map<String, dynamic>> _scanHistory = [];
  
  // Analysis State
  bool _isProcessing = false;
  String _statusMessage = '';
  Map<String, dynamic>? _lastRecommendation;
  Map<String, dynamic>? _lastMetadata;
  List<WishModel> _activeWishlist = [];
  bool _isSignatureMode = false;
  
  // Animation for Laser
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  // Focus Mode State
  AnalysisStatus _focusStatus = AnalysisStatus.none;
  String _focusRationale = '';
  double _focusNet = 0.0;
  bool _isWishMatch = false;
  
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
    _loadWishlist();
    
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

  Future<void> _loadWishlist() async {
    final repository = RepositoryProvider.of<BookRepository>(context);
    repository.getWishlistStream().listen((wishes) {
      if (mounted) setState(() => _activeWishlist = wishes.where((w) => w.isActive).toList());
    });
  }

  Future<void> _initializeTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
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
    final newTorchState = !_isTorchOn;
    await _controller!.setFlashMode(newTorchState ? FlashMode.torch : FlashMode.off);
    setState(() => _isTorchOn = newTorchState);
  }

  Future<void> _handleZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final double newZoom = zoom.clamp(_minZoomLevel, _maxZoomLevel);
    await _controller!.setZoomLevel(newZoom);
    setState(() => _currentZoomLevel = newZoom);
  }

  void _switchMode(OmniVisionMode mode) {
    if (mode == _currentMode) return;
    final tier = RepositoryProvider.of<BookRepository>(context).currentTier;

    if (mode == OmniVisionMode.batch && tier == 'Hobbyist') { _showUpgradeDialog('Pro'); return; }
    if (mode == OmniVisionMode.spatial && tier != 'Enterprise') { _showUpgradeDialog('Enterprise'); return; }

    if (_currentMode == OmniVisionMode.spatial) _spatialTimer?.cancel();

    setState(() {
      _currentMode = mode;
      _isProcessing = false;
      _focusStatus = AnalysisStatus.none;
    });

    if (mode == OmniVisionMode.spatial) _startSpatialLoop();
  }

  void _showUpgradeDialog(String requiredTier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to $requiredTier'),
        content: Text('This feature is exclusive to $requiredTier members.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('LATER')),
          ElevatedButton(onPressed: () { Navigator.pop(context); context.push('/paywall'); }, child: const Text('UPGRADE')),
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
      _isWishMatch = false;
    });

    try {
      final xFile = await _controller!.takePicture();
      final gcsUri = await storage.uploadImage(File(xFile.path));
      if (gcsUri == null) throw Exception('Upload failed');

      final metadata = await repository.getRecommendation(gcsUri, {}); 
      final recommendation = await repository.getRecommendation(gcsUri, {'min_profit': 10.0});

      if (mounted) {
        final double profit = (recommendation['estimated_profit'] as num?)?.toDouble() ?? 0.0;
        final bool isBuy = recommendation['decision'] == 'buy';
        final String isbn = metadata['isbn13'] ?? metadata['isbn10'] ?? '';
        
        bool isWish = _activeWishlist.any((w) => w.isbn == isbn || (metadata['title']?.toString().contains(w.isbn) ?? false));

        if (isWish) {
          HapticFeedback.vibrate();
          if (_isVoiceEnabled) _tts.speak("Wish match detected! Platinum opportunity.");
        } else if (isBuy) {
          HapticFeedback.heavyImpact();
          if (_isVoiceEnabled) _tts.speak("Buy detected. Profit ${profit.toInt()} dollars.");
        } else {
          HapticFeedback.mediumImpact();
          if (_isVoiceEnabled) _tts.speak("Skip.");
        }

        _scanHistory.insert(0, {'metadata': metadata, 'recommendation': recommendation});
        if (_scanHistory.length > 5) _scanHistory.removeLast();

        setState(() {
          _isProcessing = false;
          _lastRecommendation = recommendation;
          _lastMetadata = metadata;
          _focusStatus = isBuy ? AnalysisStatus.buy : AnalysisStatus.skip;
          _focusRationale = recommendation['reason'] ?? '';
          _focusNet = profit;
          _isWishMatch = isWish;
          if (isBuy) _sessionProfit += profit;
          _sessionScanCount++;
          _totalScansThisMonth++;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isProcessing = false; _focusStatus = AnalysisStatus.unknown; });
    }
  }

  void _startSpatialLoop() {
    _spatialTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (!mounted || _currentMode != OmniVisionMode.spatial) { timer.cancel(); return; }
      _simulateDetection();
    });
  }

  void _simulateDetection() {
    setState(() {
      final typeRoll = _random.nextInt(10);
      AnalysisType spineType = typeRoll < 4 ? AnalysisType.pass : (typeRoll < 7 ? AnalysisType.buy : AnalysisType.setPiece);
      
      bool isWishMatch = _random.nextInt(15) == 0;
      if (isWishMatch) {
        spineType = AnalysisType.wishVision;
        HapticFeedback.vibrate();
        if (_isVoiceEnabled) _tts.speak("Wish match detected!");
      }

      _spatialDetections.add(DetectedSpine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        x: 0.15 + _random.nextDouble() * 0.7,
        y: 0.2 + _random.nextDouble() * 0.5,
        type: spineType,
        label: isWishMatch ? 'GRAIL TARGET!' : (spineType == AnalysisType.buy ? 'BUY: \$${(15 + _random.nextInt(20))}' : 'LOW ROI'),
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
        onScaleUpdate: (details) { if (details.scale != 1.0) _handleZoom(_currentZoomLevel * details.scale); },
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                return snapshot.connectionState == ConnectionState.done ? CameraPreview(_controller!) : const Center(child: CircularProgressIndicator(color: Colors.white));
              },
            ),
            if (_isProcessing || _currentMode == OmniVisionMode.spatial) _buildScanningLaser(),
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

  Widget _buildFocusOverlay() {
    if (_focusStatus == AnalysisStatus.none) {
      return Center(
        child: GestureDetector(
          onTap: _isSignatureMode ? _handleSignatureTap : _handleFocusTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: _isSignatureMode ? AppColors.secondary : AppColors.primary, width: 3), 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_isSignatureMode ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.3),
                      blurRadius: 15,
                    )
                  ]
                ),
                child: Center(
                  child: Icon(
                    _isSignatureMode ? Icons.history_edu : Icons.filter_center_focus, 
                    color: _isSignatureMode ? AppColors.secondary : AppColors.primary, 
                    size: 60
                  )
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isSignatureMode ? 'SCAN TITLE PAGE FOR SIGNATURE' : 'TAP TO APPRAISE ITEM', 
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white, letterSpacing: 2)
              ),
            ],
          ),
        ),
      );
    }

    if (_focusStatus == AnalysisStatus.analyzing) return Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: AppColors.secondary)));

    Color color = _isWishMatch ? Colors.amber : (_focusStatus == AnalysisStatus.buy ? AppColors.primary : Colors.black87);
    
    return Container(
      decoration: BoxDecoration(
        gradient: _isWishMatch ? AppColors.purpleCoral : null,
        color: _isWishMatch ? null : color.withValues(alpha: 0.9),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isWishMatch) const Icon(Icons.stars, color: Colors.white, size: 80),
            Text(_isWishMatch ? 'GRAIL MATCH' : (_focusStatus == AnalysisStatus.buy ? 'BUY' : 'SKIP'), style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 60)),
            Text('EST. NET: \$${_focusNet.toStringAsFixed(2)}', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
            const SizedBox(height: 20),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text(_focusRationale, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionBtn(Icons.inventory_2, 'SAVE', () => _saveToHub()),
                const SizedBox(width: 20),
                _buildActionBtn(Icons.list_alt, 'LIST', () => context.push('/listing_vision', extra: _lastRecommendation)),
              ],
            ),
            const SizedBox(height: 30),
            TextButton(onPressed: () => setState(() => _focusStatus = AnalysisStatus.none), child: const Text('CONTINUE SCANNING', style: TextStyle(color: Colors.white54))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)), child: Icon(icon, color: Colors.white)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ]),
    );
  }

  Widget _buildScanningLaser() {
    return AnimatedBuilder(
      animation: _laserAnimation,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.15 + (MediaQuery.of(context).size.height * 0.6 * _laserAnimation.value),
          left: 0, right: 0,
          child: Container(height: 3, decoration: BoxDecoration(boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.8), blurRadius: 15)], gradient: LinearGradient(colors: [Colors.transparent, AppColors.secondary.withValues(alpha: 0.5), AppColors.secondary, AppColors.secondary.withValues(alpha: 0.5), Colors.transparent]))),
        );
      },
    );
  }

  Widget _buildSessionHUD() {
    final double progress = (_totalScansThisMonth % _milestoneTarget) / _milestoneTarget;
    return Positioned(
      top: 110, right: 20,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 90, height: 90, child: CircularProgressIndicator(value: progress, strokeWidth: 4, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary))),
        Container(width: 80, height: 60, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(15)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('PROFIT', style: TextStyle(color: Colors.white70, fontSize: 8)), Text('\$${_sessionProfit.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))])),
      ]),
    );
  }

  Widget _buildScanHistoryRibbon() {
     if (_scanHistory.isEmpty) return const SizedBox.shrink();
     return Positioned(top: 110, left: 20, right: 150, child: SizedBox(height: 60, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _scanHistory.length, itemBuilder: (context, i) {
        final scan = _scanHistory[i];
        final bool isBuy = scan['recommendation']?['decision'] == 'buy';
        return Container(width: 45, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8), border: Border.all(color: isBuy ? AppColors.secondary : Colors.white24, width: 2)), child: ClipRRect(borderRadius: BorderRadius.circular(6), child: scan['metadata']?['cover_image_url'] != null ? Image.network(scan['metadata']!['cover_image_url'], fit: BoxFit.cover) : const Icon(Icons.book, size: 20, color: Colors.white24)));
     })));
  }

  Widget _buildUtilityBar() {
    return Positioned(top: 50, left: 20, right: 20, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: _isTorchOn ? Colors.amber : Colors.white), onPressed: _toggleTorch)),
        const SizedBox(width: 10),
        CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: Icon(_isVoiceEnabled ? Icons.volume_up : Icons.volume_off, color: _isVoiceEnabled ? AppColors.secondary : Colors.white), onPressed: () => setState(() => _isVoiceEnabled = !_isVoiceEnabled))),
        const SizedBox(width: 10),
        CircleAvatar(
          backgroundColor: _isSignatureMode ? AppColors.secondary : Colors.black45,
          child: IconButton(
            icon: Icon(Icons.history_edu, color: _isSignatureMode ? Colors.white : Colors.white70),
            onPressed: () => setState(() => _isSignatureMode = !_isSignatureMode),
            tooltip: 'Signature Check',
          ),
        ),
      ]),
      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
    ]));
  }

  Widget _buildModeSwitcher() {
    return Positioned(bottom: 50, left: 30, right: 30, child: Container(height: 70, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(35)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _buildModeTab(OmniVisionMode.focus, Icons.center_focus_strong, 'THRIFT'),
      _buildModeTab(OmniVisionMode.batch, Icons.grid_view, 'SHELF'),
      _buildModeTab(OmniVisionMode.spatial, Icons.auto_awesome, 'SPATIAL'),
    ])));
  }

  Widget _buildModeTab(OmniVisionMode mode, IconData icon, String label) {
    bool active = _currentMode == mode;
    return GestureDetector(onTap: () => _switchMode(mode), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: active ? AppColors.secondary : Colors.white54), Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 10))]));
  }

  Widget _buildBatchOverlay() { return Center(child: GestureDetector(onTap: _handleBatchTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [if (_isProcessing) ...[const CircularProgressIndicator(color: AppColors.secondary), const SizedBox(height: 20), Text(_statusMessage, style: const TextStyle(color: Colors.white))] else ...[Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(border: Border.all(color: AppColors.secondary, width: 3), borderRadius: BorderRadius.circular(30)), child: const Icon(Icons.grid_view, color: AppColors.secondary, size: 80)), const SizedBox(height: 24), const Text('TAP TO SCAN ENTIRE BOX', style: TextStyle(color: Colors.white, letterSpacing: 1.5))]]))); }

  Widget _buildSpatialOverlay() {
    return Stack(children: [
      ..._spatialDetections.map((d) => _buildARDetection(d)),
    ]);
  }

  Widget _buildARDetection(DetectedSpine d) {
    Gradient? gradient;
    if (d.type == AnalysisType.buy) gradient = AppColors.primaryGradient;
    if (d.type == AnalysisType.wishVision) gradient = AppColors.purpleCoral;
    return Positioned(left: MediaQuery.of(context).size.width * d.x, top: MediaQuery.of(context).size.height * d.y, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: gradient, color: gradient == null ? Colors.white70 : null, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 1.5)), child: Text(d.label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))));
  }

  Future<void> _saveToHub() async {
    if (_lastRecommendation == null) return;
    final book = BookModel(
      isbn: _lastMetadata?['isbn13'] ?? _lastMetadata?['isbn10'] ?? 'UNKNOWN',
      title: _lastMetadata?['title'] ?? 'Unknown Book',
      author: _lastMetadata?['author'] ?? 'Unknown Author',
      purchasePrice: 1.0, 
      isSigned: _isWishMatch, // Placeholder for signature logic during save
      scrapedData: ScrapedData(originalRetailPrice: (_lastRecommendation?['original_retail_price'] as num?)?.toDouble())
    );
    await RepositoryProvider.of<BookRepository>(context).saveBook(book);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to VisionHub!'), backgroundColor: AppColors.secondary));
    setState(() => _focusStatus = AnalysisStatus.none);
  }

  Future<void> _handleBatchTap() async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; _statusMessage = 'ANALYZING...'; });
    try {
      final xFile = await _controller!.takePicture();
      final gcsUri = await RepositoryProvider.of<CloudStorageService>(context).uploadImage(File(xFile.path));
      final books = await RepositoryProvider.of<BookRepository>(context).batchProcessShelf(gcsUri!);
      context.pushReplacement('/review_vision', extra: books);
    } catch (e) { setState(() { _isProcessing = false; }); }
  }

  Future<void> _handleSignatureTap() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;
    
    final repository = RepositoryProvider.of<BookRepository>(context);
    final storage = RepositoryProvider.of<CloudStorageService>(context);

    HapticFeedback.lightImpact();
    setState(() {
      _isProcessing = true;
      _statusMessage = 'DETECTING SIGNATURE...';
    });

    try {
      final xFile = await _controller!.takePicture();
      final gcsUri = await storage.uploadImage(File(xFile.path));
      if (gcsUri == null) throw Exception('Upload failed');

      final result = await repository.analyzeSignature(gcsUri);

      if (mounted) {
        final bool isSigned = result['is_signed'] ?? false;
        HapticFeedback.vibrate();
        
        if (isSigned) {
          if (_isVoiceEnabled) _tts.speak("Signature detected. Verifying signer.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signature Found: ${result['signer_name']}'),
              backgroundColor: AppColors.secondary,
            ),
          );
        } else {
          if (_isVoiceEnabled) _tts.speak("No signature detected.");
        }

        setState(() {
          _isProcessing = false;
          _isSignatureMode = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isProcessing = false; });
    }
  }
}

enum AnalysisStatus { none, analyzing, buy, skip, unknown }
enum AnalysisType { buy, pass, setPiece, wishVision }
class DetectedSpine {
  final String id; final double x; final double y; final AnalysisType type; final String label;
  DetectedSpine({required this.id, required this.x, required this.y, required this.type, required this.label});
}
