// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:video_player_platform_interface/method_channel_video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$VideoPlayerPlatform', () {
    test('$MethodChannelVideoPlayer() is the default instance', () {
      expect(VideoPlayerPlatform.instance,
          isInstanceOf<MethodChannelVideoPlayer>());
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        VideoPlayerPlatform.instance = ImplementsVideoPlayerPlatform();
      }, throwsA(isInstanceOf<AssertionError>()));
    });

    test('Can be mocked with `implements`', () {
      final ImplementsVideoPlayerPlatform mock =
          ImplementsVideoPlayerPlatform();
      when(mock.isMock).thenReturn(true);
      VideoPlayerPlatform.instance = mock;
    });

    test('Can be extended', () {
      VideoPlayerPlatform.instance = ExtendsVideoPlayerPlatform();
    });
  });

  group('$MethodChannelVideoPlayer', () {
    const MethodChannel channel = MethodChannel('flutter.io/videoPlayer');
    final List<MethodCall> log = <MethodCall>[];
    final MethodChannelVideoPlayer player = MethodChannelVideoPlayer();

    setUp(() {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
      });
    });

    tearDown(() {
      log.clear();
    });

    test('init', () async {
      await player.init(100, 10);
      expect(
        log,
        <Matcher>[
          isMethodCall('init', arguments: <String, Object>{
            'maxCacheSize': 100,
            'maxCacheFileSize': 10,
          }),
        ],
      );
    });

    test('dispose', () async {
      await player.dispose(1);
      expect(
        log,
        <Matcher>[
          isMethodCall('dispose', arguments: <String, Object>{
            'textureId': 1,
          })
        ],
      );
    });

    test('create controller and set asset data source', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return <String, dynamic>{'textureId': 3};
      });
      final int textureId = await player.create();
      await player.setDataSource(
        textureId,
        DataSource(
          sourceType: DataSourceType.asset,
          asset: 'someAsset',
          package: 'somePackage',
        ),
      );
      expect(
        log,
        <Matcher>[
          isMethodCall('create', arguments: null),
          isMethodCall('setDataSource', arguments: <String, Object>{
            'textureId': 3,
            'dataSource': {
              'key': 'somePackage:someAsset',
              'asset': 'someAsset',
              'package': 'somePackage',
            },
          }),
        ],
      );
      expect(textureId, 3);
    });

    group('create controller and set network data source', () {
      test('with cache', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          log.add(methodCall);
          return <String, dynamic>{'textureId': 3};
        });
        final int textureId = await player.create();
        await player.setDataSource(
          textureId,
          DataSource(
              sourceType: DataSourceType.network,
              uri: 'someUri',
              formatHint: VideoFormat.dash,
              useCache: true),
        );
        expect(
          log,
          <Matcher>[
            isMethodCall('create', arguments: null),
            isMethodCall('setDataSource', arguments: <String, Object>{
              'textureId': 3,
              'dataSource': {
                'key': 'someUri:dash',
                'uri': 'someUri',
                'formatHint': 'dash',
                'useCache': true,
              },
            }),
          ],
        );
        expect(textureId, 3);
      });

      test('without cache', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          log.add(methodCall);
          return <String, dynamic>{'textureId': 3};
        });
        final int textureId = await player.create();
        await player.setDataSource(
          textureId,
          DataSource(
              sourceType: DataSourceType.network,
              uri: 'someUri',
              formatHint: VideoFormat.dash,
              useCache: false),
        );
        expect(
          log,
          <Matcher>[
            isMethodCall('create', arguments: null),
            isMethodCall('setDataSource', arguments: <String, Object>{
              'textureId': 3,
              'dataSource': {
                'key': 'someUri:dash',
                'uri': 'someUri',
                'formatHint': 'dash',
                'useCache': false,
              },
            }),
          ],
        );
        expect(textureId, 3);
      });

      test('without cache by default', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          log.add(methodCall);
          return <String, dynamic>{'textureId': 3};
        });
        final int textureId = await player.create();
        await player.setDataSource(
          textureId,
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'someUri',
            formatHint: VideoFormat.dash,
          ),
        );
        expect(
          log,
          <Matcher>[
            isMethodCall('create', arguments: null),
            isMethodCall('setDataSource', arguments: <String, Object>{
              'textureId': 3,
              'dataSource': {
                'key': 'someUri:dash',
                'uri': 'someUri',
                'formatHint': 'dash',
                'useCache': false,
              },
            }),
          ],
        );
        expect(textureId, 3);
      });
    });

    test('create controller and set file data source', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return <String, dynamic>{'textureId': 3};
      });
      final int textureId = await player.create();
      await player.setDataSource(
        textureId,
        DataSource(
          sourceType: DataSourceType.file,
          uri: 'someUri',
        ),
      );
      expect(
        log,
        <Matcher>[
          isMethodCall('create', arguments: null),
          isMethodCall('setDataSource', arguments: <String, Object>{
            'textureId': 3,
            'dataSource': {
              'key': 'someUri',
              'uri': 'someUri',
            },
          }),
        ],
      );
      expect(textureId, 3);
    });

    test('setLooping', () async {
      await player.setLooping(1, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('setLooping', arguments: <String, Object>{
            'textureId': 1,
            'looping': true,
          })
        ],
      );
    });

    test('play', () async {
      await player.play(1);
      expect(
        log,
        <Matcher>[
          isMethodCall('play', arguments: <String, Object>{
            'textureId': 1,
          })
        ],
      );
    });

    test('pause', () async {
      await player.pause(1);
      expect(
        log,
        <Matcher>[
          isMethodCall('pause', arguments: <String, Object>{
            'textureId': 1,
          })
        ],
      );
    });

    test('setVolume', () async {
      await player.setVolume(1, 0.7);
      expect(
        log,
        <Matcher>[
          isMethodCall('setVolume', arguments: <String, Object>{
            'textureId': 1,
            'volume': 0.7,
          })
        ],
      );
    });

    test('seekTo', () async {
      await player.seekTo(1, const Duration(milliseconds: 12345));
      expect(
        log,
        <Matcher>[
          isMethodCall('seekTo', arguments: <String, Object>{
            'textureId': 1,
            'location': 12345,
          })
        ],
      );
    });

    test('getPosition', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return 234;
      });

      final Duration position = await player.getPosition(1);
      expect(
        log,
        <Matcher>[
          isMethodCall('position', arguments: <String, Object>{
            'textureId': 1,
          })
        ],
      );
      expect(position, const Duration(milliseconds: 234));
    });

    test('videoEventsFor', () async {
      String key = "key";
      // TODO(cbenhagen): This has been deprecated and should be replaced
      // with `ServicesBinding.instance.defaultBinaryMessenger` when it's
      // available on all the versions of Flutter that we test.
      // ignore: deprecated_member_use
      defaultBinaryMessenger.setMockMessageHandler(
        "flutter.io/videoPlayer/videoEvents123",
        (ByteData message) async {
          final MethodCall methodCall =
              const StandardMethodCodec().decodeMethodCall(message);
          if (methodCall.method == 'listen') {
            // TODO(cbenhagen): This has been deprecated and should be replaced
            // with `ServicesBinding.instance.defaultBinaryMessenger` when it's
            // available on all the versions of Flutter that we test.
            // ignore: deprecated_member_use
            await defaultBinaryMessenger.handlePlatformMessage(
                "flutter.io/videoPlayer/videoEvents123",
                const StandardMethodCodec()
                    .encodeSuccessEnvelope(<String, dynamic>{
                  'key': key,
                  'event': 'initialized',
                  'duration': 98765,
                  'width': 1920,
                  'height': 1080,
                }),
                (ByteData data) {});

            // TODO(cbenhagen): This has been deprecated and should be replaced
            // with `ServicesBinding.instance.defaultBinaryMessenger` when it's
            // available on all the versions of Flutter that we test.
            // ignore: deprecated_member_use
            await defaultBinaryMessenger.handlePlatformMessage(
                "flutter.io/videoPlayer/videoEvents123",
                const StandardMethodCodec()
                    .encodeSuccessEnvelope(<String, dynamic>{
                  'key': key,
                  'event': 'completed',
                }),
                (ByteData data) {});

            // TODO(cbenhagen): This has been deprecated and should be replaced
            // with `ServicesBinding.instance.defaultBinaryMessenger` when it's
            // available on all the versions of Flutter that we test.
            // ignore: deprecated_member_use
            await defaultBinaryMessenger.handlePlatformMessage(
                "flutter.io/videoPlayer/videoEvents123",
                const StandardMethodCodec()
                    .encodeSuccessEnvelope(<String, dynamic>{
                  'key': key,
                  'event': 'bufferingUpdate',
                  'values': <List<dynamic>>[
                    <int>[0, 1234],
                    <int>[1235, 4000],
                  ],
                }),
                (ByteData data) {});

            // TODO(cbenhagen): This has been deprecated and should be replaced
            // with `ServicesBinding.instance.defaultBinaryMessenger` when it's
            // available on all the versions of Flutter that we test.
            // ignore: deprecated_member_use
            await defaultBinaryMessenger.handlePlatformMessage(
                "flutter.io/videoPlayer/videoEvents123",
                const StandardMethodCodec()
                    .encodeSuccessEnvelope(<String, dynamic>{
                  'key': key,
                  'event': 'bufferingStart',
                }),
                (ByteData data) {});

            // TODO(cbenhagen): This has been deprecated and should be replaced
            // with `ServicesBinding.instance.defaultBinaryMessenger` when it's
            // available on all the versions of Flutter that we test.
            // ignore: deprecated_member_use
            await defaultBinaryMessenger.handlePlatformMessage(
                "flutter.io/videoPlayer/videoEvents123",
                const StandardMethodCodec()
                    .encodeSuccessEnvelope(<String, dynamic>{
                  'key': key,
                  'event': 'bufferingEnd',
                }),
                (ByteData data) {});

            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else if (methodCall.method == 'cancel') {
            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else {
            fail('Expected listen or cancel');
          }
        },
      );
      expect(
          player.videoEventsFor(123),
          emitsInOrder(<dynamic>[
            VideoEvent(
              key: key,
              eventType: VideoEventType.initialized,
              duration: const Duration(milliseconds: 98765),
              size: const Size(1920, 1080),
            ),
            VideoEvent(
              key: key,
              eventType: VideoEventType.completed,
            ),
            VideoEvent(
                key: key,
                eventType: VideoEventType.bufferingUpdate,
                buffered: <DurationRange>[
                  DurationRange(
                    const Duration(milliseconds: 0),
                    const Duration(milliseconds: 1234),
                  ),
                  DurationRange(
                    const Duration(milliseconds: 1235),
                    const Duration(milliseconds: 4000),
                  ),
                ]),
            VideoEvent(
              key: key,
              eventType: VideoEventType.bufferingStart,
            ),
            VideoEvent(
              key: key,
              eventType: VideoEventType.bufferingEnd,
            ),
          ]));
    });
  });
}

class ImplementsVideoPlayerPlatform extends Mock
    implements VideoPlayerPlatform {}

class ExtendsVideoPlayerPlatform extends VideoPlayerPlatform {}
