import 'package:flutter/material.dart';
import 'lessons.dart';
import 'bonus_quizzes.dart';
import 'language_courses.dart';

List<Lesson> extendedCourse(StudyLanguage lang) {
  final name = languageName(lang),
      py = lang == StudyLanguage.python,
      java = lang == StudyLanguage.java,
      c = lang == StudyLanguage.c;
  Question q(String text, List<String> answers, int correct, String why,
          {String? code}) =>
      Question(text, answers, correct, why,
          code: code,
          kind: code == null ? QuestionKind.choice : QuestionKind.output);
  Lesson chapter(
          String id,
          String title,
          String intro,
          IconData icon,
          List<(String, String)> text,
          String code,
          List<Question> easy,
          List<Question> hard) =>
      Lesson('${lang.name}:$id', '$name · $title', intro, 5, icon, text, code,
          easy,
          challengeQuestions: hard,
          practiceQuestions: bonusQuizQuestions(lang, id));
  final read = py
      ? 'age = int(input("Your age: "))\nprint(age)'
      : java
          ? '// Import java.util.Scanner at the top of the file.\nScanner scanner = new Scanner(System.in);\nint age = scanner.nextInt();\nSystem.out.println(age);'
          : c
              ? 'int age;\nif (scanf("%d", &age) == 1) {\n  printf("Age: %d\\n", age);\n}'
              : 'int age;\nif (std::cin >> age) {\n  std::cout << "Age: " << age;\n}';
  final arithmetic = py
      ? 'print(7 / 2)   # 3.5\nprint(7 // 2)  # 3\nprint(7 % 2)   # 1'
      : 'int a = 7;\nint b = 2;\n// a / b is 3 (integer division)\n// a % b is 1 (remainder)\n// 7.0 / 2 is 3.5';
  final strings = py
      ? 'word = "code"\nprint(len(word))  # 4\nprint(word[0])    # c'
      : java
          ? 'String word = "code";\nSystem.out.println(word.length()); // 4\nSystem.out.println(word.charAt(0)); // c'
          : c
              ? '// Include <string.h> for strlen.\nchar word[] = "code";\n// strlen(word) is 4\nprintf("%c", word[0]); // c'
              : '// Include <string>.\nstd::string word = "code";\nstd::cout << word.length(); // 4\nstd::cout << word[0];       // c';
  final whileCode = py
      ? 'count = 3\nwhile count > 0:\n    print(count)\n    count -= 1'
      : 'int count = 3;\nwhile (count > 0) {\n  ${java ? 'System.out.println(count);' : c ? 'printf("%d\\n", count);' : 'std::cout << count << "\\n";'}\n  count--;\n}';
  final nested = py
      ? 'for row in range(2):\n    for column in range(3):\n        print("*")\n# Six stars, each on a new line.'
      : 'for (int row = 0; row < 2; row++) {\n  for (int column = 0; column < 3; column++) {\n    ${java ? 'System.out.println("*");' : c ? 'printf("*\\n");' : 'std::cout << "*\\n";'}\n  }\n}';
  final search = py
      ? 'values = [4, 9, 2]\nposition = -1\nfor i in range(len(values)):\n    if values[i] == 9:\n        position = i\n        break\nprint(position)  # 1'
      : '${java ? 'int[] values = {4, 9, 2};' : 'int values[] = {4, 9, 2};'}\nint position = -1;\nfor (int i = 0; i < 3; i++) {\n  if (values[i] == 9) {\n    position = i;\n    break;\n  }\n}\n// position is 1';
  final sorting = py
      ? 'values = [3, 1, 2]\nfor end in range(len(values) - 1, 0, -1):\n    for i in range(end):\n        if values[i] > values[i + 1]:\n            values[i], values[i + 1] = values[i + 1], values[i]\nprint(values)  # [1, 2, 3]'
      : '${java ? 'int[] values = {3, 1, 2};' : 'int values[] = {3, 1, 2};'}\nfor (int end = 2; end > 0; end--) {\n  for (int i = 0; i < end; i++) {\n    if (values[i] > values[i + 1]) {\n      int temp = values[i];\n      values[i] = values[i + 1];\n      values[i + 1] = temp;\n    }\n  }\n}\n// values is now {1, 2, 3}';
  final recursion = py
      ? 'def sum_to(n):\n    if n == 0:\n        return 0\n    return n + sum_to(n - 1)\n\nprint(sum_to(3))  # 6'
      : '${java ? 'static ' : ''}int sumTo(int n) {\n  if (n == 0) return 0;\n  return n + sumTo(n - 1);\n}\n// sumTo(3) returns 6. Use nonnegative n.';
  final structure = py
      ? 'student = {"name": "Sam", "score": 80}\nprint(student["score"])  # 80\nstudent["score"] = 90'
      : java
          ? 'class Student {\n  String name;\n  int score;\n}\n// Inside main:\nStudent student = new Student();\nstudent.name = "Sam";\nstudent.score = 80;'
          : c
              ? 'struct Student {\n  char name[20];\n  int score;\n};\n// Inside main:\nstruct Student student = {"Sam", 80};\nprintf("%d", student.score);'
              : 'struct Student {\n  std::string name;\n  int score;\n};\n// Inside main (include <string>):\nStudent student = {"Sam", 80};\nstd::cout << student.score;';
  final file = py
      ? 'with open("practice.txt", "w", encoding="utf-8") as file:\n    file.write("Hello file!")\nwith open("practice.txt", "r", encoding="utf-8") as file:\n    print(file.read())'
      : java
          ? '// Imports: java.nio.file.Files, java.nio.file.Path\n// This snippet belongs in a method declaring throws IOException.\nPath path = Path.of("practice.txt");\nFiles.writeString(path, "Hello file!");\nSystem.out.println(Files.readString(path));'
          : c
              ? '// Include <stdio.h>.\nFILE *file = fopen("practice.txt", "w");\nif (file != NULL) {\n  fprintf(file, "Hello file!");\n  fclose(file);\n}'
              : '// Include <fstream>.\nstd::ofstream file("practice.txt");\nif (file) {\n  file << "Hello file!";\n}\nfile.close();';
  final project = py
      ? 'scores = [50, 80, 90]\nif len(scores) > 0:\n    average = sum(scores) / len(scores)\n    print(average)'
      : '${java ? 'int[] scores = {50, 80, 90};' : 'int scores[] = {50, 80, 90};'}\nint total = 0;\nfor (int i = 0; i < 3; i++) {\n  total += scores[i];\n}\ndouble average = total / 3.0;\n// average is approximately 73.33';
  return [
    chapter(
        'input',
        'Talk to your program',
        'Ask a question. Read an answer. Validate it.',
        Icons.keyboard_rounded,
        [
          (
            'Input flows in',
            'Output displays information; input brings information into a program. Read input into a variable so later instructions can use it. ${py ? 'input returns text; int converts suitable text into a whole number.' : java ? 'Scanner reads tokens from System.in; nextInt reads an integer token.' : c ? 'scanf reads formatted input. Pass the address of age using &age, and check that one value was read.' : 'std::cin extracts input. Its success can be tested before using the variable.'}'
          ),
          (
            'Bad input is normal',
            'A person may type letters when you expect a number. ${py ? 'int("abc") raises ValueError; use a try/except handler when accepting untrusted text.' : java ? 'nextInt can throw InputMismatchException; hasNextInt lets you check before reading.' : c ? 'Check the return value of scanf. Do not use an uninitialized variable after a failed conversion.' : 'Check the stream state. A failed extraction must be handled before using the input.'}'
          ),
          (
            'Mission: friendly greeter',
            'Ask for a name and greet the learner. Then ask for an age. Test a valid number, an empty answer and letters. Imports and headers belong at the top of the source file; statement snippets belong in your main program.'
          ),
        ],
        read,
        [
          q(
              'Which direction does input travel?',
              [
                'Into the program',
                'Only onto the screen',
                'Into a printer only',
                'Nowhere'
              ],
              0,
              'Input supplies data for the program to process.'),
          q(
              'Where can a program keep a typed age?',
              [
                'In a variable',
                'Only in a comment',
                'In the file name',
                'In the keyboard layout'
              ],
              0,
              'Store input in a named variable.'),
          q(
              'What should you do with invalid input?',
              [
                'Handle it and ask again or explain the problem',
                'Always crash',
                'Use an uninitialized value',
                'Pretend the value is correct'
              ],
              0,
              'Validation makes programs predictable and user-friendly.')
        ],
        [
          q(
              'A user types abc instead of an age. What is the best response?',
              [
                'Validate or handle the failed conversion',
                'Treat it as 18',
                'Skip every check',
                'Assume a valid integer was read'
              ],
              0,
              'Input can fail to convert; do not use a value until the read succeeds.'),
          q(
              'If valid input is 21, which value should be stored as the age?',
              ['12', '21', '0', 'Always 18'],
              1,
              'A successful integer read preserves the entered number.'),
          q(
              'Why separate reading and validation from calculations?',
              [
                'It makes failures easier to handle and test',
                'It removes the need for input',
                'It prevents output',
                'It makes every number a string'
              ],
              0,
              'A clear boundary keeps invalid data out of calculations.')
        ]),
    chapter(
        'operators',
        'The operator toolbox',
        'Calculate, compare and combine conditions.',
        Icons.calculate_outlined,
        [
          (
            'Arithmetic tools',
            '+ adds, - subtracts, * multiplies, and % gives a remainder for integers. Multiplication and division normally happen before addition and subtraction. Parentheses make your intended order explicit.'
          ),
          (
            'Division needs care',
            py
                ? 'In Python, / performs true division: 7 / 2 is 3.5. // performs floor division: 7 // 2 is 3. Use positive numbers first; flooring matters for negative operands.'
                : 'With two integer operands, 7 / 2 gives 3. Use a floating-point operand, such as 7.0, to get 3.5. Integer division truncates toward zero.'
          ),
          (
            'Mission: shopping receipt',
            'Calculate the price of three items, then add a delivery fee. Use parentheses to apply a discount to the item total before adding delivery. Predict the answer before running the program.'
          ),
        ],
        arithmetic,
        [
          q('What is 4 * 3?', ['7', '12', '43', '1'], 1,
              'Multiplication gives twelve.'),
          q('What does 7 % 2 produce?', ['1', '2', '3.5', '0'], 0,
              'Seven contains three whole twos, with remainder one.'),
          q(
              'How can you make evaluation order explicit?',
              [
                'Use parentheses',
                'Remove every operator',
                'Use random spacing only',
                'Rename the compiler'
              ],
              0,
              'Parentheses group the operations you want evaluated together.')
        ],
        [
          q('What is 2 + 3 * 4?', ['20', '14', '24', '9'], 1,
              'Multiply 3 by 4 first, then add 2.'),
          q(
              'What is 7 / 2 in this language when both operands are integers?',
              py ? ['3.5', '3', '1', '7'] : ['3', '3.5', '1', '7'],
              0,
              py
                  ? 'Python / returns true division, even for int operands.'
                  : 'Integer division truncates the fractional part.'),
          q('What is (2 + 3) * 4?', ['14', '9', '20', '24'], 2,
              'The parentheses make addition happen first: 5 * 4 is 20.')
        ]),
    chapter(
        'strings',
        'Play with text',
        'Measure text and access individual characters.',
        Icons.text_fields_rounded,
        [
          (
            'Text has structure',
            'A string represents text. ${c ? 'A C string is a character sequence terminated by a null character. The terminator is not part of its text length.' : 'Strings support operations for length and character access.'} "code" contains four characters.'
          ),
          (
            'Positions start at zero',
            '${py ? 'len(word) gives the length, and word[0] reads the first character. Strings are immutable.' : java ? 'word.length() gives the length, and word.charAt(0) reads the first character. Java strings are immutable.' : c ? 'strlen(word), from <string.h>, counts characters before the null terminator. word[0] accesses the first character. Allocate room for the terminator.' : 'std::string provides length() and indexed access. Include <string>. Only access positions inside the string.'} The examples use simple ASCII text; Unicode can require additional care.'
          ),
          (
            'Mission: name badge',
            'Read a name, display it in a greeting, and show its length. Test a short name and an empty name. Check for empty text before reading its first character.'
          ),
        ],
        strings,
        [
          q('How many characters are in code?', ['3', '4', '5', '0'], 1,
              'c, o, d and e make four.'),
          q(
              'What index holds the first character?',
              ['1', '0', '4', 'Always -1'],
              1,
              'Zero-based indexing starts with index 0.'),
          q(
              'What should you check before accessing the first character?',
              [
                'That the string is not empty',
                'Only the computer color',
                'Nothing ever',
                'That it contains a number'
              ],
              0,
              'An empty string has no first character.')
        ],
        [
          q('What is the character at index 2 of code?', ['c', 'o', 'd', 'e'],
              2, 'The positions are c=0, o=1, d=2 and e=3.'),
          q(
              'What is the last valid index for four ASCII characters?',
              ['4', '3', '5', '1'],
              1,
              'Four zero-based positions end at index 3.'),
          q(
              c
                  ? 'How much space is needed for the C string code including its terminator?'
                  : 'How many ASCII characters are in the empty string?',
              c
                  ? ['4 bytes', '5 bytes', '3 bytes', '0 bytes']
                  : ['0', '1', '2', '4'],
              c ? 1 : 0,
              c
                  ? 'Four letters plus the null terminator need five char slots.'
                  : 'The empty string has length zero.')
        ]),
    chapter(
        'while',
        'Control the countdown',
        'Repeat while a condition remains true.',
        Icons.timer_outlined,
        [
          (
            'Check before each turn',
            'A while loop tests its condition before every iteration. If the condition is false at the start, the body never runs.'
          ),
          (
            'Make progress toward stopping',
            'The countdown example subtracts one after each output. Without the update, count remains 3 and the loop never finishes. Plan what changes and when the condition becomes false.'
          ),
          (
            'Mission: countdown timer',
            'Count from 5 down to 1, then display Go! Try a starting value of zero too. Confirm the loop does not print a countdown for zero.'
          ),
        ],
        whileCode,
        [
          q(
              'When is a while condition checked?',
              [
                'Before each iteration',
                'Only after the program exits',
                'Never',
                'Only once at installation'
              ],
              0,
              'A while loop checks its condition before executing its body.'),
          q(
              'Why update a countdown variable?',
              [
                'To eventually reach the stopping condition',
                'To rename the loop',
                'To hide the value',
                'To prevent every output'
              ],
              0,
              'The update moves the state toward termination.'),
          q(
              'Can a while loop run zero times?',
              ['Yes', 'No, always once', 'Only with text', 'Only with arrays'],
              0,
              'If its first condition is false, the body is skipped.')
        ],
        [
          q(
              'What sequence does the example print?',
              ['0, 1, 2', '3, 2, 1', '3, 2, 1, 0', 'Only 3'],
              1,
              'count > 0 excludes zero.',
              code: whileCode),
          q(
              'If count starts at zero, how many iterations run?',
              ['0', '1', '3', 'Forever'],
              0,
              'The starting condition is false.'),
          q(
              'If the decrement is removed, what happens for count = 3?',
              [
                'An infinite loop',
                'Exactly three outputs',
                'The value becomes zero automatically',
                'The loop is skipped'
              ],
              0,
              'Nothing makes the true condition become false.')
        ]),
    chapter(
        'nested',
        'Loops inside loops',
        'Create grids, patterns and repeated combinations.',
        Icons.grid_on_rounded,
        [
          (
            'Outer and inner work',
            'A nested loop places one loop inside another. For every outer iteration, the inner loop runs through its full sequence.'
          ),
          (
            'Count the total work',
            'Two rows with three columns require 2 × 3 = 6 inner-body executions. Use different names for the two counters so you can reason about them separately.'
          ),
          (
            'Mission: star grid',
            'Draw a pattern with two rows and three stars per row. The example prints six separate lines; modify the output placement to create rows. Then predict a 3-by-4 pattern before running it.'
          ),
        ],
        nested,
        [
          q(
              'What is a nested loop?',
              [
                'A loop inside another loop',
                'Only a condition',
                'A renamed variable',
                'A file format'
              ],
              0,
              'The inner loop is part of the outer loop body.'),
          q('How many cells are in two rows of three?', ['5', '6', '3', '2'], 1,
              'Multiply rows by columns.'),
          q(
              'Why use row and column as separate names?',
              [
                'To track two different counters clearly',
                'They must always have the same value',
                'To disable the inner loop',
                'To turn numbers into strings'
              ],
              0,
              'Distinct names clarify which dimension is changing.')
        ],
        [
          q('How many stars does the example display?', ['2', '3', '6', '9'], 2,
              'The inner body runs 2 * 3 times.',
              code: nested),
          q(
              'How many inner executions occur for 3 outer iterations and 4 inner iterations?',
              ['7', '12', '4', '3'],
              1,
              'Each of three outer iterations performs four inner iterations.'),
          q(
              'Where should a row-ending newline go when building a rectangular pattern?',
              [
                'After the inner loop, within the outer loop',
                'Only before both loops',
                'Inside every calculation',
                'Nowhere in the program'
              ],
              0,
              'Finish a row after all of its columns are displayed.')
        ]),
    chapter(
        'debugging',
        'Become a bug detective',
        'Reproduce, inspect and fix one cause at a time.',
        Icons.bug_report_outlined,
        [
          (
            'Three different failures',
            'Syntax errors break language rules. Runtime errors or invalid operations happen while the program executes. Logic errors let the program run but produce the wrong result.'
          ),
          (
            'Follow the evidence',
            'Reproduce the failure with a specific input. Read the error message, inspect relevant values and reduce the example. Change one suspected cause, then repeat the original test.'
          ),
          (
            'Mission: repair an average',
            'A program calculates (10 + 20) * 2 and calls it an average. Explain why that is wrong, fix the operation and verify the result is 15. Test zero values and an empty collection when extending it.'
          ),
        ],
        py
            ? 'total = 10 + 20\naverage = total / 2\nprint(average)  # 15.0'
            : 'double total = 10 + 20;\ndouble average = total / 2;\n// average is 15',
        [
          q(
              'A running program gives a wrong total. What kind of issue is likely?',
              [
                'A logic error',
                'Always a keyboard failure',
                'A correct answer',
                'A file extension'
              ],
              0,
              'Incorrect logic can execute without a syntax error.'),
          q(
              'What should you do before changing code?',
              [
                'Reproduce and understand the failure',
                'Delete everything',
                'Change unrelated code',
                'Ignore the input'
              ],
              0,
              'A reproducible case lets you verify a fix.'),
          q(
              'What should you do after a fix?',
              [
                'Repeat the failing test and related cases',
                'Never run it again',
                'Only change the colors',
                'Remove the expected result'
              ],
              0,
              'Retesting confirms that the behavior improved.')
        ],
        [
          q('What is the average of 10 and 20?', ['30', '60', '15', '2'], 2,
              'Add the two values and divide by two.'),
          q(
              'Which boundary case matters before dividing by a collection length?',
              [
                'An empty collection',
                'Only a very long variable name',
                'A green screen',
                'The file icon'
              ],
              0,
              'An empty collection has length zero, so the division must be avoided.'),
          q(
              'Why change one suspected cause at a time?',
              [
                'To understand which change fixed the failure',
                'To make debugging random',
                'To guarantee no tests are needed',
                'To hide unrelated errors'
              ],
              0,
              'Small controlled changes make cause and effect easier to establish.')
        ]),
    chapter(
        'search',
        'Find a value',
        'Build your first linear-search algorithm.',
        Icons.search_rounded,
        [
          (
            'Check one candidate at a time',
            'Linear search scans a collection until it finds a target or reaches the end. It works even when the collection is not sorted.'
          ),
          (
            'Report found or missing',
            'The example starts position at -1, a sentinel meaning not found. When a match is found, it stores that index and breaks out of the loop. A result of zero is valid: it means the first element.'
          ),
          (
            'Mission: find a quiz score',
            'Search [4, 9, 2] for 9, then 7. Expect index 1 for 9 and -1 for the missing value. Try a target in the first position and an empty collection.'
          ),
        ],
        search,
        [
          q(
              'Does linear search require sorted data?',
              ['No', 'Yes, always', 'Only descending data', 'Only one item'],
              0,
              'It checks candidates one by one regardless of their order.'),
          q(
              'What does an index of zero mean?',
              [
                'The first element',
                'Always not found',
                'The final element',
                'An error'
              ],
              0,
              'Zero is a valid first position.'),
          q(
              'What does break do after a match?',
              [
                'Stops the loop',
                'Erases the collection',
                'Sorts everything',
                'Starts a second search'
              ],
              0,
              'The search can stop once the desired match has been found.')
        ],
        [
          q('What position does the example find for 9?', ['0', '1', '2', '-1'],
              1, 'Nine is the second element, at index 1.',
              code: search),
          q(
              'What remains in position when searching for 7 in [4, 9, 2]?',
              ['-1', '0', '7', '2'],
              0,
              'No match changes the not-found sentinel.'),
          q(
              'In the worst case, how many items does linear search inspect in n items?',
              ['n', 'Always 1', 'Always 0', 'n squared'],
              0,
              'A missing target or a last-position target can require every item.')
        ]),
    chapter(
        'sorting',
        'Put values in order',
        'Use comparisons and swaps to sort a small collection.',
        Icons.sort_rounded,
        [
          (
            'An ordering rule',
            'Ascending order means smaller values come first. Bubble sort compares neighboring values and swaps them when they are out of order.'
          ),
          (
            'One pass is not always enough',
            'After a full ascending pass, a largest remaining value has moved to the right. Repeating passes sorts the rest. Bubble sort is useful for learning; library sorting routines are usually better for real applications.'
          ),
          (
            'Mission: sort the scoreboard',
            'Trace [3, 1, 2] by hand: compare 3 and 1, then 3 and 2. Explain the swaps. Test an already sorted list, duplicates and an empty collection.'
          ),
        ],
        sorting,
        [
          q(
              'What is ascending order?',
              [
                'Smallest to largest',
                'Largest to smallest',
                'Random order',
                'Only equal values'
              ],
              0,
              'Ascending order increases from left to right.'),
          q(
              'What does a swap do?',
              [
                'Exchanges two values',
                'Always deletes both',
                'Copies the file',
                'Stops the program'
              ],
              0,
              'A swap exchanges positions.'),
          q(
              'What does bubble sort compare?',
              [
                'Neighboring elements',
                'Only file names',
                'Unrelated screens',
                'Only the first value forever'
              ],
              0,
              'Adjacent comparisons move out-of-order values toward their destinations.')
        ],
        [
          q(
              'What is [3, 1, 2] after the first complete ascending bubble-sort pass?',
              ['[1, 2, 3]', '[3, 2, 1]', '[2, 3, 1]', '[3, 1, 2]'],
              0,
              'Swap 3 with 1, then swap 3 with 2.'),
          q(
              'When should adjacent values a and b be swapped for ascending order?',
              ['When a > b', 'Whenever a < b', 'Only if a == b', 'Never'],
              0,
              'A larger left neighbor is out of ascending order.'),
          q(
              'What is a drawback of basic bubble sort for large inputs?',
              [
                'Its repeated passes can take quadratic time',
                'It cannot sort numbers',
                'It always loses values',
                'It requires data to be sorted first'
              ],
              0,
              'The nested passes can perform a number of comparisons proportional to n squared.')
        ]),
    chapter(
        'recursion',
        'A function that calls itself',
        'Solve a smaller version of the same problem.',
        Icons.account_tree_outlined,
        [
          (
            'The two essential pieces',
            'A recursive function calls itself. It needs a base case that ends the recursion and a recursive step that moves toward that base case.'
          ),
          (
            'Trace a small example',
            'sumTo(3) asks for 3 plus sumTo(2); that asks for 2 plus sumTo(1), then 1 plus sumTo(0). The base case returns zero. Unwinding the calls produces 6.'
          ),
          (
            'Mission: sum a range',
            'Trace the sum from 1 to 4 by hand, expecting 10. Use nonnegative inputs. A negative input would not reach the zero base case in this example. Very deep recursion can exhaust stack resources.'
          ),
        ],
        recursion,
        [
          q(
              'What makes a function recursive?',
              [
                'It calls itself',
                'It never has a name',
                'It only prints text',
                'It contains no conditions'
              ],
              0,
              'Recursion uses calls to the same function.'),
          q(
              'Why is a base case necessary?',
              [
                'To stop recursion',
                'To make all inputs strings',
                'To start an infinite loop',
                'To sort the code'
              ],
              0,
              'The base case returns without another recursive call.'),
          q(
              'What should each recursive step do?',
              [
                'Move toward the base case',
                'Always increase the problem without limit',
                'Remove every check',
                'Ignore the input'
              ],
              0,
              'The remaining problem must get closer to termination.')
        ],
        [
          q('What does sumTo(3) return?', ['3', '5', '6', '9'], 2,
              '3 + 2 + 1 + 0 equals 6.',
              code: recursion),
          q(
              'What is sumTo(0) in this example?',
              ['0', '1', 'An extra recursive call', '3'],
              0,
              'Zero is the base case.'),
          q(
              'Why is -1 an invalid input for this particular recurrence?',
              [
                'Subtracting one moves it away from zero',
                'It returns 1 immediately',
                'It sorts the values',
                'It changes the function name'
              ],
              0,
              'Without validation, negative inputs keep decreasing instead of reaching the base case.')
        ]),
    chapter(
        'structures',
        py
            ? 'Meet dictionaries'
            : java
                ? 'Your first object'
                : 'Group related fields',
        'Model one student with a name and a score.',
        Icons.view_in_ar_outlined,
        [
          (
            'One record, related information',
            py
                ? 'A dictionary maps keys to values. A student can store a name under the key name and a score under the key score. Keys identify entries; a missing key needs handling.'
                : java
                    ? 'A class describes fields and behavior. An object is an instance created from a class. The Student class groups a name and score into one record.'
                    : 'A struct groups named fields. A Student record keeps a name and score together. Access fields of an ordinary record with the dot operator.'
          ),
          (
            'Use the right access',
            py
                ? 'student["score"] reads the value under score. Assigning to that key replaces its value. Dictionary keys are distinct; this structure is not an indexed list.'
                : java
                    ? 'new Student() constructs an object. student.score reads its score field. Keep this Student class at class/file scope, not as a statement inside main.'
                    : c
                        ? 'Declare struct Student before main. A char name[20] field can hold up to 19 ordinary characters plus the string terminator. Avoid writing beyond its capacity.'
                        : 'Declare Student before main, and include <string>. C++ struct members are public by default; std::string manages its text storage.'
          ),
          (
            'Mission: student card',
            'Create two student records with different names and scores. Display each score. Change only the first score and check that the second record remains unchanged.'
          ),
        ],
        structure,
        [
          q(
              'Why group a name and score?',
              [
                'They describe one related record',
                'To erase both fields',
                'To prevent data access',
                'To force all scores to zero'
              ],
              0,
              'A structured record makes related information easier to manage.'),
          q(
              py
                  ? 'What identifies an entry in a dictionary?'
                  : 'What does the score field represent?',
              py
                  ? [
                      'A key',
                      'Always index zero',
                      'A file extension',
                      'A screen color'
                    ]
                  : [
                      'One piece of the record’s data',
                      'The entire program',
                      'A loop counter in every function',
                      'A source file name'
                    ],
              0,
              py
                  ? 'A dictionary associates keys with values.'
                  : 'Fields describe the data stored in a record.'),
          q(
              'How many student records do you need to represent two different students?',
              ['Two', 'Zero', 'Exactly ten', 'Only a comment'],
              0,
              'Each record represents one student.')
        ],
        [
          q(
              'What score is initially stored in the example?',
              ['80', '90', '20', '0'],
              0,
              'The record starts with a score of 80.',
              code: structure),
          q(
              py
                  ? 'What happens when an existing score key is assigned 90?'
                  : 'What does student.score = 90 change?',
              [
                'The score value',
                'Every student automatically',
                'The source file name',
                'The language'
              ],
              0,
              'The assignment updates that record’s score.'),
          q(
              py
                  ? 'What should you consider before reading a key that may be absent?'
                  : 'What is the benefit of a descriptive field name?',
              py
                  ? [
                      'Check for the key or use a suitable default',
                      'Assume every key exists',
                      'Use any random index',
                      'Delete the dictionary'
                    ]
                  : [
                      'It explains what the stored value means',
                      'It makes validation unnecessary',
                      'It prevents all bugs',
                      'It encrypts every record'
                    ],
              0,
              py
                  ? 'A missing dictionary key can cause KeyError when accessed directly.'
                  : 'Meaningful names improve readability and reduce confusion.')
        ]),
    chapter(
        'files',
        'Save a small file',
        'Learn basic persistent input and output.',
        Icons.description_outlined,
        [
          (
            'Memory and persistence',
            'Variables normally disappear when a process ends. A file stores data that another run can read. Practice using a new file named practice.txt.'
          ),
          (
            'Open, use, close',
            py
                ? 'Use with open to close a file automatically. Mode w writes and replaces existing contents; mode r reads. Choose an encoding such as UTF-8.'
                : java
                    ? 'Files.writeString and readString are available in Java 11 and later. Import Files and Path, and handle IOException or declare it in the containing method. Paths identify file locations.'
                    : c
                        ? 'fopen returns a FILE pointer or NULL on failure. Check before writing and call fclose afterward. Mode w creates or truncates a file.'
                        : 'Use <fstream>. Check the stream before writing, and close it when finished; its destructor also closes it. Opening an output stream in the default mode replaces existing contents.'
          ),
          (
            'Mission: save a greeting',
            'Save a short greeting, close the file, then read it back. Compare the text to the expected value. Handle a missing file or a location without write permission.'
          ),
        ],
        file,
        [
          q(
              'Why save data to a file?',
              [
                'To keep it beyond one run',
                'To make it disappear immediately',
                'To remove all variables',
                'To avoid naming data'
              ],
              0,
              'Files provide persistence.'),
          q(
              'What should happen after using an opened file?',
              [
                'Close it or use automatic resource management',
                'Always leave it open forever',
                'Erase the source code',
                'Ignore failures'
              ],
              0,
              'Closing releases resources and completes normal output handling.'),
          q(
              'Can opening a file fail?',
              [
                'Yes',
                'Never',
                'Only if the computer is green',
                'Only with numbers'
              ],
              0,
              'Missing paths and permissions are common failure causes.')
        ],
        [
          q(
              'What can write mode do to an existing file?',
              [
                'Replace its contents',
                'Always append without replacing',
                'Always preserve all old text',
                'Only rename it'
              ],
              0,
              'Write mode commonly truncates existing contents.'),
          q(
              'What should you do before using a file handle after open fails?',
              [
                'Handle the failure instead of using an invalid handle',
                'Write through it anyway',
                'Assume the file is open',
                'Ignore its return state'
              ],
              0,
              'Check success and report or recover from the error.'),
          q(
              'What is a useful verification after saving a greeting?',
              [
                'Read it back and compare the text',
                'Only inspect the icon color',
                'Delete the expected answer',
                'Change the compiler name'
              ],
              0,
              'Reading back verifies actual persisted content.')
        ]),
    chapter(
        'project',
        'Build a grade tracker',
        'Combine collections, loops, functions and decisions.',
        Icons.rocket_launch_outlined,
        [
          (
            'Define a small mission',
            'Build a program that stores quiz scores, calculates their average and reports whether the average meets a pass threshold. Start with fixed scores before adding user input.'
          ),
          (
            'Combine familiar tools',
            'Use a collection for scores, a loop or sum operation for the total, division for the average, and a condition for the pass result. Keep the calculation separate from reading and displaying data.'
          ),
          (
            'Mission checklist',
            'Test one score, several scores, values exactly on the pass threshold and an empty collection. Reject invalid scores outside your allowed range. For [50, 80, 90], the average is about 73.33. Add file saving only after the basic calculations work.'
          ),
        ],
        project,
        [
          q(
              'Which collection can hold several quiz scores?',
              [
                py ? 'A list' : 'An array',
                'Only one integer variable with no collection',
                'A file name by itself',
                'A comment'
              ],
              0,
              'A collection groups the scores for processing.'),
          q(
              'How is an average calculated?',
              [
                'Total divided by count',
                'Total multiplied by count',
                'Count minus total',
                'The last score only'
              ],
              0,
              'The arithmetic mean is the sum divided by the number of values.'),
          q(
              'Why build a small version first?',
              [
                'It is easier to test and understand',
                'It removes the need for testing',
                'It guarantees no bugs',
                'It prevents future improvements'
              ],
              0,
              'A working small version is a reliable base for the next feature.')
        ],
        [
          q('What is the average of [10, 20, 30]?', ['10', '20', '30', '60'], 1,
              'The sum is 60 and the count is 3, so the mean is 20.'),
          q(
              'What must happen for an empty score collection?',
              [
                'Handle it before dividing by its count',
                'Divide by zero',
                'Assume there are three scores',
                'Return a random score'
              ],
              0,
              'Zero scores have no ordinary arithmetic mean; handle that case explicitly.'),
          q(
              'If passing requires average >= 50, does an average of exactly 50 pass?',
              ['Yes', 'No', 'Only above 51', 'It cannot be tested'],
              0,
              'The comparison includes equality. This is why boundary tests matter.')
        ]),
  ];
}
