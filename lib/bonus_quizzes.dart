import 'lessons.dart';
import 'language_courses.dart';

/// Extra questions append after existing questions so saved mistake IDs stay valid.
List<Question> bonusQuizQuestions(StudyLanguage language, String topic) {
  final py = language == StudyLanguage.python,
      java = language == StudyLanguage.java;
  final c = language == StudyLanguage.c;
  String printValue(String value) => py
      ? 'print($value)'
      : java
          ? 'System.out.println($value);'
          : c
              ? 'printf("%d", $value);'
              : 'cout << $value;';
  Question q(String prompt, List<String> choices, int answer, String why,
          {String? code}) =>
      Question(prompt, choices, answer, why,
          code: code,
          kind: code == null ? QuestionKind.choice : QuestionKind.output);
  final bank = <String, List<Question>>{
    'hello': [
      q(
          'Which step actually displays your greeting?',
          [
            'Writing a comment',
            'Running the output statement',
            'Naming the file'
          ],
          1,
          'An output statement must execute to display a message.'),
      q(
          'Which is a useful first-program experiment?',
          [
            'Change the greeting and run again',
            'Delete every line without testing',
            'Learn all syntax first',
            'Never change the sample'
          ],
          0,
          'A small edit followed by a run makes cause and effect visible.'),
      q('What number appears?', ['8', '3', '5', '53'], 0,
          'The arithmetic expression 5 + 3 evaluates to 8.',
          code: printValue('5 + 3')),
      q(
          'A program runs but prints the wrong greeting. What should you inspect?',
          [
            'The text sent to the output statement',
            'Only the file size',
            'The name of the source file'
          ],
          0,
          'Inspect the actual value being printed, then run the changed program.')
    ],
    'variables': [
      q(
          'A game score changes from 4 to 9. Which concept stores the current score?',
          ['A variable', 'A comment', 'A fixed constant'],
          0,
          'A variable holds a value that the program can use and update.'),
      q('What is the final value of coins?', ['3', '7', '10', '37'], 2,
          'coins becomes its old value 3 plus 7.',
          code: py
              ? 'coins = 3\ncoins = coins + 7\nprint(coins)'
              : 'int coins = 3;\ncoins = coins + 7;\n${printValue('coins')}'),
      q(
          'Which name best describes the number of completed lessons?',
          ['x9', 'thing', 'completedLessons', 'tempAnything'],
          2,
          'A descriptive name explains what a stored value represents.'),
      q(
          'Which value naturally represents whether a task is complete?',
          [
            'A boolean',
            'A folder path only',
            'An array of all users',
            'A font size'
          ],
          0,
          'A boolean represents a true/false state.')
    ],
    'conditions': [
      q(
          'A badge is earned at 50 points or more. Which comparison includes 50?',
          ['points > 50', 'points < 50', 'points >= 50', 'points == 51'],
          2,
          'Greater than or equal includes the boundary value 50.'),
      q('With points = 49, is points >= 50 true?', ['Yes', 'No'], 1,
          '49 is below 50, so this condition is false.'),
      q(
          'Which tests check the boundary for age >= 18?',
          ['18 only', '17, 18 and 19', '1, 2 and 3', '100 and 200 only'],
          1,
          'Test immediately below, exactly at and immediately above a boundary.'),
      q(
          'You want both valid input AND enough credit. When should you continue?',
          [
            'Either one is true',
            'Both are true',
            'Both are false',
            'Credit is never checked'
          ],
          1,
          'A logical AND requires both conditions to be true.')
    ],
    'loops': [
      q('How many values are visited: 0, 1, 2, 3?', ['3', '4', '5', '0'], 1,
          'There are four iterations even though the first index is zero.'),
      q(
          'A loop should print five stars. Which test best checks it?',
          [
            'Count the five output stars',
            'Check only the variable name',
            'Change the phone theme',
            'Skip running it'
          ],
          0,
          'Compare actual output with the required number of repetitions.'),
      q('A loop visits 2, 4 and 6. What is their sum?',
          ['6', '10', '12', '246'], 2, '2 + 4 + 6 equals 12.'),
      q(
          'Why is a loop preferable to copying the same statement 100 times?',
          [
            'It expresses repetition in one place',
            'It prevents all bugs',
            'It needs no condition or collection ever',
            'It makes every program faster'
          ],
          0,
          'Loops organize repetition without maintaining many copied statements.')
    ],
    'functions': [
      q('A function doubles its input. What should doubleValue(7) return?',
          ['7', '14', '77', '2'], 1, 'Doubling 7 produces 14.'),
      q(
          'Which is a focused function responsibility?',
          [
            'Calculate the average of supplied scores',
            'Do every unrelated task',
            'Rename every file on the device',
            'Hide all errors'
          ],
          0,
          'A focused function performs one clear operation.'),
      q(
          'A function returns 12. Does that necessarily display 12?',
          [
            'Yes, every return prints',
            'No; returning and displaying are different',
            'Only in Java',
            'Only when the value is even'
          ],
          1,
          'Returning passes a result to the caller; printing displays output.'),
      q(
          'What should a useful function test specify?',
          [
            'Input and expected result',
            'Only a pretty name',
            'Only the number of comments',
            'The wallpaper'
          ],
          0,
          'For example, input 7 should produce the expected result 14.')
    ],
    'collections': [
      q('What is the first value in [8, 3, 6]?', ['0', '8', '3', '6'], 1,
          'Index zero refers to the first value, 8.'),
      q('A collection has five elements. Which index is invalid?',
          ['0', '2', '4', '5'], 3, 'Valid zero-based indices are 0 through 4.'),
      q(
          'You need every score to calculate a total. What should you do?',
          [
            'Visit all elements',
            'Use only the last element',
            'Count characters in its name',
            'Skip zero values always'
          ],
          0,
          'Every score contributes to the total, including a score of zero.'),
      q(
          'Before reading the first element, what matters for an empty collection?',
          [
            'Check that an element exists',
            'Assume index 0 is always valid',
            'Change the collection name',
            'Use index -100'
          ],
          0,
          'An empty collection has no valid first element.')
    ],
    'input': [
      q(
          'The user enters 6 and you double it. What result should appear?',
          ['3', '6', '12', '66'],
          2,
          'Convert numeric input as needed, then calculate 6 * 2 = 12.'),
      q(
          'A user enters abc when a number is required. What is the helpful response?',
          [
            'Explain the issue and ask for a number',
            'Pretend it is always 100',
            'Use an uninitialized value',
            'Crash intentionally'
          ],
          0,
          'Reject invalid input with an understandable message.'),
      q(
          'Why should you test input containing zero?',
          [
            'Zero can expose special cases',
            'Zero is never valid anywhere',
            'It changes every type to text',
            'It disables the keyboard'
          ],
          0,
          'Zero is a useful boundary test; whether it is valid depends on the task.'),
      q(
          'Which component is input rather than output?',
          [
            'A typed age',
            'The displayed result',
            'An error explanation shown to the user',
            'A printed greeting'
          ],
          0,
          'Input enters the program; output leaves it.')
    ],
    'operators': [
      q('What value is displayed?', ['20', '14', '10', '24'], 1,
          'Multiplication happens before addition: 2 + 12 = 14.',
          code: printValue('2 + 3 * 4')),
      q('What value is displayed?', ['14', '9', '20', '24'], 2,
          'Parentheses make 2 + 3 happen first; 5 * 4 = 20.',
          code: printValue('(2 + 3) * 4')),
      q('What is 17 % 5?', ['2', '3', '5', '12'], 0,
          'Three whole groups of 5 use 15, leaving a remainder of 2.'),
      q(
          'Which expression groups addition before multiplication?',
          ['2 + 3 * 4', '(2 + 3) * 4', '2 + (3 * 4)', '2 + 12'],
          1,
          'Parentheses explicitly group the addition.')
    ],
    'strings': [
      q('For the ASCII text "robot", how many characters are there?',
          ['4', '5', '6', '0'], 1, 'r, o, b, o and t are five characters.'),
      q('Which index selects b in "robot"?', ['0', '1', '2', '3'], 2,
          'Zero-based indexing gives r at 0, o at 1 and b at 2.'),
      q(
          'What is the last valid index in the five-character text "robot"?',
          ['5', '4', '3', '-5'],
          1,
          'The last character is at length minus one: 4.'),
      q(
          'Which is text rather than a numeric value?',
          ['"42"', '42', '4 + 2', '6 * 7'],
          0,
          'Quotes indicate the text representation of 42.')
    ],
    'while': [
      q(
          'A counter starts at 3 and decreases by 1 while it is > 0. How many iterations occur?',
          ['2', '3', '4', 'Forever'],
          1,
          'The body runs for counter values 3, 2 and 1.'),
      q(
          'If a while condition is false before the first check, how many times does its body run?',
          ['0', '1', '2', 'Forever'],
          0,
          'A while loop checks its condition before entering the body.'),
      q(
          'What makes a counter-controlled while loop finish?',
          [
            'The body moves the counter toward a false condition',
            'Its indentation color',
            'The variable name alone',
            'The screen brightness'
          ],
          0,
          'The update must eventually make the continuation condition false.'),
      q(
          'A loop waits for valid input. What is a useful exit condition?',
          [
            'Input passes validation',
            'The user makes another mistake',
            'A random comment appears',
            'The file name changes'
          ],
          0,
          'Continue when the requested input is valid; allow cancellation where appropriate.')
    ],
    'nested': [
      q(
          'An outer loop runs 3 times; an inner loop runs 4 times each. How many inner-body executions occur?',
          ['7', '12', '4', '3'],
          1,
          'Each of the three outer iterations contains four inner iterations: 3 * 4.'),
      q('Two rows each contain five seats. How many seats are visited by a row/seat nested loop?',
          ['2', '5', '7', '10'], 3, '2 * 5 = 10 seat visits.'),
      q(
          'If the outer loop runs zero times, how often does the inner body run?',
          ['0', '1', 'It must run once per column', 'Forever'],
          0,
          'Without an outer iteration, the inner loop is never entered.'),
      q(
          'What should you trace when a nested loop prints too many items?',
          [
            'Both loop bounds',
            'Only the app name',
            'Only comments',
            'Only the last printed character'
          ],
          0,
          'Either loop bound can change the total number of executions.')
    ],
    'debugging': [
      q(
          'A rectangle is 3 by 4. A program reports area 7. Which operation is likely wrong?',
          [
            'Addition used instead of multiplication',
            'Multiplication used instead of addition',
            'Division by 1',
            'Printing an integer'
          ],
          0,
          'Area is width times height: 3 * 4 = 12, not 3 + 4.'),
      q(
          'After fixing a bug, what should happen to the failing test case?',
          [
            'Run it again',
            'Delete it immediately',
            'Never look at it',
            'Change the expected result to match a bug'
          ],
          0,
          'The original failure should now produce the correct result.'),
      q(
          'Which is a useful debugging observation?',
          [
            'The counter becomes 6 on iteration 3',
            'The app has a nice icon',
            'The variable name is short',
            'A friend likes the color'
          ],
          0,
          'Concrete values and execution steps help locate a logical error.'),
      q(
          'A program calculates an average incorrectly. What helps most?',
          [
            'A small input with a known correct average',
            'Randomly editing every line',
            'Hiding the output',
            'Adding unrelated features'
          ],
          0,
          'A known result lets you compare actual and intended behavior.')
    ],
    'search': [
      q(
          'In [5, 8, 2, 8], where does a first-match search find 8?',
          ['Index 0', 'Index 1', 'Index 2', 'Index 3'],
          1,
          'The first occurrence of 8 is at zero-based index 1.'),
      q(
          'When searching an empty collection, how many values can be compared?',
          ['0', '1', '2', 'As many as the target value'],
          0,
          'There are no elements to compare.'),
      q(
          'A linear search does not find its target. Which result is a sensible convention?',
          [
            'A documented not-found value',
            'Always index 0',
            'A random valid index',
            'The collection length as a valid index'
          ],
          0,
          'Use a documented sentinel such as -1, or a suitable optional result.'),
      q(
          'For a first-match search, why stop after a match?',
          [
            'The required result is already known',
            'Later values cannot exist',
            'It sorts the collection',
            'It deletes duplicates'
          ],
          0,
          'Stopping avoids unnecessary comparisons once the first match is found.')
    ],
    'sorting': [
      q(
          'Sort [7, 2, 5] in ascending order.',
          ['[7, 5, 2]', '[2, 5, 7]', '[5, 2, 7]', '[2, 7, 5]'],
          1,
          'Ascending means smallest to largest.'),
      q(
          'In ascending bubble sort, adjacent values 9 and 4 should be...',
          ['Swapped', 'Deleted', 'Added together', 'Left because 9 is first'],
          0,
          '9 belongs after 4, so this adjacent pair is out of order.'),
      q(
          'After sorting [3, 1, 3], how many elements should remain?',
          ['1', '2', '3', '4'],
          2,
          'Sorting changes order; it does not remove duplicates.'),
      q(
          'Which property should hold after a correct ascending sort?',
          [
            'Every adjacent pair is in nondecreasing order',
            'All values are unique',
            'The original first value stays first',
            'Every value increases by 1'
          ],
          0,
          'Each element should be less than or equal to the next element.')
    ],
    'recursion': [
      q('A recursive sum has base case sumTo(0) = 0. What is sumTo(4)?',
          ['4', '6', '10', '16'], 2, '4 + 3 + 2 + 1 + 0 = 10.'),
      q(
          'Which input reaches the base case immediately for sumTo(0)?',
          ['0', '1', '4', '10'],
          0,
          'Input 0 already satisfies the base-case condition.'),
      q(
          'For nonnegative n, which recursive call moves toward the zero base case?',
          ['sumTo(n - 1)', 'sumTo(n + 1)', 'sumTo(n)', 'sumTo(n + 10)'],
          0,
          'Subtracting one reduces a positive input toward zero.'),
      q(
          'Why can very deep recursion fail?',
          [
            'It can exhaust the call stack',
            'It changes all numbers to strings',
            'It always sorts data',
            'It disables return statements'
          ],
          0,
          'Each active recursive call requires stack resources.')
    ],
    'structures': [
      q(
          'A student record contains name and score. What is its purpose?',
          [
            'Group related data',
            'Store only a loop condition',
            'Replace all functions',
            'Remove the need for validation'
          ],
          0,
          'Related fields describe one entity together.'),
      q(
          'Two students both score 80. Are they necessarily the same student?',
          ['Yes', 'No', 'Only when names are short', 'Only in Python'],
          1,
          'One equal field does not establish that two records represent the same entity.'),
      q(
          'You change one student score from 70 to 85. What should happen to an unrelated student?',
          [
            'Nothing unless explicitly changed',
            'Its score must also become 85',
            'It must disappear',
            'Its name becomes 85'
          ],
          0,
          'Independent records should remain unchanged unless your code updates them.'),
      q(
          'Which pair of fields describes a quiz result clearly?',
          [
            'questionId and correct',
            'red and blue only',
            'x and unknown',
            'font and wallpaper'
          ],
          0,
          'A result needs to identify the question and record the outcome.')
    ],
    'files': [
      q(
          'Which mode normally adds content after existing file data?',
          ['Append', 'Overwrite from the beginning', 'Delete', 'Rename only'],
          0,
          'Append writes at the end instead of replacing the existing content.'),
      q(
          'A file is missing. What should the program do?',
          [
            'Handle the failure and explain or recover',
            'Assume reading succeeded',
            'Use imaginary contents',
            'Hide every future error'
          ],
          0,
          'Missing files are an expected error case that needs handling.'),
      q(
          'Why close a file or use automatic resource management?',
          [
            'Release resources and finish pending writes appropriately',
            'Change its font',
            'Delete all stored data',
            'Make every file public'
          ],
          0,
          'Proper resource management prevents leaks and helps complete I/O operations.'),
      q(
          'What should a save/read-back test verify?',
          [
            'The restored content matches the saved content',
            'Only the file name color',
            'Only the app title',
            'Nothing after saving'
          ],
          0,
          'A round-trip test checks whether persisted data can be read back correctly.')
    ],
    'project': [
      q(
          'A grade tracker stores scores 60, 80 and 100. What is the average?',
          ['60', '80', '100', '240'],
          1,
          'The total is 240; divide by three scores to get 80.'),
      q(
          'What should a grade tracker do when no scores exist?',
          [
            'Show no average yet',
            'Divide zero by zero',
            'Invent a grade',
            'Use the first element anyway'
          ],
          0,
          'An empty collection has no ordinary arithmetic mean.'),
      q(
          'Which implementation order keeps a mini project manageable?',
          [
            'Input, validation, calculation, display, tests',
            'All features at once without running',
            'Only animations',
            'Only a name'
          ],
          0,
          'Small tested stages make errors easier to isolate.'),
      q(
          'What makes a mini project more than a copied example?',
          [
            'You can explain it and adapt it to a new case',
            'Its title is longer',
            'It has more blank lines',
            'It never accepts input'
          ],
          0,
          'Understanding is shown by explaining and modifying behavior independently.')
    ],
  };
  return bank[topic] ?? const [];
}
