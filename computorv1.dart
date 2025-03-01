import 'dart:io';
import 'dart:math';

// Main function: Accepts polynomial equation input and attempts to solve it
void main() {
  print("Enter a polynomial equation:");
  String? input = stdin.readLineSync();

  if (input == null || input.isEmpty) {
    print("Error: No input provided.");
    return;
  }

  try {
    PolynomialSolver solver = PolynomialSolver(input);
    solver.solve();
  } catch (e) {
    print("Error: ${e.toString()}");
  }
}

// Class to parse and solve polynomial equations up to degree 2
class PolynomialSolver {
  late List<double> coefficients; // Stores coefficients [constant, x, x²]
  late int degree; // Highest degree with non-zero coefficient
  late Map<int, double> allTerms; // Stores all terms, including higher degrees

  // Constructor: Initializes and parses the equation
  PolynomialSolver(String equation) {
    // Only allocate for degrees 0, 1, and 2 (quadratic equations only)
    coefficients = List.filled(3, 0.0);
    allTerms = {};

    _parseEquation(equation);
    degree = _determineDegree();
  }

  // Parses the equation string into coefficient values
  void _parseEquation(String equation) {
    equation = equation.replaceAll(" ", "");
    List<String> sides = equation.split('=');
    if (sides.length != 2) {
      throw FormatException("Invalid equation format.");
    }

    Map<int, double> leftTerms = _parseSide(sides[0]);
    Map<int, double> rightTerms = _parseSide(sides[1]);

    // Move all terms to the left side (standard form: ax² + bx + c = 0)
    rightTerms.forEach((key, value) {
      leftTerms[key] = (leftTerms[key] ?? 0) - value;
    });

    // Store all terms in allTerms map
    allTerms = leftTerms;

    // Store coefficients for terms with degree < 3
    leftTerms.forEach((key, value) {
      if (key < 3) {
        coefficients[key] = value;
      }
    });
  }

  // Parses one side of the equation into a map of {exponent: coefficient}
  Map<int, double> _parseSide(String side) {
    Map<int, double> terms = {};

    // Split at +/- signs, preserving the sign with the term
    List<String> termStrings = side.split(RegExp(r'(?=[-+])'));

    // Handle equation starting with +/- which creates an empty first element
    if (termStrings[0].isEmpty) {
      termStrings.removeAt(0);
    }

    // Process each term (e.g., "5*X^2", "-3*X", "+4")
    for (String term in termStrings) {
      term = term.trim();
      if (term.isEmpty) continue;
      // print('term: $term');

      if (term.contains("X")) {
        // Term contains variable X
        int exponent = 1; // Default exponent is 1 (e.g., for just "X")
        double coefficient = 1.0; // Default coefficient is 1

        // Extract exponent if present (e.g., "X^2")
        if (term.contains("^")) {
          int caretIndex = term.indexOf("^");
          exponent = int.tryParse(term.substring(caretIndex + 1)) ?? 1;
        }

        // Extract coefficient if present (e.g., "5*X")
        if (term.contains("*")) {
          int starIndex = term.indexOf("*");
          String coeffStr = term.substring(0, starIndex);
          // print('coeffStr: $coeffStr');
          coefficient = (coeffStr.isEmpty || coeffStr == "+")
              ? 1.0
              : (coeffStr == "-" ? -1.0 : double.tryParse(coeffStr) ?? 1.0);
        } else {
          // Handle terms like "X" or "-X" without explicit coefficient
          coefficient = term.startsWith("-") ? -1.0 : 1.0;
        }

        // print('coefficient at parising: $coefficient');
        // Add to map, combining like terms
        terms[exponent] = (terms[exponent] ?? 0) + coefficient;
      } else {
        // Handle constant term (no X)
        double value = double.tryParse(term) ?? 0.0;
        terms[0] = (terms[0] ?? 0) + value;
      }
    }

    return terms;
  }

  // Determines highest non-zero degree in the polynomial
  int _determineDegree() {
    // Find highest degree in allTerms map
    int highestDegree = 0;
    allTerms.forEach((key, value) {
      if (value != 0 && key > highestDegree) {
        highestDegree = key;
      }
    });
    return highestDegree;
  }

  // Main solving method - delegates to appropriate solver based on degree
  void solve() {
    print("Reduced form: ${_formatEquation()}");
    print("Polynomial degree: $degree");

    if (degree > 2) {
      print("The polynomial degree is strictly greater than 2, I can't solve.");
      return;
    }

    if (degree == 2) {
      _solveQuadratic(); // ax² + bx + c = 0
    } else if (degree == 1) {
      _solveLinear(); // bx + c = 0
    } else {
      _solveConstant(); // c = 0
    }
  }

  // Solves quadratic equation using the quadratic formula
  void _solveQuadratic() {
    double a = coefficients[2];
    double b = coefficients[1];
    double c = coefficients[0];

    double discriminant = b * b - 4 * a * c;

    if (discriminant > 0) {
      // Two real solutions
      double x1 = (-b + sqrt(discriminant)) / (2 * a);
      double x2 = (-b - sqrt(discriminant)) / (2 * a);

      // Sort solutions in descending order
      if (x1 < x2) {
        double temp = x1;
        x1 = x2;
        x2 = temp;
      }

      print("Discriminant is strictly positive, the two solutions are:");
      print(x1.toStringAsFixed(6));
      print(x2.toStringAsFixed(6));
    } else if (discriminant == 0) {
      // One real solution (double root)
      double x = -b / (2 * a);
      print("Discriminant is zero, the solution is:");
      print(x.toStringAsFixed(6));
    } else {
      // Complex solutions
      double realPart = -b / (2 * a);
      double imaginaryPart = sqrt(-discriminant) / (2 * a);
      print("Discriminant is negative, complex solutions:");
      print("$realPart + ${imaginaryPart}i");
      print("$realPart - ${imaginaryPart}i");
    }
  }

  // Solves linear equation (degree 1)
  void _solveLinear() {
    double b = coefficients[1];
    double c = coefficients[0];
    double solution = -c / b;
    print("The solution is:");
    print(solution.toStringAsFixed(6));
  }

  // Solves constant equation (degree 0)
  void _solveConstant() {
    if (coefficients[0] == 0) {
      print("Every real number is a solution.");
    } else {
      print("No solution.");
    }
  }

  // Formats the polynomial equation in standard form
  String _formatEquation() {
    List<String> terms = [];
    // Get the highest degree
    int highestDegree = _determineDegree();

    // Include all terms from 0 to highest degree
    for (int i = 0; i <= highestDegree; i++) {
      double coeff = allTerms[i] ?? 0.0;
      String sign = (coeff >= 0) ? "+" : "-";

      // No + sign for the first term if positive
      if (i == 0 && coeff >= 0) {
        sign = "";
      }

      // Use absolute value since sign is handled separately
      double absCoeff = coeff.abs();
      terms.add("$sign ${absCoeff} * X^$i");
    }

    // If no terms (all coefficients are zero), return "0 = 0"
    if (terms.isEmpty) {
      return "0 = 0";
    }

    return terms.join(" ") + " = 0";
  }
}
