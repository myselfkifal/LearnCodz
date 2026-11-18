import 'package:flutter/material.dart';
import 'language_courses.dart';

enum QuestionKind { choice, output, blank, order, bug }

class Question {
  final String prompt;
  final List<String> options;
  final int answer;
  final String explanation;
  final QuestionKind kind;
  final String? code, imageUrl, imageDescription;
  final List<int> answerOrder;
  const Question(this.prompt, this.options, this.answer, this.explanation,
      {this.kind = QuestionKind.choice,
      this.code,
      this.imageUrl,
      this.imageDescription,
      this.answerOrder = const []});
}

class Lesson {
  final String id, title, subtitle, code;
  final int minutes;
  final String? imageUrl, imageDescription;
  final IconData icon;
  final List<(String, String)> sections;
  final List<Question> questions;
  final List<Question> challengeQuestions;
  final List<Question> practiceQuestions;
  List<Question> get allQuestions =>
      [...questions, ...challengeQuestions, ...practiceQuestions];
  const Lesson(this.id, this.title, this.subtitle, this.minutes, this.icon,
      this.sections, this.code, this.questions,
      {this.challengeQuestions = const [],
      this.practiceQuestions = const [],
      this.imageUrl,
      this.imageDescription});
}

List<Lesson> get lessons =>
    activeLanguage == null ? dartLessons : languageCourses[activeLanguage]!;
