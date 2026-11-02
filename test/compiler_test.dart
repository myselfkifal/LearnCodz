import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quizquest/code_runner.dart';
import 'package:quizquest/language_courses.dart';

void main() {
  setUp(CompilerService.clearCatalog);
  test('Boilerplate is automatic and main inside text is ignored', () {
    final cpp = prepareProgram(StudyLanguage.cpp, 'cout << "main()";');
    expect(cpp, contains('#include <iostream>'));
    expect(cpp, contains('int main()'));
    expect(cpp, contains('cout << "main()";'));
    final c =
        prepareProgram(StudyLanguage.c, 'int main(){printf("ok");return 0;}');
    expect(RegExp(r'\bint main\(').allMatches(c).length, 1);
    expect(prepareProgram(StudyLanguage.python, 'print(42)'), 'print(42)');
  });
  test('Java statements and a full Main class are adapted for the runner', () {
    final snippet =
        prepareProgram(StudyLanguage.java, 'System.out.println(42);');
    expect(snippet, contains('class Wandbox'));
    expect(snippet, contains('throws Exception'));
    final full = prepareProgram(StudyLanguage.java,
        'public class Main { Main() {} public static void main(String[] args) { System.out.println("Main"); new Main(); } }');
    expect(full, contains('class Wandbox'));
    expect(full, contains('Wandbox()'));
    expect(full, contains('new Wandbox()'));
    expect(full, contains('"Main"'));
    expect(full, isNot(contains('public class Wandbox')));
  });
  test('Compiler sends generated code and stdin without saving a public link',
      () async {
    var submitted = false;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('list.json')) {
        return http.Response(
            jsonEncode([
              {'name': 'gcc-13.2.0', 'language': 'C++'}
            ]),
            200);
      }
      final body = jsonDecode(request.body) as Map;
      expect(body['stdin'], '21');
      expect(body['save'], false);
      expect(body['code'], contains('int main()'));
      submitted = true;
      return http.Response(
          jsonEncode({
            'status': '0',
            'program_output': '42\n',
            'compiler_error': '',
            'program_error': ''
          }),
          200);
    });
    final result = await CompilerService(client)
        .run(StudyLanguage.cpp, 'int x; cin >> x; cout << x*2;', '21');
    expect(submitted, isTrue);
    expect(result.success, isTrue);
    expect(result.output, '42\n');
  });
  test('Compilation errors are returned as errors rather than simulated output',
      () async {
    final client = MockClient((request) async => request.url.path
            .endsWith('list.json')
        ? http.Response('[{"name":"cpython-3.12.7","language":"Python"}]', 200)
        : http.Response(
            '{"status":"1","compiler_error":"Syntax error","program_output":""}',
            200));
    final result = await CompilerService(client)
        .run(StudyLanguage.python, 'broken code', '');
    expect(result.success, isFalse);
    expect(result.errors, 'Syntax error');
    expect(result.output, isEmpty);
  });
  test('Service rate limiting gives a useful retry message', () async {
    final client = MockClient((_) async => http.Response('busy', 429));
    await expectLater(
        CompilerService(client).run(StudyLanguage.c, 'printf("hi");', ''),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('busy'))));
  });
  test('Live compiler runs all four languages with auto setup and stdin',
      () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final snippets = {
        StudyLanguage.cpp: 'int n; cin >> n; cout << n * 2;',
        StudyLanguage.c: 'int n; scanf("%d", &n); printf("%d", n * 2);',
        StudyLanguage.python: 'n = int(input())\nprint(n * 2)',
        StudyLanguage.java:
            'Scanner scanner = new Scanner(System.in);\nSystem.out.println(scanner.nextInt() * 2);'
      };
      final client = http.Client();
      try {
        for (final entry in snippets.entries) {
          final result =
              await CompilerService(client).run(entry.key, entry.value, '21');
          expect(result.success, isTrue,
              reason: '${entry.key}: ${result.errors}');
          expect(result.output.trim(), '42', reason: entry.key.name);
        }
      } finally {
        client.close();
      }
    }, _RealHttp());
  },
      skip: !const bool.fromEnvironment('LIVE_COMPILER'),
      timeout: const Timeout(Duration(minutes: 5)));
}

class _RealHttp extends HttpOverrides {}
