import 'dart:convert';
import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_service_impl.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_failures.dart';
import 'package:daftary/features/ai_assistant/domain/entities/tool_result.dart';
import 'package:daftary/features/ai_assistant/domain/services/ai_service.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _key = 'sk-SECRET-test-key-0123456789';
const _system = 'SYSTEM PREAMBLE';
const _customId = 'custom:https://llm.example.com/v1|my-model';

/// Every OpenAI-compatible provider id under test.
const _openAiCompatibleIds = ['openai', 'gemini', 'openrouter', _customId];
const _allIds = [..._openAiCompatibleIds, 'anthropic'];

const _toolCallRequest = AIToolCallRequest(
  id: 'call_1',
  toolName: AIToolNames.getCategorySpend,
  arguments: {
    'period': {'preset': 'thisMonth'},
    'categoryName': 'Food',
  },
);

const _toolResult = ToolResult(
  toolName: AIToolNames.getCategorySpend,
  sourceUseCase: 'GetCategoryBreakdown',
  data: {'category': 'Food', 'amountMinorUnits': 350000},
  foundData: true,
);

bool _isAnthropic(String id) => id == 'anthropic';

/// A successful final-answer body in [providerId]'s wire format.
String _answerBody(String providerId, String text) => _isAnthropic(providerId)
    ? jsonEncode({
        'type': 'message',
        'role': 'assistant',
        'content': [
          {'type': 'text', 'text': text},
        ],
        'stop_reason': 'end_turn',
      })
    : jsonEncode({
        'choices': [
          {
            'index': 0,
            'message': {'role': 'assistant', 'content': text},
            'finish_reason': 'stop',
          },
        ],
      });

/// A successful tool-call body in [providerId]'s wire format.
String _toolCallBody(
  String providerId, {
  String toolName = AIToolNames.getCategorySpend,
  Object? openAiArguments,
}) => _isAnthropic(providerId)
    ? jsonEncode({
        'type': 'message',
        'content': [
          {'type': 'text', 'text': 'Let me check.'},
          {
            'type': 'tool_use',
            'id': 'toolu_1',
            'name': toolName,
            'input': {
              'period': {'preset': 'thisMonth'},
            },
          },
        ],
        'stop_reason': 'tool_use',
      })
    : jsonEncode({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': null,
              'tool_calls': [
                {
                  'id': 'call_1',
                  'type': 'function',
                  'function': {
                    'name': toolName,
                    'arguments':
                        openAiArguments ??
                        jsonEncode({
                          'period': {'preset': 'thisMonth'},
                        }),
                  },
                },
              ],
            },
          },
        ],
      });

class _Harness {
  _Harness(MockClientHandler handler, {Duration? timeout}) {
    client = MockClient((request) {
      requests.add(request);
      return handler(request);
    });
    service = timeout == null
        ? AIServiceImpl(client)
        : AIServiceImpl.withTimeout(client, timeout);
  }

  final requests = <http.Request>[];
  late final MockClient client;
  late final AIServiceImpl service;

  Map<String, Object?> get lastBody =>
      jsonDecode(requests.last.body) as Map<String, Object?>;

  Future<Either<Failure, AITurnResult>> send(
    String providerId, {
    String apiKey = _key,
    List<AITurnMessage> context = const [],
    List<AITurnMessage> toolExchange = const [],
    String systemPrompt = _system,
    List<AIToolDeclaration>? tools,
  }) => service.sendTurn(
    providerId: providerId,
    apiKey: apiKey,
    context: context,
    question: 'How much did I spend on food?',
    availableTools: tools ?? aiToolCatalog,
    toolExchange: toolExchange,
    systemPrompt: systemPrompt,
  );
}

_Harness _respond(int status, String body) =>
    _Harness((_) async => http.Response(body, status));

void _expectFailure<T extends AIAssistantFailure>(
  Either<Failure, AITurnResult> result,
) {
  final failure = result.fold(
    (f) => f,
    (r) => fail('expected failure, got $r'),
  );
  expect(failure, isA<T>());
  expect(failure.message, isNot(contains(_key)));
  expect(failure.toString(), isNot(contains(_key)));
}

