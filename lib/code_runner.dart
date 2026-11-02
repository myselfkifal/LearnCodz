import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'language_courses.dart';
import 'quest_widgets.dart';
import 'reference_design.dart';
import 'sound_effects.dart';

String codeMask(String code) => code.replaceAllMapped(
    RegExp(r'''//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*' '''
        .trim()),
    (m) => m.group(0)!.replaceAll(RegExp(r'[^\n]'), ' '));

String prepareProgram(StudyLanguage language, String code) {
  if (language == StudyLanguage.python) return code;
  final mask = codeMask(code);
  if (language == StudyLanguage.java) {
    const imports =
        'import java.util.*;\nimport java.io.*;\nimport java.nio.file.*;\n';
    if (RegExp(r'\bstatic\s+void\s+main\s*\(').hasMatch(mask)) {
      final main = mask.indexOf(RegExp(r'\bstatic\s+void\s+main\s*\('));
      final declarations = RegExp(r'\bclass\s+(\w+)')
          .allMatches(mask.substring(0, main))
          .toList();
      if (declarations.isEmpty) return '$imports$code';
      final name = declarations.last.group(1)!;
      var transformed = code;
      final positions = RegExp('\\b${RegExp.escape(name)}\\b')
          .allMatches(mask)
          .toList()
          .reversed;
      for (final m in positions) {
        transformed = transformed.replaceRange(m.start, m.end, 'Wandbox');
      }
      final publicClass = RegExp(r'public\s+(?=(?:final\s+)?class\s+Wandbox\b)')
          .firstMatch(codeMask(transformed));
      if (publicClass != null) {
        transformed =
            transformed.replaceRange(publicClass.start, publicClass.end, '');
      }
      return '$imports$transformed';
    }
    return '${imports}class Wandbox {\n  public static void main(String[] args) throws Exception {\n$code\n  }\n}\n';
  }
  final headers = language == StudyLanguage.cpp
      ? '#include <iostream>\n#include <iomanip>\n#include <string>\n#include <vector>\n#include <algorithm>\n#include <numeric>\n#include <cmath>\n#include <map>\n#include <set>\n#include <fstream>\nusing namespace std;\n'
      : '#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <math.h>\n#include <stdbool.h>\n';
  if (RegExp(r'\bmain\s*\(').hasMatch(mask)) return '$headers$code';
  return '${headers}int main() {\n#line 1 "your_code"\n$code\nreturn 0;\n}\n';
}

class RunResult {
  final String output, errors, warnings, compiler;
  final bool success;
  const RunResult(
      {required this.output,
      required this.errors,
      required this.warnings,
      required this.compiler,
      required this.success});
}

