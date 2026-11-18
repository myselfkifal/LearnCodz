import 'package:flutter/material.dart';
import 'lessons.dart';
import 'bonus_quizzes.dart';
import 'extended_courses.dart';

enum StudyLanguage { cpp, python, java, c }

StudyLanguage? activeLanguage;
String languageName(StudyLanguage l) => {
      StudyLanguage.cpp: 'C++',
      StudyLanguage.python: 'Python',
      StudyLanguage.java: 'Java',
      StudyLanguage.c: 'C'
    }[l]!;
StudyLanguage? parseLanguage(String? name) =>
    StudyLanguage.values.where((l) => l.name == name).firstOrNull;
final languageCourses = {
  for (final l in StudyLanguage.values) l: buildCourse(l)
};

List<Lesson> buildCourse(StudyLanguage lang) {
  final name = languageName(lang),
      py = lang == StudyLanguage.python,
      java = lang == StudyLanguage.java,
      c = lang == StudyLanguage.c;
  final output = py
      ? 'print("Hello!")'
      : java
          ? 'System.out.println("Hello!");'
          : c
              ? 'printf("Hello!\\n");'
              : 'std::cout << "Hello!" << std::endl;';
  final fullHello = py
      ? output
      : java
          ? 'public class Main {\n  public static void main(String[] args) {\n    $output\n  }\n}'
          : '${c ? '#include <stdio.h>' : '#include <iostream>'}\nint main() {\n  $output\n  return 0;\n}';
  final variable = py
      ? 'age = 18\nprice = 2.5\nname = "Sam"\nprint(age)'
      : java
          ? 'int age = 18;\ndouble price = 2.5;\nString name = "Sam";\nSystem.out.println(age);'
          : c
              ? 'int age = 18;\ndouble price = 2.5;\nchar name[] = "Sam";\nprintf("%d\\n", age);'
              : 'int age = 18;\ndouble price = 2.5;\nstd::string name = "Sam";\nstd::cout << age;';
  final condition = py
      ? 'score = 8\nif score >= 5:\n    print("Pass")\nelse:\n    print("Try again")'
      : 'int score = 8;\nif (score >= 5) {\n  ${java ? 'System.out.println("Pass");' : c ? 'printf("Pass");' : 'std::cout << "Pass";'}\n} else {\n  // Runs when score is below 5.\n}';
  final loop = py
      ? 'for i in range(3):\n    print(i)\n# Prints 0, 1, 2'
      : 'for (int i = 0; i < 3; i++) {\n  ${java ? 'System.out.println(i);' : c ? 'printf("%d\\n", i);' : 'std::cout << i << "\\n";'}\n}\n// Prints 0, 1, 2';
  final function = py
      ? 'def add(a, b):\n    return a + b\n\nprint(add(2, 3))  # 5'
      : '${java ? 'static ' : ''}int add(int a, int b) {\n  return a + b;\n}\n// Calling add(2, 3) produces 5.';
  final collection = py
      ? 'scores = [10, 20, 30]\nprint(scores[0])  # 10\nprint(len(scores))  # 3'
      : java
          ? 'int[] scores = {10, 20, 30};\nSystem.out.println(scores[0]); // 10\nSystem.out.println(scores.length); // 3'
          : 'int scores[3] = {10, 20, 30};\n${c ? 'printf("%d", scores[0]);' : 'std::cout << scores[0];'} // 10';
  Question q(String prompt, List<String> options, int answer, String why,
          {String? code}) =>
      Question(prompt, options, answer, why,
          code: code,
          kind: code == null ? QuestionKind.choice : QuestionKind.output);
  Lesson lesson(
          String id,
          String title,
          String subtitle,
          IconData icon,
          List<(String, String)> sections,
          String code,
          List<Question> easy,
          List<Question> hard) =>
      Lesson('${lang.name}:$id', '$name · $title', subtitle, 3, icon, sections,
          code, easy,
          challengeQuestions: hard,
          practiceQuestions: bonusQuizQuestions(lang, id));
  return [
    lesson(
        'hello',
        'Your first hello',
        'Start at zero. Make the computer say something.',
        Icons.waving_hand_rounded,
        [
          (
            'What is a program?',
            'A program is a set of instructions a computer follows. $name is a programming language: a way to write those instructions. You do not need previous programming knowledge for this path.'
          ),
          (
            'Meet your first instruction',
            'An output instruction displays a value. Text goes inside quotation marks. In $name, try: $output'
          ),
          (
            'How to run it',
            py
                ? 'Save a file as hello.py and run python hello.py in a terminal with Python installed. Python executes your script. Lines belonging to a block use indentation.'
                : java
                    ? 'Save the full example as Main.java. With a JDK installed, run javac Main.java, then java Main. The main method is the program entry point. Java is case-sensitive.'
                    : 'Save the full example as ${c ? 'hello.c' : 'hello.cpp'}. With ${c ? 'GCC' : 'g++'} installed, compile using ${c ? 'gcc hello.c -o hello' : 'g++ hello.cpp -o hello'}, then run the resulting program. main is the entry point. ${c ? 'stdio.h provides printf.' : 'iostream provides cout.'}'
          ),
          (
            'Your mini task',
            'Change Hello! to your own name. Predict what will appear before you run it. Later examples show short snippets; ${py ? 'they can be placed in a script' : java ? 'statements go inside main unless a method definition is shown' : 'statements go inside main unless a function definition is shown'}. The app teaches with guided questions; it does not compile arbitrary code.'
          ),
        ],
        fullHello,
        [
          q(
              'What is a program?',
              [
                'Instructions for a computer',
                'Only a picture',
                'A keyboard',
                'A password'
              ],
              0,
              'Programs describe instructions to execute.'),
          q(
              'What does an output instruction do?',
              [
                'Deletes the file',
                'Displays a value',
                'Creates a password',
                'Stops every program'
              ],
              1,
              'Output shows text or values to the user.'),
          q(
              'How do you usually mark text in code?',
              [
                'Quotation marks',
                'A question mark only',
                'An arrow only',
                'No punctuation ever'
              ],
              0,
              'Quoted text is a string literal.')
        ],
        [
          q(
              'What text does this instruction display?',
              ['Hello!', 'output', 'Nothing', 'The source file name'],
              0,
              'Only the quoted text is displayed.',
              code: output),
          q(
              'Which change displays a different greeting?',
              [
                'Change the quoted text',
                'Delete all quotation marks',
                'Remove the instruction',
                'Rename the computer'
              ],
              0,
              'The string literal supplies the displayed greeting.'),
          q(
              'What is a useful first debugging step?',
              [
                'Read the error and check the syntax',
                'Delete every file',
                'Change the hardware',
                'Ignore the result'
              ],
              0,
              'An error message often points to a missing symbol or incorrect name.')
        ]),
    lesson(
        'variables',
        'Name your values',
        'Store numbers and text, then change them.',
        Icons.inventory_2_outlined,
        [
          (
            'A name for a value',
            'A variable associates a name with a value. age stores a whole number, and price stores a decimal. Use clear names to explain what your data means.'
          ),
          (
            'Numbers and text',
            py
                ? 'Python assigns values without a type declaration: age = 18. int values are whole numbers, float values have decimals, and str values contain text. = assigns a value.'
                : '$name uses declared types: int for whole numbers and double for decimals. ${c ? 'A single character uses char; a character array can store a string.' : java ? 'String stores text.' : 'std::string stores text when you include <string>.'} = assigns a value.'
          ),
          (
            'Your mini task',
            'Create a variable named points with value 10. Increase it by 2. The new value should be 12. Changing a variable updates the value associated with its name.'
          ),
        ],
        variable,
        [
          q(
              'What does = usually do?',
              [
                'Assigns a value',
                'Always compares equality',
                'Starts a loop',
                'Prints automatically'
              ],
              0,
              '= is assignment.'),
          q('Which value is a whole number?', ['18', '2.5', '"Sam"', '"Hello"'],
              0, '18 has no fractional part.'),
          q(
              'Which variable name is clearer for a total price?',
              ['totalPrice', 'x1z', 'abcxyz', 'thingy'],
              0,
              'Meaningful names explain intent.')
        ],
        [
          q(
              'After points = 10 and then points = points + 2, what is points?',
              ['10', '2', '12', '102'],
              2,
              'The old value 10 plus 2 becomes 12.'),
          q(
              'Which operation leaves a value of 5 starting from 8?',
              ['Subtract 3', 'Add 3', 'Multiply by 3', 'Set it to 3'],
              0,
              '8 - 3 is 5.'),
          q(
              'What is a variable used for?',
              [
                'Associating a name with data',
                'Only printing a title',
                'Compiling the operating system',
                'Replacing the keyboard'
              ],
              0,
              'Variables let later instructions access named data.')
        ]),
    lesson(
        'conditions',
        'Choose a path',
        'Make decisions with if and else.',
        Icons.alt_route,
        [
          (
            'True or false',
            'Comparisons ask questions. score >= 5 checks whether score is at least five. == checks equality; = assigns a value. Do not confuse the two.'
          ),
          (
            'Pick a branch',
            'if runs its block when the condition is true. else runs the alternative when it is false. ${py ? 'A colon begins each block, and indentation groups its statements.' : 'Parentheses enclose the condition, and braces group statements.'}'
          ),
          (
            'Your mini task',
            'Create a grade checker: scores of 5 or higher pass. Try 4, 5 and 6. The exact boundary, 5, is a particularly useful test.'
          ),
        ],
        condition,
        [
          q(
              'When does an if block run?',
              [
                'When its condition is true',
                'Only at midnight',
                'Never',
                'Only after else'
              ],
              0,
              'if executes its body for a true condition.'),
          q('Which operator checks equality?', ['=', '==', '+', '*'], 1,
              '== compares values.'),
          q(
              'Which branch handles a false if condition?',
              ['else', 'print', 'return', 'int'],
              0,
              'else supplies the alternative.')
        ],
        [
          q(
              'For score = 5, is score >= 5 true?',
              ['Yes', 'No', 'Only for 6', 'It cannot be checked'],
              0,
              '>= includes equality, so five qualifies.'),
          q(
              'Which values should you test around a threshold of 5?',
              ['4, 5 and 6', 'Only 100', 'Only 0', 'No values'],
              0,
              'Testing just below, at and above a boundary exposes mistakes.'),
          q(
              'What happens when an if condition is false and there is no else?',
              [
                'The if body is skipped',
                'The body runs twice',
                'The program must crash',
                'The variable disappears'
              ],
              0,
              'Execution continues after the if statement.')
        ]),
    lesson(
        'loops',
        'Repeat with purpose',
        'Let a loop do the repetitive work.',
        Icons.loop,
        [
          (
            'Why repeat?',
            'Loops repeat a group of instructions. You can display three numbers without writing three separate output instructions.'
          ),
          (
            'Understand the range',
            py
                ? 'range(3) produces 0, 1 and 2. The upper bound is excluded. A for loop visits each value, assigning it to i.'
                : 'The loop initializes i to 0, runs while i < 3, and increments i after each run. The body runs for 0, 1 and 2.'
          ),
          (
            'Your mini task',
            'Change the loop to print values 0 through 4. Make sure it finishes. A loop whose stopping condition never changes may run forever.'
          ),
        ],
        loop,
        [
          q(
              'Why use a loop?',
              [
                'To repeat instructions',
                'To rename the language',
                'To disable output',
                'To encrypt everything'
              ],
              0,
              'Loops express repeated work.'),
          q('How many values are in 0, 1, 2?', ['2', '3', '4', '0'], 1,
              'There are three values.'),
          q(
              'What should a loop normally have?',
              [
                'A way to finish',
                'No condition or bounds ever',
                'Only text',
                'A password'
              ],
              0,
              'A stopping condition or finite sequence prevents endless repetition.')
        ],
        [
          q('How many times does the example loop run?',
              ['2', '3', '4', 'Forever'], 1, 'It visits 0, 1 and 2.',
              code: loop),
          q('What is the last value printed by the example?',
              ['3', '2', '0', '1'], 1, 'The upper bound 3 is excluded.'),
          q(
              'Which change produces five iterations starting at zero?',
              [
                py ? 'Use range(5)' : 'Use i < 5',
                py ? 'Use range(4)' : 'Use i < 4',
                'Start at 5 and never update',
                'Remove the body'
              ],
              0,
              'The values 0 through 4 give five iterations.')
        ]),
    lesson(
        'functions',
        'Build small helpers',
        'Give reusable work a name.',
        Icons.functions,
        [
          (
            'One job at a time',
            'A function groups a reusable piece of work. Parameters describe its inputs. Calling the function runs the work with actual argument values.'
          ),
          (
            'Return a result',
            'return sends a result back to the caller. add(2, 3) should return 5. ${py ? 'Python defines a function using def and an indented body.' : java ? 'Java functions are methods. This static method belongs inside the class, outside main.' : 'A function definition can go before main so that the later call knows its declaration.'}'
          ),
          (
            'Your mini task',
            'Write a helper that doubles a number. Think about its input and expected output: input 4 should produce 8.'
          ),
        ],
        function,
        [
          q(
              'Why create a function?',
              [
                'Reuse a named piece of work',
                'To avoid all variables',
                'Only to draw images',
                'To prevent inputs'
              ],
              0,
              'Functions package reusable behavior.'),
          q(
              'What does return do?',
              [
                'Sends a result to the caller',
                'Always prints a result',
                'Repeats forever',
                'Deletes arguments'
              ],
              0,
              'Returning and printing are different operations.'),
          q(
              'What are function inputs called in its definition?',
              ['Parameters', 'Screens', 'Folders', 'Pixels'],
              0,
              'Parameters name the inputs a function accepts.')
        ],
        [
          q('What does add(2, 3) return in this example?',
              ['23', '5', '6', '2'], 1, '2 + 3 is 5.',
              code: function),
          q('What should doubleValue(4) return?', ['4', '2', '8', '16'], 2,
              'Doubling means multiplying by two.'),
          q(
              'A function returns 5. Does that alone display 5?',
              [
                'No; output must be requested separately',
                'Always',
                'Only on Monday',
                'It always displays 0'
              ],
              0,
              'Returning delivers a result to the caller, not necessarily to the screen.')
        ]),
    lesson(
        'collections',
        py ? 'Meet your first list' : 'Meet your first array',
        'Keep related values in one place.',
        Icons.view_list_outlined,
        [
          (
            'Values in order',
            '${py ? 'A list' : 'An array'} stores multiple values in order. Indexes start at zero. In [10, 20, 30], the first element is at index 0 and has value 10.'
          ),
          (
            'Stay inside the bounds',
            'A three-element collection has valid indexes 0, 1 and 2. ${c || lang == StudyLanguage.cpp ? 'Accessing an array outside its bounds is undefined behavior and must be avoided.' : 'An invalid index raises an error or exception.'} ${py ? 'Use len(scores) to get its length.' : java ? 'Use scores.length to get an array length.' : 'This fixed array has three elements; keep track of its length when accessing it.'}'
          ),
          (
            'Your mini task',
            'Store three quiz scores and read the first and last. Predict each value before accessing it. Never access index 3 in a three-item collection.'
          ),
        ],
        collection,
        [
          q('What is the first index?', ['0', '1', '-1', '3'], 0,
              'Indexing starts at zero.'),
          q(
              'Why use a collection?',
              [
                'To group related values',
                'To erase every value',
                'To prevent loops',
                'To rename files'
              ],
              0,
              'Collections organize multiple related values.'),
          q('How many elements are shown in the example?', ['1', '2', '3', '4'],
              2, 'The collection contains 10, 20 and 30.')
        ],
        [
          q('What is scores[1] for values 10, 20, 30?', ['10', '20', '30', '1'],
              1, 'Index 1 is the second element: 20.'),
          q('Which index is outside a three-element collection?',
              ['0', '1', '2', '3'], 3, 'The last valid index is 2.'),
          q(
              'For a nonempty collection of length n, what is its last index?',
              ['n', 'n - 1', 'n + 1', 'Always 1'],
              1,
              'Zero-based indexes run from 0 to n - 1.')
        ]),
    ...extendedCourse(lang),
  ];
}
