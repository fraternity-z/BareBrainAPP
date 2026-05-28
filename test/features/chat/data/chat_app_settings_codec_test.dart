import 'package:bare_brain_app/src/features/chat/data/models/chat_app_settings_codec.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatAppSettingsCodec', () {
    test('round trips all app settings sections', () {
      const settings = ChatAppSettings(
        voice: ChatVoiceSettings(
          enabled: true,
          provider: ChatVoiceProvider.custom,
          endpoint: 'https://voice.example.com',
          speaker: 'alice',
          streaming: false,
          timeout: Duration(seconds: 12),
        ),
        quickPhrases: <ChatQuickPhrase>[
          ChatQuickPhrase(
            id: 'phrase-1',
            title: '开场白',
            content: '你好',
          ),
        ],
        networkProxy: ChatNetworkProxySettings(
          enabled: true,
          type: ChatNetworkProxyType.http,
          server: '127.0.0.1',
          port: 1080,
          username: 'u',
          password: 'p',
          bypassRules: <String>['localhost'],
          testUrl: 'https://example.com',
        ),
        worldBook: ChatWorldBookSettings(
          enabled: true,
          maxActiveEntries: 3,
          entries: <ChatWorldBookEntry>[
            ChatWorldBookEntry(
              id: 'world-1',
              title: '地点',
              content: '在实验室。',
              keywords: <String>['实验室'],
            ),
          ],
        ),
        promptInjection: ChatPromptInjectionSettings(
          enabled: true,
          rules: <ChatPromptInjectionRule>[
            ChatPromptInjectionRule(
              id: 'prompt-1',
              title: '风格',
              content: '保持简洁。',
              position: ChatPromptInjectionPosition.userPrefix,
            ),
          ],
        ),
        storage: ChatStorageSettings(
          retentionPolicy: ChatStorageRetentionPolicy.ninetyDays,
          maxLocalConversations: 30,
        ),
      );

      final decoded = ChatAppSettingsCodec.decode(
        ChatAppSettingsCodec.encode(settings),
      );

      expect(decoded, settings);
    });

    test('falls back to defaults for malformed optional fields', () {
      final settings = ChatAppSettingsCodec.fromJson(<String, dynamic>{
        'voice': <String, dynamic>{'provider': 'missing'},
        'networkProxy': <String, dynamic>{'port': -1},
        'quickPhrases': <Object?>[
          <String, dynamic>{'title': 'missing id'},
        ],
      });

      expect(settings.voice.provider, ChatVoiceProvider.custom);
      expect(settings.networkProxy.port, 1);
      expect(settings.networkProxy.bypassRules, isNotEmpty);
      expect(settings.quickPhrases, isEmpty);
    });

    test('normalizes imported lists and drops blank setting records', () {
      final settings = ChatAppSettingsCodec.fromJson(<String, dynamic>{
        'voice': <String, dynamic>{
          'endpoint': ' https://voice.example.com ',
          'speaker': ' ',
        },
        'quickPhrases': <Object?>[
          <String, dynamic>{
            'id': ' phrase-1 ',
            'title': ' 开场白 ',
            'content': ' 你好 ',
          },
          <String, dynamic>{
            'id': 'phrase-blank',
            'title': ' ',
            'content': '忽略',
          },
        ],
        'networkProxy': <String, dynamic>{
          'username': ' user ',
          'testUrl': ' ',
          'bypassRules': <Object?>[' localhost ', '', 42],
        },
        'worldBook': <String, dynamic>{
          'entries': <Object?>[
            <String, dynamic>{
              'id': ' world-1 ',
              'title': ' 实验室 ',
              'content': ' 位于三楼 ',
              'keywords': <Object?>[' 实验室 ', '', 42],
            },
          ],
        },
        'promptInjection': <String, dynamic>{
          'rules': <Object?>[
            <String, dynamic>{
              'id': ' prompt-1 ',
              'title': ' 风格 ',
              'content': ' 保持简洁 ',
            },
            <String, dynamic>{
              'id': 'prompt-blank',
              'title': '空白',
              'content': '',
            },
          ],
        },
      });

      expect(settings.quickPhrases, hasLength(1));
      expect(settings.voice.endpoint, 'https://voice.example.com');
      expect(settings.voice.speaker, '默认');
      expect(settings.quickPhrases.single.id, 'phrase-1');
      expect(settings.quickPhrases.single.title, '开场白');
      expect(settings.networkProxy.username, 'user');
      expect(settings.networkProxy.testUrl, 'https://example.com');
      expect(settings.networkProxy.bypassRules, <String>['localhost']);
      expect(settings.worldBook.entries.single.keywords, <String>['实验室']);
      expect(settings.promptInjection.rules, hasLength(1));
      expect(settings.promptInjection.rules.single.content, '保持简洁');
    });
  });
}
