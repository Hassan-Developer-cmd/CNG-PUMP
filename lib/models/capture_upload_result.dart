/// Represents the server response from `POST /api/v1/capture/captureImage`.
///
/// The backend returns either:
///   { "success": true,  "imageUrl": "...", "imageId": "..." }
/// or a nested data object like:
///   { "success": true, "data": { "imageUrl": "...", "_id": "..." } }
class CaptureUploadResult {
  /// Whether the upload was accepted by the server (HTTP 200 / 201).
  final bool success;

  /// The publicly accessible MongoDB GridFS or cloud URL of the stored image.
  final String? imageUrl;

  /// The MongoDB document `_id` for this upload record.
  final String? imageId;

  /// Optional server-side message returned in the response body.
  final String? message;

  const CaptureUploadResult({
    required this.success,
    this.imageUrl,
    this.imageId,
    this.message,
  });

  factory CaptureUploadResult.fromJson(Map<String, dynamic> json) {
    // Unwrap nested `data`, `images`, or `capture` if present
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final imagesMap = json['images'] is Map<String, dynamic>
        ? json['images'] as Map<String, dynamic>
        : null;
    final captureMap = json['capture'] is Map<String, dynamic>
        ? json['capture'] as Map<String, dynamic>
        : null;

    final imageUrl = data['imageUrl'] as String? ??
        data['image_url'] as String? ??
        data['url'] as String? ??
        imagesMap?['imageUrl'] as String? ??
        imagesMap?['url'] as String?;

    final imageId = data['imageId'] as String? ??
        data['image_id'] as String? ??
        data['_id'] as String? ??
        data['id'] as String? ??
        captureMap?['id'] as String? ??
        captureMap?['_id'] as String?;

    final successFromJson = json['success'] as bool? ??
        json['ok'] as bool? ??
        (json['status'] == 'success') ||
        (json['status'] == 200 || json['status'] == 201);

    final success = successFromJson ||
        imageUrl != null ||
        imageId != null ||
        json['statusCode'] == 200 ||
        json['statusCode'] == 201;

    return CaptureUploadResult(
      success: success,
      imageUrl: imageUrl,
      imageId: imageId,
      message: json['message'] as String? ?? data['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (imageId != null) 'imageId': imageId,
        if (message != null) 'message': message,
      };

  @override
  String toString() =>
      'CaptureUploadResult(success: $success, imageUrl: $imageUrl, imageId: $imageId)';
}
