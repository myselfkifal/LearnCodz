import 'language_courses.dart';

class MissionCase {
  final String input, expected;
  const MissionCase(this.input, this.expected);
}

class CodingMission {
  final String id, title, description;
  final List<String> steps, hints;
  final List<MissionCase> cases;
  const CodingMission(this.id, this.title, this.description, this.steps,
      this.hints, this.cases);
  String starter(StudyLanguage language) {
    final read = switch (language) {
      StudyLanguage.python => 'n = int(input())',
      StudyLanguage.cpp => 'int n;\ncin >> n;',
      StudyLanguage.c => 'int n;\nscanf("%d", &n);',
      StudyLanguage.java =>
        'Scanner reader = new Scanner(System.in);\nint n = reader.nextInt();'
    };
    final output = switch (language) {
      StudyLanguage.python => 'print(n)',
      StudyLanguage.cpp => 'cout << n;',
      StudyLanguage.c => 'printf("%d", n);',
      StudyLanguage.java => 'System.out.println(n);'
    };
    return '$read\n${language == StudyLanguage.python ? '#' : '//'} TODO: $description\n$output';
  }
}

const codingMissions = [
  CodingMission('double', 'Double trouble',
      'Read an integer and print twice its value.', [
    'Read one integer from input.',
    'Multiply it by 2.',
    'Print only the result, then check all three cases.'
  ], [
    'Keep the input in a variable named n.',
    'Use n * 2 in your output statement. Zero and negative numbers should work too.'
  ], [
    MissionCase('4', '8'),
    MissionCase('0', '0'),
    MissionCase('-3', '-6')
  ]),
  CodingMission('grade', 'Pass or try again',
      'Print Pass for a score of 50 or more; otherwise print Retry.', [
    'Read one score.',
    'Compare the score with 50, including equality.',
    'Print exactly Pass or Retry.'
  ], [
    'Use an if / else condition.',
    'The boundary matters: 50 is a pass. Use >=, not >.'
  ], [
    MissionCase('75', 'Pass'),
    MissionCase('50', 'Pass'),
    MissionCase('49', 'Retry')
  ]),
  CodingMission(
      'even', 'Number detective', 'Read an integer and print Even or Odd.', [
    'Read one integer.',
    'Find the remainder after dividing by 2.',
    'Print Even when the remainder is zero; otherwise print Odd.'
  ], [
    'The remainder operator is %.',
    'Use n % 2 == 0. Zero is even; negative even numbers also have remainder zero.'
  ], [
    MissionCase('8', 'Even'),
    MissionCase('7', 'Odd'),
    MissionCase('-2', 'Even')
  ]),
  CodingMission(
      'square',
      'Square it',
      'Print the square of the input integer.',
      ['Read n.', 'Multiply n by itself.', 'Print the result.'],
      ['Use n * n, not n * 2.'],
      [MissionCase('3', '9'), MissionCase('-4', '16'), MissionCase('0', '0')]),
  CodingMission('absolute', 'Distance from zero',
      'Print the absolute value of the input integer.', [
    'Read n.',
    'If n is negative, change its sign.',
    'Print the resulting nonnegative value.'
  ], [
    'Zero stays zero. Try an if statement.'
  ], [
    MissionCase('-7', '7'),
    MissionCase('6', '6'),
    MissionCase('0', '0')
  ]),
  CodingMission('sum', 'Add the staircase',
      'Given a nonnegative integer n, print the sum from 1 through n.', [
    'Start a total at zero.',
    'Loop from 1 through n, adding each number.',
    'Print the total after the loop.'
  ], [
    'Include n in the loop. For n = 0, the total stays zero.'
  ], [
    MissionCase('5', '15'),
    MissionCase('1', '1'),
    MissionCase('0', '0')
  ]),
  CodingMission('factorial', 'Multiply the staircase',
      'Given n from 0 through 10, print its factorial.', [
    'Start a product at one.',
    'Multiply it by each integer from 1 through n.',
    'Print the product.'
  ], [
    'Start at 1, not 0. By definition, 0! is 1.'
  ], [
    MissionCase('5', '120'),
    MissionCase('0', '1'),
    MissionCase('3', '6')
  ]),
  CodingMission(
      'digits',
      'Digit detective',
      'Count the decimal digits in a nonnegative integer. Zero has one digit.',
      [
        'Handle zero as a special case.',
        'Repeatedly remove the last digit and count the steps.',
        'Print the count.'
      ],
      [
        'Use integer division by 10. In Python, use //.'
      ],
      [
        MissionCase('405', '3'),
        MissionCase('0', '1'),
        MissionCase('98765', '5')
      ]),
];

