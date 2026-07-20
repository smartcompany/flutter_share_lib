import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data' as typed_data;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

/// 앨범 그리드 + 왼쪽 첫 칸 촬영 아이콘 스타일의 미디어 피커 서비스
///
/// 사용 예시:
/// ```dart
/// final files = await MediaPickerService.pickImages(context, maxCount: 9);
/// if (files != null && files.isNotEmpty) {
///   // 업로드 등 처리
/// }
/// ```
class MediaPickerService {
  MediaPickerService._();

  /// 앨범에서 이미지를 선택하거나 촬영 아이콘을 통해 카메라로 촬영합니다.
  /// 앨범 그리드 왼쪽 첫 칸에 촬영 아이콘이 표시됩니다.
  /// 기본적으로 이미지를 압축하여 반환합니다 (Vercel 4.5MB 제한 등 대응).
  ///
  /// [context] - 빌드 컨텍스트
  /// [maxCount] - 최대 선택 개수 (기본 9)
  /// [permissionDeniedMessage] - 권한 거부 시 표시할 메시지
  /// [compress] - 압축 적용 여부 (기본 true)
  /// [maxWidth] - 압축 시 최대 너비 (기본 1280, Vercel 4.5MB 제한 대응)
  /// [maxHeight] - 압축 시 최대 높이 (기본 720)
  /// [quality] - 압축 품질 1~100 (기본 65)
  /// [compressFailureMessage] - 압축 실패 시 표시할 메시지
  ///
  /// 반환: 선택/촬영된 이미지의 [XFile] 목록. 취소/압축 실패 시 null.
  static Future<List<XFile>?> pickImages(
    BuildContext context, {
    int maxCount = 9,
    String permissionDeniedMessage = '앨범 접근 권한이 필요합니다',
    bool compress = true,
    int maxWidth = 1280,
    int maxHeight = 720,
    int quality = 65,
    String compressFailureMessage = '이미지 압축 실패',
  }) async {
    debugPrint(
      '🔵 [MediaPickerService] pickImages start '
      'maxCount=$maxCount compress=$compress maxWidth=$maxWidth '
      'maxHeight=$maxHeight quality=$quality',
    );
    // 이미지만 선택하므로 image 타입만 요청. 기본값(common)이면 이미지+동영상 권한을 모두 요구해
    // 사진만 허용한 경우에도 거부로 인식될 수 있음. hasAccess(authorized || limited)로 판단해
    // "일부만 허용" 상태에서도 피커를 연다.
    final ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );
    debugPrint(
      '🔵 [MediaPickerService] permission state: isAuth=${ps.isAuth}, '
      'hasAccess=${ps.hasAccess}, isLimited=${ps.isLimited}',
    );
    if (!ps.hasAccess) {
      debugPrint('🟡 [MediaPickerService] permission denied');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(permissionDeniedMessage)),
        );
      }
      return null;
    }

    final List<XFile>? files = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ImagePickerPage(
          maxCount: maxCount,
          compress: compress,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
          compressFailureMessage: compressFailureMessage,
          isLimitedAccess: ps.isLimited,
        ),
      ),
    );
    debugPrint(
      '🔵 [MediaPickerService] pickImages done files=${files?.length ?? -1}',
    );

    return files;
  }
}

class _ImagePickerPage extends StatefulWidget {
  const _ImagePickerPage({
    required this.maxCount,
    required this.compress,
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.compressFailureMessage,
    required this.isLimitedAccess,
  });

  final int maxCount;
  final bool compress;
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final String compressFailureMessage;
  final bool isLimitedAccess;

