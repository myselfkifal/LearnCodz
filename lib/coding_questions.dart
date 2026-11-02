import 'lessons.dart';
import 'language_courses.dart';

const dartCodingQuestions = [
  Question('What does this program print?', ['8', '6', '3', '5'], 0,
      'The loop adds 0, 1 and 2 to 5, giving 8.',
      kind: QuestionKind.output,
      code:
          'var total = 5;\nfor (var i = 0; i < 3; i++) {\n  total += i;\n}\nprint(total);'),
  Question('Choose the missing keyword.', ['return', 'print', 'while', 'else'],
      0, 'return sends the calculated result back to the caller.',
      kind: QuestionKind.blank, code: 'int square(int n) {\n  ___ n * n;\n}'),
  Question(
      'Arrange the lines to print the doubled value.',
      ['print(doubled);', 'final value = 4;', 'final doubled = value * 2;'],
      0,
      'Declare value first, calculate doubled next, then print it.',
      kind: QuestionKind.order,
      answerOrder: [1, 2, 0]),
  Question('Which line contains the bug?', ['Line 1', 'Line 2', 'Line 3'], 1,
      'A two-item list has indexes 0 and 1. Accessing index 2 is out of range.',
      kind: QuestionKind.bug,
      code:
          '1  final items = [10, 20];\n2  final last = items[2];\n3  print(last);'),
  Question('What is the output?', ['true', 'false', '10', 'An error'], 0,
      '10 is greater than 5 and less than 20, so both comparisons are true.',
      kind: QuestionKind.output,
      code: 'final n = 10;\nprint(n > 5 && n < 20);'),
  Question('Fill the blank to check equality.', ['=', '==', '!=', '>='], 1,
      '== compares values for equality. = is assignment.',
      kind: QuestionKind.blank,
      code: "if (score ___ 3) {\n  print('Perfect!');\n}"),
  Question(
      'Arrange the lines into a valid function.',
      ['  return a + b;', '}', 'int add(int a, int b) {'],
      0,
      'The function declaration opens the block, return is inside, and the closing brace comes last.',
      kind: QuestionKind.order,
      answerOrder: [2, 0, 1]),
  Question('Find the logic error.', ['Line 1', 'Line 2', 'Line 3'], 1,
      'An average needs division by the number of values. Multiplying the sum gives the wrong result.',
      kind: QuestionKind.bug,
      code:
          '1  final sum = 10 + 20;\n2  final average = sum * 2;\n3  print(average);'),
];

final languageLabs = {
  for (final l in StudyLanguage.values) l: buildLanguageLab(l)
};
List<Question> get codingQuestions => activeLanguage == null
    ? dartCodingQuestions
    : languageLabs[activeLanguage]!;
String? codingQuestionKey(Question q) {
  if (activeLanguage == null) return null;
  final index = codingQuestions.indexOf(q);
  return index < 0 ? null : '${activeLanguage!.name}:lab:$index';
}

List<Question> buildLanguageLab(StudyLanguage l) {
  final py = l == StudyLanguage.python,
      java = l == StudyLanguage.java,
      c = l == StudyLanguage.c;
  final printEight = py
      ? 'print(4 * 2)'
      : java
          ? 'System.out.println(4 * 2);'
          : c
              ? 'printf("%d", 4 * 2);'
              : 'std::cout << 4 * 2;';
  final lines = py
      ? ['print(doubled)', 'value = 4', 'doubled = value * 2']
      : [
          (java
              ? 'System.out.println(doubled);'
              : c
                  ? 'printf("%d", doubled);'
                  : 'std::cout << doubled;'),
          'int value = 4;',
          'int doubled = value * 2;'
        ];
  return [
    Question(
        'What does this ${languageName(l)} instruction display?',
        ['8', '6', '42', '2'],
        0,
        'Multiplication happens before output, so 4 * 2 gives 8.',
        kind: QuestionKind.output,
        code: printEight),
    Question(
        'Fill the gap to return a result.',
        ['return', 'print', 'else', 'while'],
        0,
        'return gives the result back to the caller.',
        kind: QuestionKind.blank,
        code: py
            ? 'def square(n):\n    ___ n * n'
            : '${java ? 'static ' : ''}int square(int n) {\n  ___ n * n;\n}'),
    Question('Arrange the lines to display twice the value.', lines, 0,
        'Declare value, compute doubled, then display it.',
        kind: QuestionKind.order, answerOrder: [1, 2, 0]),
    Question(
        'Which line accesses an invalid index?',
        ['Line 1', 'Line 2', 'Line 3'],
        1,
        'Three elements have valid indexes 0, 1, 2. ${c || l == StudyLanguage.cpp ? 'An out-of-bounds array access is undefined behavior.' : 'Index 3 raises an error or exception.'}',
        kind: QuestionKind.bug,
        code: py
            ? '1  items = [10, 20, 30]\n2  last = items[3]\n3  print(last)'
            : '${java ? '1  int[] items = {10, 20, 30};' : '1  int items[3] = {10, 20, 30};'}\n2  int last = items[3];\n3  // display last'),
    Question('If a number is 10 and increases by 3, what is its new value?',
        ['13', '10', '3', '103'], 0, 'Adding three to ten produces thirteen.',
        kind: QuestionKind.output,
        code: py
            ? 'n = 10\nn = n + 3\nprint(n)'
            : 'int n = 10;\nn = n + 3;\n// display n'),
    Question('Fill the gap to check equality.', ['=', '==', '!=', '>'], 1,
        '== checks equality. = assigns a value.',
        kind: QuestionKind.blank,
        code: py
            ? 'if score ___ 3:\n    print("Perfect")'
            : 'if (score ___ 3) {\n  // display Perfect\n}'),
    Question(
        'Put the function definition in order.',
        py
            ? ['    return a + b', 'def add(a, b):']
            : [
                '  return a + b;',
                '}',
                '${java ? 'static ' : ''}int add(int a, int b) {'
              ],
        0,
        'Declare the function before its body. ${py ? 'Indent the body.' : 'The closing brace ends its block.'}',
        kind: QuestionKind.order,
        answerOrder: py ? [1, 0] : [2, 0, 1]),
    Question(
        'Find the average-calculation bug.',
        ['Line 1', 'Line 2', 'Line 3'],
        1,
        'An average divides the sum by the number of items; it does not multiply the sum.',
        kind: QuestionKind.bug,
        code: py
            ? '1  total = 10 + 20\n2  average = total * 2\n3  print(average)'
            : '1  double total = 10 + 20;\n2  double average = total * 2;\n3  // display average'),
  ];
}
