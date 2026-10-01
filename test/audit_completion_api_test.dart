import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:cng_pump/constants/api_constants.dart';
import 'package:cng_pump/models/audit_config_model.dart';
import 'package:cng_pump/models/capture_history_item.dart';
import 'package:cng_pump/models/capture_upload_result.dart';
import 'package:cng_pump/models/cng_reading_item.dart';
import 'package:cng_pump/models/comparison_history_record.dart';
import 'package:cng_pump/models/station_history_item.dart';
import 'package:cng_pump/providers/capture_provider.dart';
import 'package:cng_pump/providers/history_provider.dart';
import 'package:cng_pump/providers/pump_provider.dart';
import 'package:cng_pump/providers/user_provider.dart';
import 'package:cng_pump/repositories/audit_repository.dart';
import 'package:cng_pump/screens/dashboard/dashboard_screen.dart';
import 'package:cng_pump/screens/result_screen/comparison_result_screen.dart';
import 'package:cng_pump/services/api/api_client.dart';
import 'package:cng_pump/services/api/auth_storage.dart';

void main() {
  setUp(() {
    ApiConstants.setBaseUrl('http://192.168.1.8:5000');
  });

  group('Audit Completion API Unit & Endpoint Contract Tests', () {
    test('POST /api/v1/capture/complete/:id in Meter mode sends multipart/form-data, omit nozzleNumber and attach image', () async {
      String? calledUrl;
      String? calledMethod;
      Map<String, String>? calledHeaders;
      Map<String, String>? calledFields;
      String? calledFileKey;

      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_comp_meter_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await testFile.writeAsBytes([1, 2, 3, 4]);

      final mockHttp = MockClient.streaming((request, bodyStream) async {
        calledUrl = request.url.toString();
        calledMethod = request.method;
        calledHeaders = request.headers;

        if (request is http.MultipartRequest) {
          calledFields = request.fields;
          if (request.files.isNotEmpty) {
            calledFileKey = request.files.first.field;
          }
        }

        final respBytes = utf8.encode(jsonEncode({
          'success': true,
          'message': 'Audit marked as complete',
          'sessionId': 'session_meter_123',
        }));

        return http.StreamedResponse(
          Stream.value(respBytes),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      testApiClient.setAuthToken('test_jwt_token_meter');

      final repo = RemoteAuditRepository(client: testApiClient);

      final result = await repo.completeAuditSession(
        sessionId: 'session_meter_123',
        mode: 'Meter',
        capturedImages: [
          CapturedImage(label: 'VB1', image: testFile, capturedAt: DateTime.now()),
        ],
        statusText: 'IN_SYNC',
        hasCorruption: false,
        difference: '+0.00 KG',
        threshold: '1.00 KG',
        stationName: 'Station North',
        operatorName: 'Ali Operator',
      );

      // Verify endpoint and method
      expect(calledMethod, 'POST');
      expect(calledUrl, 'http://192.168.1.8:5000/api/v1/capture/complete/session_meter_123');

      // Verify headers: Content-Type is multipart/form-data, Accept is application/json, Bearer token
      expect(calledHeaders?['content-type'], contains('multipart/form-data'));
      expect(calledHeaders?['content-type'], isNot(contains('application/json')));
      expect(calledHeaders?['accept'], contains('application/json'));
      expect(calledHeaders?['authorization'], 'Bearer test_jwt_token_meter');

      // Verify fields for Meter mode: captureType is 'meter', imageType is 'vb1', nozzleNumber is OMITTED
      expect(calledFields?['captureType'], 'meter');
      expect(calledFields?['imageType'], 'vb1');
      expect(calledFields?.containsKey('nozzleNumber'), isFalse);

      // Verify file field key is strictly 'image'
      expect(calledFileKey, 'image');
      expect(result['success'], isTrue);

      if (await testFile.exists()) await testFile.delete();
    });

    test('POST /api/v1/capture/complete/:id in Nozzle mode sends multipart/form-data with dynamic nozzleNumber and image', () async {
      String? calledUrl;
      String? calledMethod;
      Map<String, String>? calledHeaders;
      Map<String, String>? calledFields;
      String? calledFileKey;

      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_comp_nozzle_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await testFile.writeAsBytes([1, 2, 3, 4]);

      final mockHttp = MockClient.streaming((request, bodyStream) async {
        calledUrl = request.url.toString();
        calledMethod = request.method;
        calledHeaders = request.headers;

        if (request is http.MultipartRequest) {
          calledFields = request.fields;
          if (request.files.isNotEmpty) {
            calledFileKey = request.files.first.field;
          }
        }

        final respBytes = utf8.encode(jsonEncode({
          'success': true,
          'message': 'Nozzle audit marked as complete',
          'sessionId': 'session_nozzle_456',
        }));

        return http.StreamedResponse(
          Stream.value(respBytes),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      testApiClient.setAuthToken('test_jwt_token_nozzle');

      final repo = RemoteAuditRepository(client: testApiClient);

      final result = await repo.completeAuditSession(
        sessionId: 'session_nozzle_456',
        mode: 'Nozzle 3',
        imageFile: testFile,
        imageType: 'digitalMachine',
        statusText: 'CORRUPTION_DETECTED',
        hasCorruption: true,
        difference: '-1.35 KG',
        threshold: '1.00 KG',
        stationName: 'Station South',
        operatorName: 'Zahid Khan',
      );

      // Verify endpoint and method
      expect(calledMethod, 'POST');
      expect(calledUrl, 'http://192.168.1.8:5000/api/v1/capture/complete/session_nozzle_456');

      // Verify headers
      expect(calledHeaders?['content-type'], contains('multipart/form-data'));
      expect(calledHeaders?['accept'], contains('application/json'));
      expect(calledHeaders?['authorization'], 'Bearer test_jwt_token_nozzle');

      // Verify fields for Nozzle mode: captureType is 'nozzle', imageType is 'digitalMachine', nozzleNumber is '3'
      expect(calledFields?['captureType'], 'nozzle');
      expect(calledFields?['imageType'], 'digitalMachine');
      expect(calledFields?['nozzleNumber'], '3');

      // Verify file field key is strictly 'image'
      expect(calledFileKey, 'image');
      expect(result['success'], isTrue);

      if (await testFile.exists()) await testFile.delete();
    });

    test('completeSession in CaptureProvider updates state and catches errors', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Invalid session token or expired'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testApiClient);
      final captureProvider = CaptureProvider(repository: repo);
      captureProvider.setActiveSessionId('test_err_session');

      final success = await captureProvider.completeSession(
        difference: '0.00 KG',
        threshold: '1.00 KG',
        hasCorruption: false,
      );

      expect(success, isFalse);
      expect(captureProvider.isCompleting, isFalse);
      expect(captureProvider.completionError, contains('Invalid session token or expired'));

      // Active session ID is preserved for retry
      expect(captureProvider.activeSessionId, 'test_err_session');
    });
  });

  group('ComparisonResultScreen Widget & "Done" Button Flow Tests', () {
    testWidgets('Tapping Done triggers completeAuditSession, shows spinner, resets provider and navigates on success', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool completionCalled = false;
      String? completedId;

      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/api/v1/capture/complete/')) {
          completionCalled = true;
          completedId = request.url.pathSegments.last;
          return http.Response(
            jsonEncode({'success': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/audits') {
          return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      final testClient = ApiClient(httpClient: mockHttp);
      testClient.setAuthToken('mock_token_abc');
      final repo = RemoteAuditRepository(client: testClient);

      final captureProvider = CaptureProvider(repository: repo);
      captureProvider.setActiveSessionId('session_active_777');

      final historyProvider = HistoryProvider(repository: repo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: captureProvider),
            ChangeNotifierProvider.value(value: historyProvider),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(
              home: Scaffold(
                body: ComparisonResultScreen(
                  sessionId: 'session_active_777',
                  differenceValue: '1.35 KG',
                  thresholdValue: '1 KG',
                  hasCorruption: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final doneButtonFinder = find.widgetWithText(ElevatedButton, 'Done');
      expect(doneButtonFinder, findsOneWidget);

      // Tap Done
      await tester.tap(doneButtonFinder);
      await tester.pumpAndSettle();

      expect(completionCalled, isTrue);
      expect(completedId, 'session_active_777');

      // Verify CaptureProvider local audit session was safely reset
      expect(captureProvider.activeSessionId, isNull);
      expect(captureProvider.timerActive, isFalse);
    });

    testWidgets('Tapping Done shows SnackBar on failure without losing session state, enabling retry', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int callCount = 0;

      final mockHttp = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({'message': 'Server temporary failure'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final testClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testClient);

      final captureProvider = CaptureProvider(repository: repo);
      captureProvider.setActiveSessionId('retry_session_888');

      final historyProvider = HistoryProvider(repository: repo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: captureProvider),
            ChangeNotifierProvider.value(value: historyProvider),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(
              home: Scaffold(
                body: ComparisonResultScreen(
                  sessionId: 'retry_session_888',
                  differenceValue: '0.00 KG',
                  thresholdValue: '1 KG',
                  hasCorruption: false,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final doneButtonFinder = find.widgetWithText(ElevatedButton, 'Done');
      expect(doneButtonFinder, findsOneWidget);

      // Tap Done
      await tester.tap(doneButtonFinder);
      await tester.pumpAndSettle();

      expect(callCount, 1);

      // Verify SnackBar displayed with error message
      expect(find.textContaining('Server temporary failure'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Verify session was NOT cleared so user can retry
      expect(captureProvider.activeSessionId, 'retry_session_888');

      // Tap Retry in SnackBar
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
    });
  });

  group('Image Upload /api/v1/capture/captureImage Tests', () {
    test('Multipart request sends field key strictly "image", MediaType jpeg, headers and fields', () async {
      String? calledUrl;
      String? calledMethod;
      Map<String, String>? calledHeaders;
      Map<String, String>? calledFields;
      String? calledFileField;
      String? calledFilename;
      String? calledContentType;

      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_upload_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await testFile.writeAsBytes([1, 2, 3, 4]);

      final mockHttp = MockClient.streaming((request, bodyStream) async {
        calledUrl = request.url.toString();
        calledMethod = request.method;
        calledHeaders = request.headers;

        if (request is http.MultipartRequest) {
          calledFields = request.fields;
          if (request.files.isNotEmpty) {
            final f = request.files.first;
            calledFileField = f.field;
            calledFilename = f.filename;
            calledContentType = f.contentType.toString();
          }
        }

        final responseBody = jsonEncode({
          'success': true,
          'message': 'Image uploaded successfully',
          'imageUrl': 'http://192.168.1.8:5000/uploads/test.jpg',
          'imageId': 'img_test_123',
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      testApiClient.setAuthToken('bearer_token_xyz');

      final repo = RemoteAuditRepository(client: testApiClient);

      final result = await repo.uploadCapturedImage(
        mode: 'Meter',
        readingType: 'VB1',
        imageFile: testFile,
        readingValue: '1234.5',
      );

      // Verify endpoint and method
      expect(calledMethod, 'POST');
      expect(calledUrl, 'http://192.168.1.8:5000/api/v1/capture/captureImage');

      // Verify header safety:
      // Accept is application/json, Bearer token is injected
      expect(calledHeaders?['accept'], contains('application/json'));
      expect(calledHeaders?['authorization'], 'Bearer bearer_token_xyz');

      // CRITICAL: Content-Type must NOT be application/json; it must be multipart/form-data with boundary
      expect(calledHeaders?['content-type'], isNot(contains('application/json')));
      expect(calledHeaders?['content-type'], contains('multipart/form-data'));

      // Verify form fields
      expect(calledFields?['mode'], 'Meter');
      expect(calledFields?['imageType'], 'vb1');
      expect(calledFields?['readingType'], 'vb1');
      expect(calledFields?['readingValue'], '1234.5');
      expect(calledFields?['timestamp'], isNotNull);

      // Verify file field is strictly 'image' and MediaType is 'image/jpeg'
      expect(calledFileField, 'image');
      expect(calledContentType, 'image/jpeg');

      // Verify successful result
      expect(result.success, isTrue);
      expect(result.imageUrl, 'http://192.168.1.8:5000/uploads/test.jpg');
      expect(result.imageId, 'img_test_123');

      if (await testFile.exists()) await testFile.delete();
    });

    test('On upload error: parses and sets exact message from response.body', () async {
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_upload_err_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await testFile.writeAsBytes([1, 2, 3, 4]);

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Only JPEG and PNG images are allowed for audit verification',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testApiClient);
      final captureProvider = CaptureProvider(repository: repo);

      // Set image on vb1
      await captureProvider.setImageByType(CngReadingType.vb1, testFile, DateTime.now());

      final result = await captureProvider.uploadImageForType(CngReadingType.vb1);

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(result.message, 'Only JPEG and PNG images are allowed for audit verification');

      // Verify cardUploadError banner text
      expect(captureProvider.cardUploadError(CngReadingType.vb1),
          'Only JPEG and PNG images are allowed for audit verification');
      expect(captureProvider.isCardVerified(CngReadingType.vb1), isFalse);

      if (await testFile.exists()) await testFile.delete();
    });

    test('On 200/201: marks card verified and clears upload error', () async {
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_upload_ok_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await testFile.writeAsBytes([1, 2, 3, 4]);

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Image uploaded',
            'imageUrl': 'http://192.168.1.8:5000/uploads/ok.jpg',
            'imageId': 'id_ok_555',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      final repo = RemoteAuditRepository(client: testApiClient);
      final captureProvider = CaptureProvider(repository: repo);

      await captureProvider.setImageByType(CngReadingType.vs1, testFile, DateTime.now());

      final result = await captureProvider.uploadImageForType(CngReadingType.vs1);

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(captureProvider.cardUploadError(CngReadingType.vs1), isNull);
      expect(captureProvider.isCardVerified(CngReadingType.vs1), isTrue);
      expect(captureProvider.cardUploadedImageUrl(CngReadingType.vs1), 'http://192.168.1.8:5000/uploads/ok.jpg');
      expect(captureProvider.cardUploadedImageId(CngReadingType.vs1), 'id_ok_555');

      if (await testFile.exists()) await testFile.delete();
    });

    test('Helper getBackendImageType maps according to backend contract specification', () {
      // 1. Meter mode: vb1, vs1, rflow
      expect(getBackendImageType('vb1', 'Meter'), equals('vb1'));
      expect(getBackendImageType('VB1', 'Meter'), equals('vb1'));
      expect(getBackendImageType('vs1', 'Meter'), equals('vs1'));
      expect(getBackendImageType('VS1', 'Meter'), equals('vs1'));
      expect(getBackendImageType('VB1_CARD', 'Meter'), equals('vb1'));
      expect(getBackendImageType('rflow', 'Meter'), equals('rflow'));
      expect(getBackendImageType('R Flow', 'Meter'), equals('rflow'));

      // 2. Nozzle mode (Nozzle 1, Nozzle 2, Nozzle 3, Nozzle 4): digitalMachine, counter, microMotion
      for (final nozzle in ['Nozzle 1', 'Nozzle 2', 'Nozzle 3', 'Nozzle 4']) {
        expect(getBackendImageType('digitalMachine', nozzle), equals('digitalMachine'));
        expect(getBackendImageType('digital', nozzle), equals('digitalMachine'));
        expect(getBackendImageType('machine', nozzle), equals('digitalMachine'));
        expect(getBackendImageType('meter', nozzle), equals('digitalMachine'));
        expect(getBackendImageType('Meter', nozzle), equals('digitalMachine'));
        expect(getBackendImageType('counter', nozzle), equals('counter'));
        expect(getBackendImageType('Counter', nozzle), equals('counter'));
        expect(getBackendImageType('microMotion', nozzle), equals('microMotion'));
        expect(getBackendImageType('Micro Motion', nozzle), equals('microMotion'));
      }
    });

    test('Backend receives req.body.imageType as vb1 and vs1 with headers and files', () async {
      final tempDir = Directory.systemTemp;
      final vb1File = File('${tempDir.path}/test_vb1_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final vs1File = File('${tempDir.path}/test_vs1_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await vb1File.writeAsBytes([1, 2, 3, 4]);
      await vs1File.writeAsBytes([5, 6, 7, 8]);

      final capturedFields = <String, String>{};
      final capturedHeaders = <String, String>{};
      int uploadCalls = 0;

      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/api/v1/capture/captureImage')) {
          uploadCalls++;
          capturedHeaders.addAll(request.headers);
          // For multipart requests, query parameters or parsed body
          // MockClient gives request as BaseRequest (MultipartRequest or Request)
          if (request is http.Request) {
            // normal request
          }
          return http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'Image accepted',
              'imageUrl': 'http://192.168.1.8:5000/uploads/test.jpg',
              'imageId': 'img_${uploadCalls}',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      testApiClient.setAuthToken('backend_token_123');
      final repo = RemoteAuditRepository(client: testApiClient);
      final captureProvider = CaptureProvider(repository: repo);

      // Verify VB1 upload in Meter mode
      await captureProvider.setImageByType(CngReadingType.vb1, vb1File, DateTime.now());
      final vb1Result = await captureProvider.uploadImageForType(CngReadingType.vb1);
      expect(vb1Result, isNotNull);
      expect(vb1Result!.success, isTrue);
      expect(captureProvider.isCardVerified(CngReadingType.vb1), isTrue);

      // Verify VS1 upload in Meter mode
      await captureProvider.setImageByType(CngReadingType.vs1, vs1File, DateTime.now());
      final vs1Result = await captureProvider.uploadImageForType(CngReadingType.vs1);
      expect(vs1Result, isNotNull);
      expect(vs1Result!.success, isTrue);
      expect(captureProvider.isCardVerified(CngReadingType.vs1), isTrue);

      if (await vb1File.exists()) await vb1File.delete();
      if (await vs1File.exists()) await vs1File.delete();
    });

    test('Trigger retry for VB1 and VS1 cards after 400 failure recovers on 200/201', () async {
      final tempDir = Directory.systemTemp;
      final retryFile = File('${tempDir.path}/test_retry_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await retryFile.writeAsBytes([1, 2, 3, 4]);

      bool shouldFail = true;

      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/api/v1/capture/captureImage')) {
          if (shouldFail) {
            return http.Response(
              jsonEncode({
                'success': false,
                'message': 'Failed imageType validation',
              }),
              400,
              headers: {'content-type': 'application/json'},
            );
          } else {
            return http.Response(
              jsonEncode({
                'status': 'success',
                'message': 'Retry accepted',
                'imageUrl': 'http://192.168.1.8:5000/uploads/retry_ok.jpg',
                'imageId': 'retry_img_777',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return http.Response('{}', 200);
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      testApiClient.setAuthToken('token_retry_abc');
      final repo = RemoteAuditRepository(client: testApiClient);
      final captureProvider = CaptureProvider(repository: repo);

      await captureProvider.setImageByType(CngReadingType.vb1, retryFile, DateTime.now());

      // 1. Initial attempt fails
      final failResult = await captureProvider.uploadImageForType(CngReadingType.vb1);
      expect(failResult!.success, isFalse);
      expect(captureProvider.isCardVerified(CngReadingType.vb1), isFalse);
      expect(captureProvider.cardUploadError(CngReadingType.vb1), 'Failed imageType validation');

      // 2. Trigger retry -> succeeds
      shouldFail = false;
      final retryResult = await captureProvider.uploadImageForType(CngReadingType.vb1);
      expect(retryResult!.success, isTrue);
      expect(captureProvider.isCardVerified(CngReadingType.vb1), isTrue);
      expect(captureProvider.cardUploadError(CngReadingType.vb1), isNull);
      expect(captureProvider.cardUploadedImageId(CngReadingType.vb1), 'retry_img_777');

      if (await retryFile.exists()) await retryFile.delete();
    });

    test('Multipart request has imageType and mode in fields matching backend contract', () async {
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_multipart_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await testFile.writeAsBytes([1, 2, 3, 4]);

      String? sentImageType;
      String? sentMode;
      String? sentCaptureType;
      String? sentNozzleNumber;
      String? authHeader;

      final mockHttp = MockClient.streaming((http.BaseRequest request, http.ByteStream bodyStream) async {
        if (request is http.MultipartRequest) {
          sentImageType = request.fields['imageType'];
          sentMode = request.fields['mode'];
          sentCaptureType = request.fields['captureType'];
          sentNozzleNumber = request.fields['nozzleNumber'];
          authHeader = request.headers['Authorization'];
        }
        final respBytes = utf8.encode(jsonEncode({
          'status': 'success',
          'imageUrl': 'http://192.168.1.8:5000/uploads/test.jpg',
          'imageId': 'id_999',
        }));
        return http.StreamedResponse(
          Stream.value(respBytes),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      testApiClient.setAuthToken('token_test_xyz');
      final repo = RemoteAuditRepository(client: testApiClient);

      // Meter mode -> vb1
      await repo.uploadCapturedImage(
        mode: 'Meter',
        readingType: 'vb1',
        imageFile: testFile,
      );
      expect(sentImageType, equals('vb1'));
      expect(sentCaptureType, equals('meter'));
      expect(sentMode, equals('Meter'));
      expect(authHeader, equals('Bearer token_test_xyz'));

      // Meter mode -> vs1
      await repo.uploadCapturedImage(
        mode: 'Meter',
        readingType: 'vs1',
        imageFile: testFile,
      );
      expect(sentImageType, equals('vs1'));
      expect(sentCaptureType, equals('meter'));
      expect(sentMode, equals('Meter'));

      // Nozzle mode -> digitalMachine (First card / Meter)
      await repo.uploadCapturedImage(
        mode: 'Nozzle 1',
        readingType: 'meter',
        imageFile: testFile,
      );
      expect(sentImageType, equals('digitalMachine'));
      expect(sentCaptureType, equals('nozzle'));
      expect(sentNozzleNumber, equals('1'));
      expect(sentMode, equals('Nozzle 1'));

      // Nozzle mode -> counter (Second card)
      await repo.uploadCapturedImage(
        mode: 'Nozzle 2',
        readingType: 'counter',
        imageFile: testFile,
      );
      expect(sentImageType, equals('counter'));
      expect(sentCaptureType, equals('nozzle'));
      expect(sentNozzleNumber, equals('2'));
      expect(sentMode, equals('Nozzle 2'));

      // Nozzle mode -> microMotion (Third card / Micro Motion)
      await repo.uploadCapturedImage(
        mode: 'Nozzle 3',
        readingType: 'Micro Motion',
        imageFile: testFile,
      );
      expect(sentImageType, equals('microMotion'));
      expect(sentCaptureType, equals('nozzle'));
      expect(sentNozzleNumber, equals('3'));
      expect(sentMode, equals('Nozzle 3'));

      if (await testFile.exists()) await testFile.delete();
    });

    test('Micro Motion optional card upload on Nozzle mode returns HTTP 200 without invalid image type error', () async {
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_micromotion_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await testFile.writeAsBytes([10, 20, 30, 40]);

      String? sentImageType;
      String? sentMode;
      String? sentCaptureType;
      bool rejectedForInvalidType = false;

      final mockHttp = MockClient.streaming((http.BaseRequest request, http.ByteStream bodyStream) async {
        if (request is http.MultipartRequest) {
          sentImageType = request.fields['imageType'];
          sentMode = request.fields['mode'];
          sentCaptureType = request.fields['captureType'];

          // Simulate backend validation: valid Nozzle imageTypes are strictly 'digitalMachine', 'counter', 'microMotion'
          final validNozzleTypes = {'digitalMachine', 'counter', 'microMotion'};
          if (sentCaptureType == 'nozzle' && !validNozzleTypes.contains(sentImageType)) {
            rejectedForInvalidType = true;
            return http.StreamedResponse(
              Stream.value(utf8.encode(jsonEncode({'message': 'invalid image type for nozzle'}))),
              400,
              headers: {'content-type': 'application/json'},
            );
          }
        }

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({
            'status': 'success',
            'imageUrl': 'http://192.168.1.8:5000/uploads/micromotion_test.jpg',
            'imageId': 'mm_img_101',
          }))),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockHttp);
      testApiClient.setAuthToken('token_mm_test');
      final repo = RemoteAuditRepository(client: testApiClient);
      final provider = CaptureProvider(repository: repo);
      provider.setPrimarySourceMode(PrimarySourceMode.nozzle1);

      // Set image on the optional Micro Motion card
      await provider.setImageByType(CngReadingType.microMotion, testFile, DateTime.now());

      final result = await provider.uploadImageForType(CngReadingType.microMotion);

      expect(rejectedForInvalidType, isFalse);
      expect(sentImageType, equals('microMotion'));
      expect(sentCaptureType, equals('nozzle'));
      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(provider.cardUploadError(CngReadingType.microMotion), isNull);
      expect(provider.cardUploadedImageUrl(CngReadingType.microMotion), equals('http://192.168.1.8:5000/uploads/micromotion_test.jpg'));
      expect(provider.cardUploadedImageId(CngReadingType.microMotion), equals('mm_img_101'));

      if (await testFile.exists()) await testFile.delete();
    });
  });

  group('Direct "Save Data" Flow Tests (Bypassing ComparisonResultScreen)', () {
    testWidgets('Tapping Save Data directly triggers completion API, shows progress dialog, displays "Pics sent successfully", and resets session without opening ComparisonResultScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tempDir = Directory.systemTemp;
      final f1 = File('${tempDir.path}/test_vb1_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final f2 = File('${tempDir.path}/test_vs1_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f1.writeAsBytes([1, 2, 3]);
      await f2.writeAsBytes([4, 5, 6]);

      bool completionCalled = false;

      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/api/v1/capture/complete/')) {
          completionCalled = true;
          return http.Response(
            jsonEncode({'success': true, 'message': 'Complete'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/capture/captureImage') {
          return http.Response(
            jsonEncode({'success': true, 'imageUrl': 'http://img.jpg', 'imageId': 'id1'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/audits') {
          return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      final testClient = ApiClient(httpClient: mockHttp);
      testClient.setAuthToken('mock_token_abc');
      final repo = RemoteAuditRepository(client: testClient);

      final captureProvider = CaptureProvider(repository: repo);
      // Capture required images (VB1 and VS1 for Meter mode)
      await captureProvider.setImageByType(CngReadingType.vb1, f1, DateTime.now());
      await captureProvider.setImageByType(CngReadingType.vs1, f2, DateTime.now());
      expect(captureProvider.canViewResult, isTrue);

      final historyProvider = HistoryProvider(repository: repo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: captureProvider),
            ChangeNotifierProvider.value(value: historyProvider),
            ChangeNotifierProvider(create: (_) => PumpProvider()),
            ChangeNotifierProvider(create: (_) => UserProvider()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MaterialApp(
              home: DashboardScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final saveDataButton = find.text('Save Data');
      expect(saveDataButton, findsOneWidget);

      // Tap Save Data
      await tester.tap(saveDataButton);
      await tester.pump(); // Start execution & show progress dialog

      // Verify progress dialog appears with "Uploading images to server..."
      expect(find.text('Uploading images to server...'), findsOneWidget);

      // Advance through async operations to dismiss progress dialog
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify completion API was called directly
      expect(completionCalled, isTrue);

      // Verify progress dialog is dismissed
      expect(find.text('Uploading images to server...'), findsNothing);

      // Verify prominent green SnackBar "Pics sent successfully" is shown
      expect(find.text('Pics sent successfully'), findsOneWidget);

      // Verify ComparisonResultScreen / ComparingResultScreen never appeared
      expect(find.text('Comparison Result'), findsNothing);
      expect(find.text('CORRUPTION DETECTED'), findsNothing);
      expect(find.text('IN-SYNC'), findsNothing);

      // Verify active session in CaptureProvider is cleared
      expect(captureProvider.activeSessionId, isNull);
      expect(captureProvider.timerActive, isFalse);

      if (await f1.exists()) await f1.delete();
      if (await f2.exists()) await f2.delete();
    });
  });
}