  @override
  State<_ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<_ImagePickerPage> {
  /// 한 번에 너무 많이 올리면 저용량 기기에서 OOM으로 앱이 종료될 수 있음
  static const _pageSize = 80;
  static const _thumbnailSize = 120;
  static const _loadMoreThreshold = 900.0;

  final List<AssetEntity> _assets = [];
  final Set<AssetEntity> _selected = {};
  final ScrollController _scrollController = ScrollController();
  AssetPathEntity? _album;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isLimitedAccess = false;
  bool _isConfirming = false;
  /// setState 전에 동기적으로 막아 스크롤 리스너 동시 호출 방지
  bool _loadMoreLocked = false;

  @override
  void initState() {
    super.initState();
    _isLimitedAccess = widget.isLimitedAccess;
    _scrollController.addListener(_onScroll);
    unawaited(_loadAssets(reset: true));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _assets.clear();
    _selected.clear();
    _ThumbnailCache.instance.clear();
    super.dispose();
  }

  void _onScroll() => _maybeLoadMore();

  void _maybeLoadMore() {
    if (!_hasMore || _isLoading || _isLoadingMore || _loadMoreLocked) return;
    if (_album == null) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    // 화면을 다 채우지 못했거나(maxScrollExtent==0), 하단 근처면 다음 페이지
    final nearBottom = position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - _loadMoreThreshold;
    if (nearBottom) {
      unawaited(_loadAssets(reset: false));
    }
  }

  Future<void> _openLimitedLibraryPicker() async {
    try {
      await PhotoManager.presentLimited();
      if (!mounted) return;
      await _loadAssets(reset: true);
      final state = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _isLimitedAccess = state.isLimited;
      });
    } catch (e, st) {
      debugPrint('❌ [MediaPickerService] presentLimited failed: $e\n$st');
    }
  }

  Future<void> _loadAssets({required bool reset}) async {
    if (reset) {
      debugPrint('🔵 [MediaPickerService] _loadAssets start');
      _loadMoreLocked = false;
      if (mounted) {
        setState(() {
          _isLoading = true;
          _isLoadingMore = false;
          _hasMore = true;
          _assets.clear();
        });
      }
    } else {
      if (_loadMoreLocked || _isLoadingMore || !_hasMore) return;
      _loadMoreLocked = true;
      _isLoadingMore = true;
      if (mounted) setState(() {});
    }

    try {
      AssetPathEntity? resolvedAlbum = _album;
      if (reset || resolvedAlbum == null) {
        final paths = await PhotoManager.getAssetPathList(
          hasAll: true,
          onlyAll: true,
          type: RequestType.image,
        );
        resolvedAlbum = paths.isEmpty ? null : paths.first;
      }

      if (resolvedAlbum == null) {
        debugPrint('🟡 [MediaPickerService] no album paths');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = false;
          _loadMoreLocked = false;
        });
        return;
      }

      final total = await resolvedAlbum.assetCountAsync;
      final start = reset ? 0 : _assets.length;
      if (start >= total) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = false;
          _loadMoreLocked = false;
        });
        return;
      }

      final end = (start + _pageSize).clamp(0, total);
      final batch =
          await resolvedAlbum.getAssetListRange(start: start, end: end);
      debugPrint(
        '🔵 [MediaPickerService] _loadAssets album=${resolvedAlbum.name} '
        'range=$start..$end total=$total batch=${batch.length}',
      );

      if (!mounted) return;
      setState(() {
        _album = resolvedAlbum;
        if (reset) {
          _assets
            ..clear()
            ..addAll(batch);
        } else {
          _assets.addAll(batch);
        }
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = end < total;
        _loadMoreLocked = false;
      });

      // 첫 페이지가 화면을 못 채우면(스크롤 불가) 다음 페이지를 이어서 로드.
      // 이미 스크롤 가능한데 하단에 있으면 사용자가 더 내릴 때 리스너가 담당.
      if (_hasMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          final pos = _scrollController.position;
          if (pos.hasContentDimensions && pos.maxScrollExtent <= 0) {
            _maybeLoadMore();
          }
        });
      }
    } catch (e, st) {
      debugPrint('❌ [MediaPickerService] 이미지 로드 실패: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 불러오지 못했습니다')),
        );
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _loadMoreLocked = false;
      });
    }
  }

  Future<void> _onCameraTap() async {
    debugPrint('🔵 [MediaPickerService] _onCameraTap start');
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) {
        debugPrint('🟡 [MediaPickerService] _onCameraTap cancelled');
        return;
      }
      debugPrint(
        '🔵 [MediaPickerService] _onCameraTap picked path=${picked.path}',
      );

      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/camera_${DateTime.now().millisecondsSinceEpoch}.jpg';

      String outPath = picked.path;
      if (widget.compress) {
        final compressed = await FlutterImageCompress.compressAndGetFile(
          picked.path,
          targetPath,
          quality: widget.quality,
          minWidth: widget.maxWidth,
          minHeight: widget.maxHeight,
        );
        if (compressed == null) {
          debugPrint('❌ [MediaPickerService] _onCameraTap compress failed');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.compressFailureMessage)),
            );
          }
          return;
        }
        outPath = compressed.path;
        debugPrint(
          '🔵 [MediaPickerService] _onCameraTap compressed path=$outPath',
        );
      }

      if (!mounted) return;
      debugPrint('✅ [MediaPickerService] _onCameraTap done');
      Navigator.of(context).pop(<XFile>[XFile(outPath)]);
    } catch (e, st) {
      debugPrint('❌ [MediaPickerService] 카메라 촬영 실패: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라를 사용할 수 없습니다')),
      );
    }
  }

  void _onAssetTap(AssetEntity asset) {
    if (_isConfirming) return;

    var confirmAfterTap = false;

    if (_selected.contains(asset)) {
      setState(() {
        debugPrint('🔵 [MediaPickerService] deselect asset id=${asset.id}');
        _selected.remove(asset);
      });
      return;
    }

    if (_selected.length >= widget.maxCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 ${widget.maxCount}장까지 선택할 수 있습니다')),
      );
      return;
    }

    setState(() {
      _selected.add(asset);
      debugPrint(
        '🔵 [MediaPickerService] select asset id=${asset.id} selected=${_selected.length}/${widget.maxCount}',
      );
    });

    // 1장만 선택(프로필/배경): setState 밖에서 confirm — setState 안 async 호출 시 UI 멈춤
    if (widget.maxCount == 1) {
      confirmAfterTap = true;
    }

    if (confirmAfterTap) {
      unawaited(_onConfirm());
    }
  }

  Future<void> _onConfirm() async {
    if (_isConfirming) return;
    _isConfirming = true;
    if (mounted) {
      setState(() {});
    }

    debugPrint('🔵 [MediaPickerService] _onConfirm start selected=${_selected.length}');
    if (_selected.isEmpty) {
      debugPrint('🟡 [MediaPickerService] _onConfirm empty selection');
      _isConfirming = false;
      if (mounted) Navigator.of(context).pop(<XFile>[]);
      return;
    }
    final dir = await getTemporaryDirectory();
    final List<XFile> files = [];
    int index = 0;
    for (final asset in _selected) {
      debugPrint(
        '🔵 [MediaPickerService] _onConfirm asset id=${asset.id} type=${asset.typeInt} title=${asset.title}',
      );
      File? file;
      try {
        // iCloud 전용/미다운로드 에셋은 시뮬레이터에서 CloudPhotoLibraryErrorDomain(1006) 발생 가능
        file = await asset.file;
      } catch (e, st) {
        debugPrint('❌ [MediaPickerService] _onConfirm getFile failed id=${asset.id} error=$e');
        debugPrint('$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '사진을 불러오지 못했습니다. 기기에 저장된 사진을 선택하거나 실기기에서 다시 시도해 주세요.',
              ),
            ),
          );
        }
        _isConfirming = false;
        if (mounted) setState(() {});
        return;
      }
      if (file == null) {
        debugPrint('❌ [MediaPickerService] _onConfirm file null id=${asset.id}');
        continue;
      }
      debugPrint('🔵 [MediaPickerService] _onConfirm file path=${file.path}');
      if (widget.compress) {
        final targetPath =
            '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: widget.quality,
          minWidth: widget.maxWidth,
          minHeight: widget.maxHeight,
        );
        if (compressed != null) {
          files.add(XFile(compressed.path));
          debugPrint(
            '🔵 [MediaPickerService] _onConfirm compressed path=${compressed.path}',
          );
        } else {
          debugPrint('❌ [MediaPickerService] _onConfirm compress failed id=${asset.id}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.compressFailureMessage)),
            );
          }
          _isConfirming = false;
          if (mounted) setState(() {});
          return;
        }
      } else {
        files.add(XFile(file.path));
        debugPrint('🔵 [MediaPickerService] _onConfirm keep original path=${file.path}');
      }
      index++;
    }
    if (!mounted) return;
    debugPrint('✅ [MediaPickerService] _onConfirm done outFiles=${files.length}');
    Navigator.of(context).pop(files);
  }

  Future<void> _onConfirmPressed() async {
    await _onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: const Text('사진 선택'),
        actions: [
          TextButton(
            onPressed: (_selected.isEmpty || _isConfirming) ? null : _onConfirmPressed,
            child: Text(
              _selected.isEmpty
                  ? '완료'
                  : '완료 (${_selected.length}/${widget.maxCount})',
              style: TextStyle(
                color: _selected.isEmpty
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isLimitedAccess)
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '선택한 사진만 표시됩니다. 보관함 전체를 쓰려면 더 선택하거나 설정에서 「모든 사진」 허용을 선택하세요.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: _openLimitedLibraryPicker,
                      child: const Text('더 선택'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(2),
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        // 로딩 셀을 itemCount에 넣지 않음 → 페이지 추가 시 레이아웃 점프 감소
                        itemCount: _assets.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final theme = Theme.of(context);
                            return GestureDetector(
                              onTap: _isConfirming ? null : _onCameraTap,
                              child: Container(
                                color: theme.colorScheme.surface,
                                child: Center(
                                  child: Icon(
                                    Icons.camera_enhance,
                                    size: 40,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          }

                          final asset = _assets[index - 1];
                          final selected = _selected.contains(asset);
                          return KeyedSubtree(
                            key: ValueKey<String>(asset.id),
                            child: GestureDetector(
                              onTap: _isConfirming
                                  ? null
                                  : () => _onAssetTap(asset),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _AssetThumbnail(
                                    asset: asset,
                                    size: _thumbnailSize,
                                  ),
                                  if (selected)
                                    Container(
                                      color: Colors.black26,
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (_isLoadingMore)
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
        ),
        if (_isConfirming)
          const ColoredBox(
            color: Color(0x66000000),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

/// 썸네일 LRU 캐시 — 빌드마다 재디코드/플리커 방지, 메모리 상한 유지
class _ThumbnailCache {
  _ThumbnailCache._();
  static final _ThumbnailCache instance = _ThumbnailCache._();

  static const int maxEntries = 120;
  final LinkedHashMap<String, typed_data.Uint8List> _map =
      LinkedHashMap<String, typed_data.Uint8List>();

  typed_data.Uint8List? get(String id) {
    final value = _map.remove(id);
    if (value != null) {
      _map[id] = value;
    }
    return value;
  }

  void put(String id, typed_data.Uint8List bytes) {
    _map.remove(id);
    _map[id] = bytes;
    while (_map.length > maxEntries) {
      _map.remove(_map.keys.first);
    }
  }

  void clear() => _map.clear();
}

/// 한 번 로드한 썸네일은 State/캐시에 유지 (FutureBuilder 재생성 금지)
class _AssetThumbnail extends StatefulWidget {
  const _AssetThumbnail({required this.asset, required this.size});

  final AssetEntity asset;
  final int size;

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  typed_data.Uint8List? _bytes;
  bool _loading = false;
  String? _loadedId;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _AssetThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id ||
        oldWidget.size != widget.size) {
      _resolve();
    }
  }

  void _resolve() {
    final id = '${widget.asset.id}_${widget.size}';
    if (_loadedId == id && _bytes != null) return;

    final cached = _ThumbnailCache.instance.get(id);
    if (cached != null) {
      _bytes = cached;
      _loadedId = id;
      _loading = false;
      return;
    }

    _loadedId = id;
    _bytes = null;
    if (_loading) return;
    _loading = true;
    unawaited(_load(id));
  }

  Future<void> _load(String id) async {
    try {
      final bytes = await widget.asset.thumbnailDataWithSize(
        ThumbnailSize.square(widget.size),
      );
      if (!mounted) return;
      if (id != '${widget.asset.id}_${widget.size}') return;
      if (bytes != null && bytes.isNotEmpty) {
        _ThumbnailCache.instance.put(id, bytes);
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null || bytes.isEmpty) {
      return ColoredBox(color: Theme.of(context).dividerColor);
    }
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }
}