String normalizedOutput(String value) => value.replaceAll('\r\n', '\n').trim();

String runnableLessonCode(StudyLanguage language, String topic, String source) {
  if (language == StudyLanguage.python ||
      (topic != 'functions' && topic != 'recursion')) {
    return source;
  }
  final call = topic == 'functions' ? 'add(2, 3)' : 'sumTo(3)';
  if (language == StudyLanguage.java) {
    return 'class Main {\n$source\npublic static void main(String[] args) {\nSystem.out.println($call);\n}\n}';
  }
  return '$source\nint main() {\n${language == StudyLanguage.c ? 'printf("%d", $call);' : 'std::cout << $call;'}\nreturn 0;\n}';
}

class CompilerHint {
  final String title, detail;
  final int? line;
  const CompilerHint(this.title, this.detail, this.line);
  static CompilerHint from(String error, StudyLanguage language, String source,
      {String? generatedSource}) {
    final lower = error.toLowerCase();
    final (title, detail) = lower.contains('indentationerror') ||
            lower.contains('expected an indented block')
        ? (
            'Check your indentation',
            'Indent the lines inside an if, loop or function consistently. Python uses indentation to group code.'
          )
        : lower.contains('zerodivisionerror') ||
                lower.contains('division by zero')
            ? (
                'A value cannot be divided by zero',
                'Check the divisor before using / or %. Add a condition for zero input.'
              )
            : lower.contains('nameerror') ||
                    lower.contains('not declared') ||
                    lower.contains('cannot find symbol')
                ? (
                    'A name could not be found',
                    'Check spelling and letter case. Declare the variable before using it, in the same scope.'
                  )
                : lower.contains("expected ';'") ||
                        lower.contains("';' expected") ||
                        lower.contains('expected ‘;’')
                    ? (
                        'A semicolon may be missing',
                        'Check the end of this statement and the line just before it. C, C++ and Java statements usually end with ;.'
                      )
                    : lower.contains('syntaxerror') ||
                            lower.contains('expected')
                        ? (
                            'Check the structure of this line',
                            'Look for a missing quote, bracket, colon or operator. Start with the first compiler message.'
                          )
                        : (
                            'Let’s inspect the first error',
                            'Read the first message below, make one small change and run again. Later errors may disappear after the first fix.'
                          );
    int? line;
    if (language == StudyLanguage.python) {
      line =
          int.tryParse(RegExp(r'line (\d+)').firstMatch(error)?.group(1) ?? '');
    } else {
      line = int.tryParse(
          RegExp(r'your_code:(\d+)').firstMatch(error)?.group(1) ?? '');
    }
    if (line == null && generatedSource != null && source.isNotEmpty) {
      final rawLine = int.tryParse(
          RegExp(r'\.(?:java|cpp|c):(\d+)').firstMatch(error)?.group(1) ?? '');
      final offset = generatedSource.indexOf(source);
      if (rawLine != null && offset >= 0) {
        line = rawLine -
            '\n'.allMatches(generatedSource.substring(0, offset)).length;
      }
    }
    if (line != null && (line < 1 || line > source.split('\n').length)) {
      line = null;
    }
    return CompilerHint(title, detail, line);
  }
}