class CompilerService {
  static List<dynamic>? _catalog;
  final http.Client client;
  CompilerService(this.client);
  Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (!kIsWeb) 'User-Agent': 'Mozilla/5.0 LearnCodz/1.0'
      };
  Future<RunResult> run(
      StudyLanguage language, String source, String stdin) async {
    if (source.trim().isEmpty) {
      throw const FormatException('Write a little code first.');
    }
    if (source.length > 20000 || stdin.length > 10000) {
      throw const FormatException(
          'Keep code under 20,000 characters and input under 10,000.');
    }
    if (_catalog == null) {
      final response = await client
          .get(Uri.parse('https://wandbox.org/api/list.json'), headers: headers)
          .timeout(const Duration(seconds: 20));
      _check(response);
      final value = jsonDecode(response.body);
      if (value is! List) {
        throw const FormatException(
            'Compiler list is temporarily unavailable.');
      }
      _catalog = value;
    }
    final names = {
      StudyLanguage.cpp: 'C++',
      StudyLanguage.c: 'C',
      StudyLanguage.python: 'Python',
      StudyLanguage.java: 'Java'
    };
    final preferred = {
      StudyLanguage.cpp: 'gcc-13.2.0',
      StudyLanguage.c: 'gcc-13.2.0-c',
      StudyLanguage.python: 'cpython-3.12.7',
      StudyLanguage.java: 'openjdk-jdk-21+35'
    };
    final available = _catalog!
        .whereType<Map>()
        .where((c) =>
            c['language'] == names[language] &&
            !(c['name'] as String).contains('head'))
        .toList();
    if (available.isEmpty) {
      throw const FormatException(
          'This language is temporarily unavailable. Try again later.');
    }
    final compiler = available.firstWhere(
        (c) => c['name'] == preferred[language],
        orElse: () => available.first)['name'] as String;
    final response = await client
        .post(Uri.parse('https://wandbox.org/api/compile.json'),
            headers: headers,
            body: jsonEncode({
              'compiler': compiler,
              'code': prepareProgram(language, source),
              'stdin': stdin,
              'save': false,
              if (language == StudyLanguage.c) 'compiler-option-raw': '-lm'
            }))
        .timeout(const Duration(seconds: 60));
    _check(response);
    if (response.bodyBytes.length > 2000000) {
      throw const FormatException(
          'Program output is too large. Print fewer values and try again.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    String text(String key) {
      final value = (data[key] ?? '').toString();
      return value.length > 20000
          ? '${value.substring(0, 20000)}\n[Output shortened]'
          : value;
    }

    return RunResult(
        output: text('program_output'),
        errors: [
          text('compiler_error'),
          text('program_error'),
          if ((data['signal'] ?? '').toString().isNotEmpty)
            'Program stopped: ${data['signal']}'
        ].where((s) => s.isNotEmpty).join('\n'),
        warnings: text('compiler_output'),
        compiler: compiler,
        success: data['status'].toString() == '0' &&
            (data['signal'] ?? '').toString().isEmpty);
  }

  void _check(http.Response response) {
    if (response.statusCode == 429) {
      throw const FormatException(
          'The compiler is busy. Wait a moment, then try again.');
    }
    if (response.statusCode == 403) {
      throw const FormatException(
          'The compiler service refused this connection. Try another network or try again later.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const FormatException(
          'The online compiler is temporarily unavailable. Please retry.');
    }
  }

  @visibleForTesting
  static void clearCatalog() => _catalog = null;
}

class CodeRunnerPage extends StatefulWidget {
  final SharedPreferences prefs;
  final http.Client Function()? clientFactory;
  const CodeRunnerPage({super.key, required this.prefs, this.clientFactory});
  @override
  State<CodeRunnerPage> createState() => _CodeRunnerPageState();
}

class _CodeRunnerPageState extends State<CodeRunnerPage> {
  late StudyLanguage language;
  final code = TextEditingController(), input = TextEditingController();
  Timer? draftTimer;
  http.Client? runningClient;
  bool running = false;
  int generation = 0;
  DateTime? lastRun;
  String? error, status;
  RunResult? result;
  @override
  void initState() {
    super.initState();
    language = activeLanguage ?? StudyLanguage.cpp;
    loadDraft();
    code.addListener(changed);
    input.addListener(changed);
  }

  String starter(StudyLanguage l) => switch (l) {
        StudyLanguage.cpp => 'cout << "Hello, LearnCodz!" << endl;',
        StudyLanguage.c => 'printf("Hello, LearnCodz!\\n");',
        StudyLanguage.python => 'print("Hello, LearnCodz!")',
        StudyLanguage.java => 'System.out.println("Hello, LearnCodz!");'
      };
  void loadDraft() {
    code.text = widget.prefs.getString('codeDraft.${language.name}') ??
        starter(language);
    input.text = widget.prefs.getString('codeInput.${language.name}') ?? '';
  }

  void changed() {
    draftTimer?.cancel();
    draftTimer = Timer(const Duration(milliseconds: 600), saveDraft);
  }

  Future<void> saveDraft() async {
    final l = language.name, source = code.text, stdin = input.text;
    try {
      await Future.wait([
        widget.prefs.setString('codeDraft.$l', source),
        widget.prefs.setString('codeInput.$l', stdin)
      ]);
    } catch (_) {}
  }

  @override
  void dispose() {
    draftTimer?.cancel();
    runningClient?.close();
    saveDraft();
    code.dispose();
    input.dispose();
    super.dispose();
  }