const dartLessons = [
  Lesson(
      'variables',
      'Meet your variables',
      'Give your ideas a name and a place to live.',
      3,
      Icons.data_object,
      [
        (
          'A named container',
          'A variable is a name associated with a value. Think of a label on a box: the label helps you find what you stored. In Dart, var score = 10 creates a variable named score.'
        ),
        (
          'Values can change',
          'You can assign a new value to a variable later. score = 20 replaces 10 with 20. An int holds whole numbers, a double holds decimal numbers, and a String holds text.'
        ),
        (
          'When a value should stay put',
          'Use final when you will assign a variable only once. Use const for a value known at compile time. Clear names, like totalPrice, make programs easier to understand.'
        ),
      ],
      "var score = 10;\nscore = score + 5;\nfinal name = 'Alex';\nprint(score); // 15",
      [
        Question(
            'What is score after score = 10; score = score + 5;?',
            ['10', '5', '15', '50'],
            2,
            'The old value, 10, is added to 5. The new value is 15.'),
        Question(
            'Which Dart type stores text?',
            ['int', 'String', 'bool', 'double'],
            1,
            'String stores text, such as a name or a message.'),
        Question(
            'Which keyword means a variable can only be assigned once?',
            ['var', 'while', 'final', 'print'],
            2,
            'A final variable can be assigned once; its value need not be known at compile time.'),
      ]),
  Lesson(
      'conditions',
      'Make a decision',
      'Teach your program to choose its next step.',
      3,
      Icons.alt_route,
      [
        (
          'True or false',
          'A bool has one of two values: true or false. A comparison such as age >= 18 produces a bool. The == operator checks equality; = assigns a value.'
        ),
        (
          'Choose a branch',
          'An if statement runs a block only when its condition is true. An else block runs when that condition is false. This lets programs respond to different situations.'
        ),
        (
          'Combine conditions',
          'Use && when both conditions must be true. Use || when at least one must be true. Use ! to reverse a boolean value.'
        ),
      ],
      "final age = 20;\nif (age >= 18) {\n  print('Adult');\n} else {\n  print('Under 18');\n}",
      [
        Question(
            'Which operator checks whether two values are equal?',
            ['=', '==', '++', '+'],
            1,
            '== compares values. A single = assigns a value.'),
        Question(
            'When does an else block run?',
            [
              'Always',
              'When the if condition is false',
              'Only in a loop',
              'Before the if condition'
            ],
            1,
            'The else branch is the alternative when the if condition is false.'),
        Question(
            'What does true && false evaluate to?',
            ['true', 'false', 'null', '1'],
            1,
            '&& requires both sides to be true. One side is false, so the result is false.'),
      ]),
  Lesson(
      'loops',
      'Find your rhythm',
      'Let repetition do the heavy lifting.',
      4,
      Icons.loop,
      [
        (
          'Repeat with purpose',
          'A loop repeats a block of code. Instead of writing the same statement five times, a loop can run it five times for you.'
        ),
        (
          'The for loop',
          'A for loop has an initialization, a condition, and an update. In for (var i = 0; i < 3; i++), i starts at zero, the body runs while i is less than three, and i increases after each run.'
        ),
        (
          'Keep an exit',
          'A while loop repeats while its condition is true. Make sure the condition can eventually become false. Otherwise the program may repeat forever. break exits a loop immediately.'
        ),
      ],
      'for (var i = 0; i < 3; i++) {\n  print(i);\n}\n// Prints 0, 1, 2',
      [
        Question(
            'How often does for (var i = 0; i < 3; i++) run its body?',
            ['2 times', '3 times', '4 times', 'Forever'],
            1,
            'The body runs for i equal to 0, 1 and 2. At 3, the condition is false.'),
        Question(
            'What does i++ do?',
            ['Adds 1 to i', 'Doubles i', 'Resets i to 0', 'Ends the loop'],
            0,
            'i++ increases the variable by one.'),
        Question(
            'Which statement exits a loop immediately?',
            ['continue', 'repeat', 'break', 'next'],
            2,
            'break leaves the loop. continue skips to the next iteration instead.'),
      ]),
  Lesson(
      'functions',
      'Build with functions',
      'Small reusable pieces make big problems easier.',
      4,
      Icons.functions,
      [
        (
          'One job, one function',
          'A function groups instructions under a name. Call the function whenever you need that work done. A focused function is easier to read, test and reuse.'
        ),
        (
          'Inputs and outputs',
          'Parameters are named inputs in a function definition. Arguments are the actual values passed when calling it. return sends a result back to the caller.'
        ),
        (
          'Describe your result',
          'The return type tells readers what kind of value to expect. int means a whole-number result. void means the function does not return a useful value.'
        ),
      ],
      'int add(int a, int b) {\n  return a + b;\n}\nfinal result = add(2, 3); // 5',
      [
        Question(
            'What does return do?',
            [
              'Repeats the function',
              'Sends a result to the caller',
              'Creates a loop',
              'Always prints text'
            ],
            1,
            'return ends the function call and can provide a value to its caller.'),
        Question(
            'For int add(int a, int b) => a + b, what is add(2, 3)?',
            ['23', '6', '5', '2'],
            2,
            'The arguments 2 and 3 are added together, returning 5.'),
        Question(
            'What does a void return type mean?',
            [
              'No parameters',
              'The function cannot run',
              'No useful return value',
              'Always returns zero'
            ],
            2,
            'A void function performs work without returning a useful result.'),
      ]),
  Lesson(
      'collections',
      'Keep things together',
      'Organize related values with lists and maps.',
      4,
      Icons.view_list_outlined,
      [
        (
          'A list of possibilities',
          'A List holds an ordered collection of values. Indexes start at zero. In [10, 20, 30], index 0 contains 10, and index 2 contains 30.'
        ),
        (
          'Grow your collection',
          'Use add to append an item to a growable list. The length property tells you how many items it contains. Accessing an index outside the list throws an error.'
        ),
        (
          'Find by a key',
          'A Map associates keys with values. A profile map can store a name under the key name and an age under the key age. Each key identifies one entry.'
        ),
      ],
      "final fruits = ['Apple', 'Mango'];\nfruits.add('Pear');\nprint(fruits[0]); // Apple\nprint(fruits.length); // 3",
      [
        Question(
            'What is the first valid index of a non-empty Dart list?',
            ['1', '-1', '0', 'The list length'],
            2,
            'Lists use zero-based indexing, so the first element is at index 0.'),
        Question(
            'A list has two items. After adding one item, what is its length?',
            ['1', '2', '3', '0'],
            2,
            'Adding one item increases the length from two to three.'),
        Question(
            'Which collection associates keys with values?',
            ['List', 'Map', 'int', 'bool'],
            1,
            'A Map stores key-value pairs, letting you retrieve values using their keys.'),
      ]),
  Lesson(
      'debugging',
      'Become a bug detective',
      'Turn unexpected behavior into a useful clue.',
      3,
      Icons.bug_report_outlined,
      [
        (
          'Three kinds of trouble',
          'A syntax error breaks the language rules. A runtime error occurs while a program runs. A logic error lets a program run but produce the wrong result.'
        ),
        (
          'Reproduce, inspect, simplify',
          'First find steps that reliably reproduce the problem. Read error messages and inspect relevant values. Reduce the problem to a small example so you can understand its cause.'
        ),
        (
          'Test your boundaries',
          'Try an empty list, zero, and values at the edge of a condition. After a fix, run the original failing case and related cases. A test checks actual behavior against expected behavior.'
        ),
      ],
      'final values = [10, 20];\nprint(values[1]); // 20\n// values[2] would be out of range.\n// Valid indexes: 0 through length - 1.',
      [
        Question(
            'A program runs but calculates the wrong total. What is this?',
            [
              'A logic error',
              'Always a syntax error',
              'A successful test',
              'A compiler feature'
            ],
            0,
            'A logic error produces incorrect behavior even though the program can run.'),
        Question(
            'Which index is invalid for a list with two items?',
            ['0', '1', '2', 'Both 0 and 1'],
            2,
            'The valid indexes are 0 and 1. Index 2 is outside the list.'),
        Question(
            'What should you do after fixing a bug?',
            [
              'Skip the failing case',
              'Only rename variables',
              'Test the original failure and related cases',
              'Remove every test'
            ],
            2,
            'Rechecking the failure verifies the fix. Related cases reveal unintended effects.'),
      ]),
];