void main() {
  group('OpenAI-compatible adapter', () {
    for (final id in _openAiCompatibleIds) {
      group(id, () {
        test(
          'request shape: endpoint, auth header, system, messages, tools',
          () async {
            final h = _Harness(
              (_) async => http.Response(_answerBody(id, 'ok'), 200),
            );
            await h.send(
              id,
              context: const [
                AITurnMessage.user('earlier q'),
                AITurnMessage.assistant('earlier a'),
              ],
            );

            final req = h.requests.single;
            final config = AIProviderRegistry.resolve(id)!;
            expect(req.method, 'POST');
            expect(req.url, config.endpoint);
            expect(req.url.path, endsWith('/chat/completions'));
            expect(req.url.hasQuery, isFalse);
            expect(req.headers['Authorization'], 'Bearer $_key');
            expect(req.headers['Content-Type'], startsWith('application/json'));

            final body = h.lastBody;
            expect(body['model'], config.model);
            expect(body['messages'], [
              {'role': 'system', 'content': _system},
              {'role': 'user', 'content': 'earlier q'},
              {'role': 'assistant', 'content': 'earlier a'},
              {'role': 'user', 'content': 'How much did I spend on food?'},
            ]);
            final tools = body['tools']! as List;
            expect(tools, hasLength(aiToolCatalog.length));
            expect(tools.first, {
              'type': 'function',
              'function': {
                'name': aiToolCatalog.first.name,
                'description': aiToolCatalog.first.description,
                'parameters': jsonDecode(
                  jsonEncode(aiToolCatalog.first.parametersSchema),
                ),
              },
            });
          },
        );

        test('parses a final answer', () async {
          final h = _Harness(
            (_) async => http.Response(_answerBody(id, ' 3,500 EGP '), 200),
          );
          expect(
            await h.send(id),
            const Right<Failure, AITurnResult>(
              AITurnResult.answer('3,500 EGP'),
            ),
          );
        });

        test('parses a tool call (JSON-string arguments)', () async {
          final h = _Harness(
            (_) async => http.Response(_toolCallBody(id), 200),
          );
          final result = (await h.send(id)).getOrElse((f) => fail('$f'));
          expect(result.requestsToolCalls, isTrue);
          expect(
            result.toolCalls.single,
            const AIToolCallRequest(
              id: 'call_1',
              toolName: AIToolNames.getCategorySpend,
              arguments: {
                'period': {'preset': 'thisMonth'},
              },
            ),
          );
        });
      });
    }

    test('serializes the tool exchange; tool results as JSON', () async {
      final h = _Harness(
        (_) async => http.Response(_answerBody('openai', 'done'), 200),
      );
      await h.send(
        'openai',
        toolExchange: const [
          AITurnMessage.toolCallRequest([_toolCallRequest]),
          AITurnMessage.toolResult(
            toolCallId: 'call_1',
            toolResult: _toolResult,
          ),
        ],
      );
      final messages = h.lastBody['messages']! as List;
      final assistant = messages[messages.length - 2] as Map;
      final tool = messages.last as Map;

      expect(assistant['role'], 'assistant');
      final call = (assistant['tool_calls'] as List).single as Map;
      expect(call['id'], 'call_1');
      expect(call['type'], 'function');
      expect(call['function']['name'], AIToolNames.getCategorySpend);
      expect(call['function']['arguments'], isA<String>());
      expect(
        jsonDecode(call['function']['arguments'] as String),
        _toolCallRequest.arguments,
      );

      expect(tool['role'], 'tool');
      expect(tool['tool_call_id'], 'call_1');
      expect(jsonDecode(tool['content'] as String), {
        'toolName': AIToolNames.getCategorySpend,
        'foundData': true,
        'data': {'category': 'Food', 'amountMinorUnits': 350000},
      });
    });

    test('foundData=false is serialized, sourceUseCase is not', () async {
      final h = _Harness(
        (_) async => http.Response(_answerBody('openai', 'none'), 200),
      );
      await h.send(
        'openai',
        toolExchange: const [
          AITurnMessage.toolCallRequest([_toolCallRequest]),
          AITurnMessage.toolResult(
            toolCallId: 'call_1',
            toolResult: ToolResult(
              toolName: AIToolNames.getPersonBalance,
              sourceUseCase: 'GetPersonBalance',
              data: {},
              foundData: false,
            ),
          ),
        ],
      );
      final content =
          ((h.lastBody['messages']! as List).last as Map)['content'];
      expect(jsonDecode(content as String), {
        'toolName': AIToolNames.getPersonBalance,
        'foundData': false,
        'data': <String, Object?>{},
      });
      expect(content, isNot(contains('GetPersonBalance')));
    });

    test('omits system message and tools when empty', () async {
      final h = _Harness(
        (_) async => http.Response(_answerBody('openai', 'x'), 200),
      );
      await h.send('openai', systemPrompt: '', tools: const []);
      final body = h.lastBody;
      expect(body.containsKey('tools'), isFalse);
      expect((body['messages']! as List).single, {
        'role': 'user',
        'content': 'How much did I spend on food?',
      });
    });

    test('accepts list-of-parts content and empty-string arguments', () async {
      var h = _Harness(
        (_) async => http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': [
                    {'type': 'text', 'text': 'Hello '},
                    {'type': 'text', 'text': 'there'},
                  ],
                },
              },
            ],
          }),
          200,
        ),
      );
      expect(
        (await h.send('openai')).getOrElse((f) => fail('$f')).answer,
        'Hello there',
      );

      h = _Harness(
        (_) async => http.Response(
          _toolCallBody(
            'openai',
            toolName: AIToolNames.getOwedOverview,
            openAiArguments: '',
          ),
          200,
        ),
      );
      expect(
        (await h.send(
          'openai',
        )).getOrElse((f) => fail('$f')).toolCalls.single.arguments,
        isEmpty,
      );
    });

    test('decodes UTF-8 Arabic answers', () async {
      final h = _Harness(
        (_) async => http.Response.bytes(
          utf8.encode(_answerBody('openai', 'صرفت ٣٥٠٠ جنيه')),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      expect(
        (await h.send('openai')).getOrElse((f) => fail('$f')).answer,
        'صرفت ٣٥٠٠ جنيه',
      );
    });
  });

  group('Anthropic adapter', () {
    test('request shape: headers, system field, tools, max_tokens', () async {
      final h = _Harness(
        (_) async => http.Response(_answerBody('anthropic', 'ok'), 200),
      );
      await h.send('anthropic');

      final req = h.requests.single;
      expect(req.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(req.headers['x-api-key'], _key);
      expect(req.headers['anthropic-version'], '2023-06-01');
      expect(req.headers.containsKey('Authorization'), isFalse);

      final body = h.lastBody;
      expect(body['model'], AIProviderRegistry.anthropic.defaultModel);
      expect(body['max_tokens'], isA<int>());
      expect(body['system'], _system);
      expect(body['messages'], [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'How much did I spend on food?'},
          ],
        },
      ]);
      final tools = body['tools']! as List;
      expect(tools, hasLength(aiToolCatalog.length));
      expect(tools.first, {
        'name': aiToolCatalog.first.name,
        'description': aiToolCatalog.first.description,
        'input_schema': jsonDecode(
          jsonEncode(aiToolCatalog.first.parametersSchema),
        ),
      });
    });

    test(
      'serializes tool exchange; merges tool results into one user turn',
      () async {
        final h = _Harness(
          (_) async => http.Response(_answerBody('anthropic', 'ok'), 200),
        );
        await h.send(
          'anthropic',
          toolExchange: const [
            AITurnMessage.toolCallRequest([
              _toolCallRequest,
              AIToolCallRequest(
                id: 'call_2',
                toolName: AIToolNames.getOwedOverview,
                arguments: {},
              ),
            ]),
            AITurnMessage.toolResult(
              toolCallId: 'call_1',
              toolResult: _toolResult,
            ),
            AITurnMessage.toolResult(
              toolCallId: 'call_2',
              toolResult: _toolResult,
            ),
          ],
        );
        final messages = h.lastBody['messages']! as List;
        expect(messages, hasLength(3));
        expect(messages[1], {
          'role': 'assistant',
          'content': [
            {
              'type': 'tool_use',
              'id': 'call_1',
              'name': AIToolNames.getCategorySpend,
              'input': _toolCallRequest.arguments,
            },
            {
              'type': 'tool_use',
              'id': 'call_2',
              'name': AIToolNames.getOwedOverview,
              'input': <String, Object?>{},
            },
          ],
        });
        final results = (messages[2] as Map)['content'] as List;
        expect((messages[2] as Map)['role'], 'user');
        expect(results, hasLength(2));
        expect((results.first as Map)['type'], 'tool_result');
        expect((results.first as Map)['tool_use_id'], 'call_1');
        expect(jsonDecode((results.first as Map)['content'] as String), {
          'toolName': AIToolNames.getCategorySpend,
          'foundData': true,
          'data': {'category': 'Food', 'amountMinorUnits': 350000},
        });
      },
    );

    test(
      'drops a leading assistant message and merges consecutive users',
      () async {
        final h = _Harness(
          (_) async => http.Response(_answerBody('anthropic', 'ok'), 200),
        );
        await h.send(
          'anthropic',
          context: const [
            AITurnMessage.assistant('orphan answer'),
            AITurnMessage.user('failed earlier question'),
          ],
        );
        final messages = h.lastBody['messages']! as List;
        expect(messages, hasLength(1));
        expect((messages.single as Map)['role'], 'user');
        expect(((messages.single as Map)['content'] as List), hasLength(2));
      },
    );

    test('parses a final answer', () async {
      final h = _Harness(
        (_) async => http.Response(_answerBody('anthropic', 'Done.'), 200),
      );
      expect(
        (await h.send('anthropic')).getOrElse((f) => fail('$f')),
        const AITurnResult.answer('Done.'),
      );
    });

    test('parses a tool call (text preamble ignored)', () async {
      final h = _Harness(
        (_) async => http.Response(_toolCallBody('anthropic'), 200),
      );
      expect(
        (await h.send('anthropic')).getOrElse((f) => fail('$f')),
        const AITurnResult.toolCalls([
          AIToolCallRequest(
            id: 'toolu_1',
            toolName: AIToolNames.getCategorySpend,
            arguments: {
              'period': {'preset': 'thisMonth'},
            },
          ),
        ]),
      );
    });
  });

  group('failure mapping (T064)', () {
    for (final id in _allIds) {
      group(id, () {
        for (final status in [401, 403]) {
          test('$status -> InvalidApiKeyFailure', () async {
            _expectFailure<InvalidApiKeyFailure>(
              await _respond(
                status,
                '{"error":{"message":"bad $_key"}}',
              ).send(id),
            );
          });
        }

        test('429 -> RateLimitFailure', () async {
          _expectFailure<RateLimitFailure>(
            await _respond(429, '{"error":{"message":"slow down"}}').send(id),
          );
        });

        for (final status in [500, 502, 503, 529]) {
          test('$status -> AIProviderFailure', () async {
            _expectFailure<AIProviderFailure>(
              await _respond(status, '<html>oops</html>').send(id),
            );
          });
        }

        test('other 4xx (400/404) -> AIProviderFailure', () async {
          _expectFailure<AIProviderFailure>(
            await _respond(
              400,
              '{"type":"error","error":{"type":"invalid_request_error","message":"bad"}}',
            ).send(id),
          );
          _expectFailure<AIProviderFailure>(
            await _respond(404, 'not found').send(id),
          );
        });

        test('provider-error envelope on 200 -> AIProviderFailure', () async {
          _expectFailure<AIProviderFailure>(
            await _respond(
              200,
              '{"type":"error","error":{"type":"overloaded_error","message":"busy"}}',
            ).send(id),
          );
        });

        test('invalid-key envelope on 400 -> InvalidApiKeyFailure', () async {
          _expectFailure<InvalidApiKeyFailure>(
            await _respond(
              400,
              '{"type":"error","error":{"type":"authentication_error","code":"invalid_api_key","message":"Invalid API key: $_key"}}',
            ).send(id),
          );
        });

        test('rate-limit envelope on 400 -> RateLimitFailure', () async {
          _expectFailure<RateLimitFailure>(
            await _respond(
              400,
              '{"type":"error","error":{"type":"rate_limit_error","message":"x"}}',
            ).send(id),
          );
        });

        final transportErrors = <String, Object>{
          'SocketException': const SocketException('no route'),
          'ClientException': http.ClientException('failed', Uri.parse('x:')),
          'HandshakeException': const HandshakeException('tls'),
          'unexpected error': StateError('boom'),
        };
        transportErrors.forEach((name, error) {
          test('$name -> AINetworkFailure', () async {
            final h = _Harness((_) async => throw error);
            _expectFailure<AINetworkFailure>(await h.send(id));
          });
        });

        test('timeout -> AINetworkFailure', () async {
          final h = _Harness(
            (_) => Future.delayed(
              const Duration(milliseconds: 300),
              () => http.Response(_answerBody(id, 'late'), 200),
            ),
            timeout: const Duration(milliseconds: 20),
          );
          _expectFailure<AINetworkFailure>(await h.send(id));
        });

        final unrecognized = <String, String>{
          'malformed JSON': '{"choices": [',
          'empty body': '',
          'JSON array': '[1, 2]',
          'empty object': '{}',
          'wrong types': '{"choices": "nope", "content": "nope"}',
          'no answer and no tool call': _isAnthropic(id)
              ? '{"content": []}'
              : '{"choices": [{"message": {"content": "   "}}]}',
        };
        unrecognized.forEach((name, body) {
          test('$name -> UnrecognizedAIResponseFailure', () async {
            _expectFailure<UnrecognizedAIResponseFailure>(
              await _respond(200, body).send(id),
            );
          });
        });

        test(
          'tool outside availableTools -> UnrecognizedAIResponseFailure',
          () async {
            final h = _Harness(
              (_) async => http.Response(
                _toolCallBody(id, toolName: 'deleteTransaction'),
                200,
              ),
            );
            _expectFailure<UnrecognizedAIResponseFailure>(await h.send(id));
          },
        );

        test(
          'declared-in-catalog but not offered tool -> Unrecognized',
          () async {
            final h = _Harness(
              (_) async => http.Response(_toolCallBody(id), 200),
            );
            _expectFailure<UnrecognizedAIResponseFailure>(
              await h.send(
                id,
                tools: aiToolCatalog
                    .where((t) => t.name != AIToolNames.getCategorySpend)
                    .toList(),
              ),
            );
          },
        );

        test(
          'empty API key -> InvalidApiKeyFailure, no request sent',
          () async {
            final h = _respond(200, _answerBody(id, 'x'));
            _expectFailure<InvalidApiKeyFailure>(
              await h.send(id, apiKey: '  '),
            );
            expect(h.requests, isEmpty);
          },
        );
      });
    }

    test('OpenAI tool arguments that are not JSON -> Unrecognized', () async {
      for (final args in ['{not json', '[1,2]']) {
        final h = _Harness(
          (_) async => http.Response(
            _toolCallBody('openai', openAiArguments: args),
            200,
          ),
        );
        _expectFailure<UnrecognizedAIResponseFailure>(await h.send('openai'));
      }
    });

    test('OpenAI tool call without id -> Unrecognized', () async {
      final h = _respond(
        200,
        jsonEncode({
          'choices': [
            {
              'message': {
                'tool_calls': [
                  {
                    'function': {
                      'name': AIToolNames.getOwedOverview,
                      'arguments': '{}',
                    },
                  },
                ],
              },
            },
          ],
        }),
      );
      _expectFailure<UnrecognizedAIResponseFailure>(await h.send('openai'));
    });

    test(
      'Gemini list-shaped invalid-key envelope -> InvalidApiKeyFailure',
      () async {
        final h = _respond(
          400,
          jsonEncode([
            {
              'error': {
                'code': 400,
                'message': 'API key not valid. Please pass a valid API key.',
                'status': 'INVALID_ARGUMENT',
              },
            },
          ]),
        );
        _expectFailure<InvalidApiKeyFailure>(await h.send('gemini'));
      },
    );

    test('Anthropic tool_use with non-object input -> Unrecognized', () async {
      final h = _respond(
        200,
        jsonEncode({
          'content': [
            {
              'type': 'tool_use',
              'id': 't',
              'name': AIToolNames.getOwedOverview,
              'input': 'oops',
            },
          ],
        }),
      );
      _expectFailure<UnrecognizedAIResponseFailure>(await h.send('anthropic'));
    });

    test(
      'unknown/invalid providerId -> InvalidApiKeyFailure, no request',
      () async {
        for (final id in ['mystery', 'custom:http://evil.example|m', '']) {
          final h = _respond(200, _answerBody('openai', 'x'));
          _expectFailure<InvalidApiKeyFailure>(await h.send(id));
          expect(h.requests, isEmpty);
        }
      },
    );

    test('a non-JSON-encodable tool result never throws', () async {
      final h = _respond(200, _answerBody('openai', 'x'));
      final result = await h.send(
        'openai',
        toolExchange: [
          const AITurnMessage.toolCallRequest([_toolCallRequest]),
          AITurnMessage.toolResult(
            toolCallId: 'call_1',
            toolResult: ToolResult(
              toolName: AIToolNames.getCategorySpend,
              sourceUseCase: 'X',
              data: {'when': DateTime(2026)},
              foundData: true,
            ),
          ),
        ],
      );
      _expectFailure<UnrecognizedAIResponseFailure>(result);
      expect(h.requests, isEmpty);
    });

    test(
      'the key is never in any failure, even when the provider echoes it',
      () async {
        final bodies = [
          '{"error":{"message":"Incorrect API key provided: $_key"}}',
          '{"type":"error","error":{"type":"api_error","message":"$_key"}}',
          _key,
        ];
        for (final id in _allIds) {
          for (final status in [200, 400, 401, 403, 404, 429, 500]) {
            for (final body in bodies) {
              final result = await _respond(status, body).send(id);
              final failure = result.fold((f) => f, (r) => fail('$r'));
              expect(failure, isA<AIAssistantFailure>());
              expect(failure.message, isNot(contains(_key)));
              expect(failure.message, isNot(contains('Incorrect API key')));
              expect(failure.toString(), isNot(contains(_key)));
            }
          }
        }
      },
    );
  });
}