  Future<void> run() async {
    if (running) return;
    if (lastRun != null && DateTime.now().difference(lastRun!).inSeconds < 3) {
      setState(
          () => error = 'Give the compiler a moment before running again.');
      return;
    }
    final id = ++generation;
    lastRun = DateTime.now();
    final client = widget.clientFactory?.call() ?? http.Client();
    runningClient = client;
    setState(() {
      running = true;
      error = null;
      result = null;
      status = 'Compiling and running…';
    });
    try {
      await saveDraft();
      final value =
          await CompilerService(client).run(language, code.text, input.text);
      if (mounted && id == generation) {
        SoundEffects.instance
            .play(value.success ? SoundCue.correct : SoundCue.incorrect);
        setState(() {
          result = value;
          status = value.success ? 'Program finished' : 'Program needs a fix';
        });
      }
    } on TimeoutException {
      if (mounted && id == generation) {
        setState(() => error =
            'The run timed out. Check for endless loops, then try again.');
      }
    } on FormatException catch (e) {
      if (mounted && id == generation) setState(() => error = e.message);
    } catch (_) {
      if (mounted && id == generation) {
        setState(() => error =
            'Could not reach the compiler. Check your internet connection and retry.');
      }
    } finally {
      client.close();
      if (mounted && id == generation) setState(() => running = false);
    }
  }

  void cancel() {
    generation++;
    runningClient?.close();
    setState(() {
      running = false;
      status = 'Stopped waiting for this run';
    });
  }

  Widget output(String title, String value, {bool problem = false}) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: problem ? Colors.red : null)),
        const SizedBox(height: 8),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color:
                    problem ? const Color(0xFFFFF0ED) : const Color(0xFFF4F6F1),
                borderRadius: BorderRadius.circular(16)),
            child: SelectableText(value,
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 13, height: 1.5)))
      ]));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Code Playground')),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: ListView(padding: const EdgeInsets.all(22), children: [
                const Text('Write a little. Run it. See what happens.',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                DropdownButtonFormField<StudyLanguage>(
                    value: language,
                    decoration: const InputDecoration(
                        labelText: 'Programming language',
                        border: OutlineInputBorder()),
                    items: StudyLanguage.values
                        .map((l) => DropdownMenuItem(
                            value: l, child: Text(languageName(l))))
                        .toList(),
                    onChanged: running
                        ? null
                        : (l) {
                            if (l == null) return;
                            unawaited(saveDraft());
                            draftTimer?.cancel();
                            setState(() {
                              language = l;
                              loadDraft();
                              result = null;
                              error = null;
                              status = null;
                            });
                          }),
                const SizedBox(height: 14),
                Text(
                    language == StudyLanguage.python
                        ? 'Write normal Python code. No special setup required.'
                        : 'Write statements only — we add standard imports and the entry point. A normal full program is also accepted.',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 12),
                TextField(
                    controller: code,
                    readOnly: running,
                    minLines: 9,
                    maxLines: 18,
                    maxLength: 20000,
                    keyboardType: TextInputType.multiline,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 14, height: 1.5),
                    decoration: InputDecoration(
                        labelText: 'Your code',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFF7F6FB),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)))),
                const SizedBox(height: 10),
                TextField(
                    controller: input,
                    readOnly: running,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 10000,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                        labelText: 'Program input (stdin)',
                        hintText:
                            'Enter all answers here before Run, one per line.',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                const Text(
                    'Runs online using Wandbox. Your code and input are sent for execution; this app does not request a public saved link.',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 16),
                if (running) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 10),
                  OutlinedButton(
                      onPressed: cancel, child: const Text('Cancel run'))
                ] else
                  QuestButton(label: 'Run code', onPressed: run),
                if (status != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(status!,
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                if (error != null)
                  output('Connection / run problem', error!, problem: true),
                if (result != null) ...[
                  output(
                      'Output',
                      result!.output.isEmpty
                          ? (result!.success
                              ? 'Program finished with no output. Add a print/output statement to display a value.'
                              : 'No program output. See the compiler messages below.')
                          : result!.output),
                  if (result!.errors.isNotEmpty)
                    output('Compiler / runtime messages', result!.errors,
                        problem: !result!.success),
                  if (result!.warnings.isNotEmpty)
                    output('Compiler notes', result!.warnings),
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('Runtime: ${result!.compiler}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54)))
                ],
                const SizedBox(height: 18),
                ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('See the complete program we generate'),
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                          valueListenable: code,
                          builder: (context, value, _) => CodePanel(
                              code: prepareProgram(language, value.text)))
                    ]),
              ]))));
}
