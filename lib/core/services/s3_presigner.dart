import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import '../config/aws_config.dart';

// Very small SigV4 presigner for S3 PutObject
// NOTE: This is intended as a development fallback only. Consider using
// Cognito or a backend signer for production.
class S3Presigner {
  static String _hashHex(Uint8List bytes) => sha256.convert(bytes).toString();
  static List<int> _hmac(List<int> key, String message) => Hmac(sha256, key).convert(utf8.encode(message)).bytes;

  static String presignPutUrl({
    required String bucket,
    required String region,
    required String key,
    required String contentType,
    Duration expires = const Duration(hours: 1),
  }) {
    final now = DateTime.now().toUtc();
    final amzDate = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
    final dateStamp = DateFormat('yyyyMMdd').format(now);

    final algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final credential = '$awsAccessKeyId/$credentialScope';

    final host = '$bucket.s3.$region.amazonaws.com';
    final canonicalUri = '/$key';

    // We will sign 'host' only, Content-Type is not included in signed headers
    final canonicalHeaders = 'host:$host\n';
    final signedHeaders = 'host';

    final isoDuration = expires.inSeconds.toString();
    final queryParams = <String, String>{
      'X-Amz-Algorithm': algorithm,
      'X-Amz-Credential': Uri.encodeComponent(credential),
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': isoDuration,
      'X-Amz-SignedHeaders': signedHeaders,
    };
    if (awsSessionToken.isNotEmpty) {
      // Session token must be present in the canonical query string for temporary creds
      queryParams['X-Amz-Security-Token'] = Uri.encodeComponent(awsSessionToken);
    }

    final sortedKeys = queryParams.keys.toList()..sort();
    final canonicalQueryString = sortedKeys
        .map((k) => '$k=${queryParams[k]}')
        .join('&');

    final payloadHash = 'UNSIGNED-PAYLOAD';

    final canonicalRequest = [
      'PUT',
      canonicalUri,
      canonicalQueryString,
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');

    final canonicalRequestHash = sha256.convert(utf8.encode(canonicalRequest)).toString();

    final stringToSign = [
      algorithm,
      amzDate,
      credentialScope,
      canonicalRequestHash,
    ].join('\n');

    // Derive signing key
    final kDate = _hmac(utf8.encode('AWS4$awsSecretAccessKey'), dateStamp);
    final kRegion = _hmac(kDate, region);
    final kService = _hmac(kRegion, 's3');
    final kSigning = _hmac(kService, 'aws4_request');

    final signature = Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();

    final url = Uri(
      scheme: 'https',
      host: host,
      path: '/$key',
      query: '$canonicalQueryString&X-Amz-Signature=$signature',
    );

    return url.toString();
  }
}

extension on Digest {
  String bytesToHex() => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
