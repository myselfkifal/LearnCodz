import 'lottie_effects.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'language_courses.dart';
import 'quest_widgets.dart';
import 'reference_design.dart';
import 'sound_effects.dart';
import 'coding_missions.dart';
import 'polished_panels.dart';
import 'quest_motion.dart';

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
  final StudyLanguage? initialLanguage;
  final String? initialCode, sourceId;
  final CodingMission? mission;
  const CodeRunnerPage(
      {super.key,
      required this.prefs,
      this.clientFactory,
      this.initialLanguage,
      this.initialCode,
      this.sourceId,
      this.mission});
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
  final List<(MissionCase, RunResult)> caseResults = [];
  String get draftSuffix =>
      '${language.name}${widget.mission != null ? '.mission.${widget.mission!.id}' : widget.sourceId != null ? '.${widget.sourceId}' : ''}';
  bool get allTestsPassed =>
      widget.mission != null &&
      caseResults.length == widget.mission!.cases.length &&
      caseResults.every((entry) =>
          entry.$2.success &&
          normalizedOutput(entry.$2.output) ==
              normalizedOutput(entry.$1.expected));
  @override
  void initState() {
    super.initState();
    language = widget.initialLanguage ?? activeLanguage ?? StudyLanguage.cpp;
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
    code.text = widget.prefs.getString('codeDraft.$draftSuffix') ??
        widget.initialCode ??
        widget.mission?.starter(language) ??
        starter(language);
    input.text = widget.prefs.getString('codeInput.$draftSuffix') ?? '';
  }

  void changed() {
    if (mounted && !running && (result != null || caseResults.isNotEmpty)) {
      setState(() {
        result = null;
        status = null;
        error = null;
        caseResults.clear();
      });
    }
    draftTimer?.cancel();
    draftTimer = Timer(const Duration(milliseconds: 600), saveDraft);
  }

  Future<void> saveDraft() async {
    final l = draftSuffix, source = code.text, stdin = input.text;
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
    editorFocus.dispose();
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
      caseResults.clear();
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

  Future<void> checkMission() async {
    final mission = widget.mission;
    if (mission == null || running) return;
    final id = ++generation;
    final source = code.text;
    final client = widget.clientFactory?.call() ?? http.Client();
    runningClient = client;
    setState(() {
      running = true;
      error = null;
      result = null;
      caseResults.clear();
      status = 'Checking your solution…';
    });
    try {
      await saveDraft();
      for (final test in mission.cases) {
        if (!mounted || id != generation) return;
        final value =
            await CompilerService(client).run(language, source, test.input);
        if (!mounted || id != generation) return;
        setState(() {
          caseResults.add((test, value));
          if (!value.success) result = value;
        });
        if (!value.success) break;
      }
      if (allTestsPassed) {
        final completed =
            (widget.prefs.getStringList('missionCompletions') ?? []).toSet()
              ..add('${language.name}:${mission.id}');
        final saved = await widget.prefs
            .setStringList('missionCompletions', completed.toList());
        if (mounted && id == generation) {
          setState(() => status = saved
              ? 'Mission complete — all tests passed!'
              : 'All tests passed. Completion could not be saved. Please retry.');
          SoundEffects.instance.play(SoundCue.achievement);
        }
      } else {
        setState(() =>
            status = 'A useful clue. Check the cases below and try again.');
      }
    } on TimeoutException {
      if (mounted && id == generation) {
        setState(() => error =
            'The test timed out. Check for an endless loop and try again.');
      }
    } on FormatException catch (e) {
      if (mounted && id == generation) {
        setState(() => error = e.message);
      }
    } catch (_) {
      if (mounted && id == generation) {
        setState(() => error =
            'Could not finish the tests. Check your connection and retry.');
      }
    } finally {
      client.close();
      if (mounted && id == generation) setState(() => running = false);
    }
  }

  Widget missionBrief() =>
      ToolkitPanel(title: widget.mission!.title, children: [
        Text(widget.mission!.description,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...widget.mission!.steps.indexed.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFEAF4DD),
                  child: Text('${entry.$1 + 1}',
                      style: const TextStyle(fontSize: 12, color: questGreen))),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(entry.$2,
                      style: const TextStyle(fontSize: 13, height: 1.5)))
            ]))),
        ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.lightbulb_outline, color: Color(0xFFE0A126)),
            title: const Text('Need a hint?'),
            children: widget.mission!.hints
                .map((hint) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(hint, style: const TextStyle(fontSize: 13))))
                .toList()),
        const Text(
            'Check cases with the button below the editor. Print only the requested output; avoid input prompts.',
            style: TextStyle(fontSize: 12, color: Colors.black54))
      ]);
  Widget friendlyError() {
    final hint = CompilerHint.from(result!.errors, language, code.text,
        generatedSource: prepareProgram(language, code.text));
    return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ToolkitPanel(title: hint.title, children: [
          Text(hint.detail),
          if (hint.line != null)
            TextButton.icon(
                onPressed: () {
                  final lines = code.text.split('\n');
                  final start = lines
                      .take(hint.line! - 1)
                      .fold<int>(0, (sum, line) => sum + line.length + 1);
                  code.selection = TextSelection(
                      baseOffset: start,
                      extentOffset: start + lines[hint.line! - 1].length);
                  FocusScope.of(context).requestFocus(editorFocus);
                },
                icon: const Icon(Icons.my_location),
                label: Text('Highlight line ${hint.line}'))
        ]));
  }

  final editorFocus = FocusNode();

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
      appBar: AppBar(
          title: Text(
              widget.mission == null ? 'Code Playground' : 'Mission Studio'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: ListView(padding: const EdgeInsets.all(22), children: [
                if (widget.mission == null)
                  Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFEAF6FF), Color(0xFFF0F8E8)]),
                          borderRadius: BorderRadius.circular(24)),
                      child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('YOUR CODING SANDBOX',
                                      style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1.4,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF397CA3))),
                                  SizedBox(height: 10),
                                  Text('Small ideas.\nReal code.',
                                      style: TextStyle(
                                          fontSize: 28,
                                          height: 1.15,
                                          fontWeight: FontWeight.w900)),
                                  SizedBox(height: 10),
                                  Text(
                                      'Experiment, run, repeat.\nYour draft stays right here.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                          height: 1.5))
                                ])),
                            SizedBox(width: 12),
                            CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.terminal_rounded,
                                    size: 32, color: Color(0xFF2196DC)))
                          ])),
                const SizedBox(height: 22),
                if (widget.mission != null) missionBrief(),
                DropdownButtonFormField<StudyLanguage>(
                    value: language,
                    decoration: const InputDecoration(
                        labelText: 'Programming language',
                        prefixIcon: Icon(Icons.code_rounded, color: questGreen),
                        filled: true,
                        fillColor: Color(0xFFF7F8FA),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none)),
                    items: StudyLanguage.values
                        .map((l) => DropdownMenuItem(
                            value: l, child: Text(languageName(l))))
                        .toList(),
                    onChanged: running ||
                            widget.mission != null ||
                            widget.sourceId != null
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
                        : 'Setup included. Write statements or a full program.',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 12),
                Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFF192433),
                        borderRadius: BorderRadius.circular(20)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      Container(
                          padding: const EdgeInsets.fromLTRB(16, 7, 8, 7),
                          color: const Color(0xFF243246),
                          child: Row(children: [
                            for (final color in [
                              const Color(0xFFFF8B83),
                              const Color(0xFFFFD77B),
                              const Color(0xFF8BDC9F)
                            ])
                              Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: CircleAvatar(
                                      radius: 4, backgroundColor: color)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    'main.${switch (language) {
                                      StudyLanguage.cpp => 'cpp',
                                      StudyLanguage.python => 'py',
                                      StudyLanguage.java => 'java',
                                      StudyLanguage.c => 'c'
                                    }}',
                                    style: const TextStyle(
                                        color: Color(0xFFCCD7E6),
                                        fontFamily: 'monospace',
                                        fontSize: 12))),
                            IconButton(
                                tooltip: 'Copy code',
                                onPressed: () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: code.text));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Code copied')));
                                  }
                                },
                                icon: const Icon(Icons.copy_rounded,
                                    color: Color(0xFFB9CBDD), size: 18))
                          ])),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          child: TextField(
                              key: const ValueKey('code-editor'),
                              controller: code,
                              focusNode: editorFocus,
                              readOnly: running,
                              minLines: 8,
                              maxLines: 18,
                              maxLength: 20000,
                              keyboardType: TextInputType.multiline,
                              autocorrect: false,
                              enableSuggestions: false,
                              cursorColor: const Color(0xFFB6F18A),
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  height: 1.7,
                                  color: Color(0xFFD7EDCB)),
                              decoration: const InputDecoration(
                                  filled: false,
                                  labelText: 'Your code',
                                  labelStyle:
                                      TextStyle(color: Color(0xFFB9CBDD)),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  counterStyle: TextStyle(
                                      color: Color(0xFF9BAFC5), fontSize: 10))))
                    ])),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                const Row(children: [
                  Icon(Icons.keyboard_alt_outlined,
                      size: 20, color: Color(0xFF6C7E92)),
                  SizedBox(width: 8),
                  Text('Test with your own input',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16))
                ]),
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
                        filled: true,
                        fillColor: Color(0xFFF7F8FA),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                const Text(
                    'Runs online with Wandbox. Your code and input are sent to run.',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 16),
                if (running) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 10),
                  OutlinedButton(
                      onPressed: cancel, child: const Text('Cancel run'))
                ] else
                  QuestButton(
                      label: 'Run code', onPressed: run, color: questGreen),
                if (widget.mission != null && !running) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                      onPressed: checkMission,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Check all test cases'))
                ],
                if (allTestsPassed)
                  const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: QuestEntrance(
                          child: Column(children: [
                        QuestLottie(
                            animation: QuestAnimation.celebrate, size: 92),
                        FeatureBanner(
                            eyebrow: 'YOU BUILT IT',
                            title: 'All green. Nice work!',
                            subtitle: 'Your solution passed every test case.',
                            icon: Icons.verified_rounded)
                      ]))),
                for (final entry in caseResults.indexed)
                  Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: ToolkitPanel(
                          title:
                              'Case ${entry.$1 + 1} · ${entry.$2.$2.success && normalizedOutput(entry.$2.$2.output) == normalizedOutput(entry.$2.$1.expected) ? 'Passed' : 'Needs a fix'}',
                          children: [
                            Text('Input: ${entry.$2.$1.input}'),
                            Text('Expected: ${entry.$2.$1.expected}'),
                            const SizedBox(height: 8),
                            SelectableText(
                                'Your output: ${entry.$2.$2.output.isEmpty ? '(none)' : entry.$2.$2.output}',
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 13))
                          ])),
                if (status != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(status!,
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                if (error != null)
                  output('Connection / run problem', error!, problem: true),
                if (result != null) ...[
                  if (!result!.success && result!.errors.isNotEmpty)
                    friendlyError(),
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
                    leading: const Icon(Icons.integration_instructions_outlined,
                        color: questGreen),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    collapsedBackgroundColor: const Color(0xFFF6F8F3),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                    title: const Text('Advanced: full program'),
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                          valueListenable: code,
                          builder: (context, value, _) => CodePanel(
                              code: prepareProgram(language, value.text)))
                    ]),
              ]))));
}
