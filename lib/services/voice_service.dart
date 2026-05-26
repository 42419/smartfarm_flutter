import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../config/config.dart';

enum VoiceState { idle, recording, recognizing }

class VoiceService {
  VoiceService._();

  static final VoiceService instance = VoiceService._();

  final AudioRecorder _recorder = AudioRecorder();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;

  final ValueNotifier<String> recognizedText = ValueNotifier('');

  Future<bool> get isAvailable async {
    return await _recorder.hasPermission();
  }

  Future<bool> startListening({
    void Function(String text)? onResult,
    void Function(String error)? onError,
  }) async {
    if (_state != VoiceState.idle) return false;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      onError?.call('未授权麦克风权限');
      return false;
    }

    try {
      recognizedText.value = '';

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _state = VoiceState.recording;

      final audioBytes = <int>[];
      await for (final chunk in stream) {
        audioBytes.addAll(chunk);
      }

      _state = VoiceState.recognizing;

      if (audioBytes.isEmpty) {
        _state = VoiceState.idle;
        onError?.call('未检测到语音');
        return false;
      }

      final text = await _sendToStt(audioBytes);
      _state = VoiceState.idle;

      if (text != null && text.isNotEmpty) {
        recognizedText.value = text;
        onResult?.call(text);
        return true;
      } else {
        onError?.call('语音识别失败');
        return false;
      }
    } catch (e) {
      _state = VoiceState.idle;
      onError?.call('录音异常: $e');
      return false;
    }
  }

  Future<String?> _sendToStt(List<int> pcm16Data) async {
    if (Config.sttApiUrl.isEmpty || Config.sttApiKey.isEmpty) {
      return null;
    }

    try {
      final base64Audio = base64Encode(Uint8List.fromList(pcm16Data));

      final resp = await _dio.post(
        Config.sttApiUrl,
        data: jsonEncode({
          'format': 'pcm',
          'rate': 16000,
          'channel': 1,
          'cuid': 'smart_farm_flutter',
          'token': Config.sttApiKey,
          'len': pcm16Data.length,
          'speech': base64Audio,
        }),
      );

      final result = resp.data;
      if (result is Map<String, dynamic>) {
        final errNo = result['err_no'];
        if (errNo != null && errNo != 0) {
          debugPrint('VoiceService: STT error $errNo ${result['err_msg']}');
          return null;
        }
        final firstResult = (result['result'] as List?)?.firstOrNull;
        return firstResult?.toString();
      }

      return null;
    } catch (e) {
      debugPrint('VoiceService: STT request failed: $e');
      return null;
    }
  }

  Future<void> stop() async {
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  void cancel() {
    try {
      _recorder.stop();
    } catch (_) {}
    _state = VoiceState.idle;
    recognizedText.value = '';
  }

  void dispose() {
    cancel();
    _recorder.dispose();
  }
}
