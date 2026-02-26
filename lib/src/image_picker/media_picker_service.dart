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
        ),
      ),
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
  });

  final int maxCount;
  final bool compress;
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final String compressFailureMessage;

  @override
  State<_ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<_ImagePickerPage> {
  final List<AssetEntity> _assets = [];
  final Set<AssetEntity> _selected = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final paths = await PhotoManager.getAssetPathList(
        hasAll: true,
        onlyAll: true,
        type: RequestType.image,
      );
      if (paths.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final recent = paths.first;
      final assets = await recent.getAssetListRange(start: 0, end: 200);
      setState(() {
        _assets
          ..clear()
          ..addAll(assets);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [MediaPickerService] 이미지 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 불러오지 못했습니다')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onCameraTap() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;

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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.compressFailureMessage)),
            );
          }
          return;
        }
        outPath = compressed.path;
      }

      if (!mounted) return;
      Navigator.of(context).pop(<XFile>[XFile(outPath)]);
    } catch (e) {
      debugPrint('❌ [MediaPickerService] 카메라 촬영 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라를 사용할 수 없습니다')),
      );
    }
  }

  void _onAssetTap(AssetEntity asset) {
    setState(() {
      if (_selected.contains(asset)) {
        _selected.remove(asset);
      } else {
        if (_selected.length >= widget.maxCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('최대 ${widget.maxCount}장까지 선택할 수 있습니다')),
          );
          return;
        }
        _selected.add(asset);
      }
    });
  }

  Future<void> _onConfirm() async {
    if (_selected.isEmpty) {
      Navigator.of(context).pop(<XFile>[]);
      return;
    }
    final dir = await getTemporaryDirectory();
    final List<XFile> files = [];
    int index = 0;
    for (final asset in _selected) {
      final file = await asset.file;
      if (file == null) continue;
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
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.compressFailureMessage)),
            );
          }
          return;
        }
      } else {
        files.add(XFile(file.path));
      }
      index++;
    }
    if (!mounted) return;
    Navigator.of(context).pop(files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 선택'),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _onConfirm,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _assets.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: _onCameraTap,
                    child: Container(
                      color: Theme.of(context).dividerColor,
                      child: const Center(
                        child: Icon(Icons.camera_enhance, size: 32),
                      ),
                    ),
                  );
                }
                final asset = _assets[index - 1];
                final selected = _selected.contains(asset);
                return GestureDetector(
                  onTap: () => _onAssetTap(asset),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AssetEntityImage(
                        asset,
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(300),
                        fit: BoxFit.cover,
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
                                color:
                                    Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
