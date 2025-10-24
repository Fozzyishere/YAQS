.pragma library

// Helper function to convert degrees to radians
function toRadians(degrees) {
    return degrees * (Math.PI / 180);
}

// Helper function to convert radians to degrees
function toDegrees(radians) {
    return radians * (180 / Math.PI);
}

// Mathematical constants
var constants = {
    PI: Math.PI,
    E: Math.E,
    LN2: Math.LN2,
    LN10: Math.LN10,
    LOG2E: Math.LOG2E,
    LOG10E: Math.LOG10E,
    SQRT1_2: Math.SQRT1_2,
    SQRT2: Math.SQRT2
};

// Safe evaluation function that handles advanced math
function evaluate(expression) {
    if (!expression || expression.trim() === '') {
        throw new Error("Empty expression");
    }

    try {
        // Start with trimmed expression
        var processed = expression.trim();

        // Replace 'x' with '*' for multiplication (case-insensitive)
        // First replace 'x' between digits using lookahead to avoid consuming characters
        while (/(\d)\s*x\s*/gi.test(processed)) {
            processed = processed.replace(/(\d)\s*x\s*/gi, '$1*');
        }
        // Also match standalone 'x' with word boundaries (but not in function names)
        processed = processed.replace(/\bx\b/gi, '*');

        // Replace power operator ^ with **
        processed = processed.replace(/\^/g, '**');

        // Replace mathematical constants (before function names to avoid conflicts)
        processed = processed
            .replace(/\bpi\b/gi, Math.PI)
            .replace(/\be\b/gi, Math.E);

        // Handle degree versions of trig functions (must be done before regular trig)
        // Use IIFE to create inline conversion from degrees to radians
        processed = processed
            .replace(/\bsind\s*\(/g, '(function(x) { return Math.sin(' + (Math.PI / 180) + ' * x); })(')
            .replace(/\bcosd\s*\(/g, '(function(x) { return Math.cos(' + (Math.PI / 180) + ' * x); })(')
            .replace(/\btand\s*\(/g, '(function(x) { return Math.tan(' + (Math.PI / 180) + ' * x); })(');

        // Replace function calls with Math object equivalents
        processed = processed
            // Trigonometric functions (radians)
            .replace(/\bsin\s*\(/g, 'Math.sin(')
            .replace(/\bcos\s*\(/g, 'Math.cos(')
            .replace(/\btan\s*\(/g, 'Math.tan(')
            .replace(/\basin\s*\(/g, 'Math.asin(')
            .replace(/\bacos\s*\(/g, 'Math.acos(')
            .replace(/\batan\s*\(/g, 'Math.atan(')
            .replace(/\batan2\s*\(/g, 'Math.atan2(')

            // Hyperbolic functions
            .replace(/\bsinh\s*\(/g, 'Math.sinh(')
            .replace(/\bcosh\s*\(/g, 'Math.cosh(')
            .replace(/\btanh\s*\(/g, 'Math.tanh(')
            .replace(/\basinh\s*\(/g, 'Math.asinh(')
            .replace(/\bacosh\s*\(/g, 'Math.acosh(')
            .replace(/\batanh\s*\(/g, 'Math.atanh(')

            // Logarithmic and exponential functions
            .replace(/\blog\s*\(/g, 'Math.log10(')    // log = base 10
            .replace(/\bln\s*\(/g, 'Math.log(')        // ln = natural log
            .replace(/\bexp\s*\(/g, 'Math.exp(')
            .replace(/\bpow\s*\(/g, 'Math.pow(')

            // Root functions
            .replace(/\bsqrt\s*\(/g, 'Math.sqrt(')
            .replace(/\bcbrt\s*\(/g, 'Math.cbrt(')

            // Rounding and absolute
            .replace(/\babs\s*\(/g, 'Math.abs(')
            .replace(/\bfloor\s*\(/g, 'Math.floor(')
            .replace(/\bceil\s*\(/g, 'Math.ceil(')
            .replace(/\bround\s*\(/g, 'Math.round(')
            .replace(/\btrunc\s*\(/g, 'Math.trunc(')

            // Min/Max
            .replace(/\bmin\s*\(/g, 'Math.min(')
            .replace(/\bmax\s*\(/g, 'Math.max(')

            // Random
            .replace(/\brandom\s*\(\s*\)/g, 'Math.random()');

        // Sanitize expression - only allow safe characters
        // Allow: digits, operators, parentheses, decimal points, whitespace, Math object, function syntax
        // Also allow {, }, :, ; for IIFE function expressions (used in degree trig functions)
        if (!/^[0-9+\-*/%().\s\w,{}:;=]+$/.test(processed)) {
            throw new Error("Invalid characters in expression");
        }

        // Evaluate the processed expression
        var result = eval(processed);

        // Validate result
        if (result === Infinity || result === -Infinity) {
            throw new Error("Division by zero or overflow");
        }

        if (isNaN(result)) {
            throw new Error("Invalid calculation (NaN)");
        }

        if (!isFinite(result)) {
            throw new Error("Result is not a finite number");
        }

        return result;
    } catch (error) {
        // Re-throw our custom errors
        if (error.message.includes("Division by zero") ||
            error.message.includes("Invalid calculation") ||
            error.message.includes("Invalid characters") ||
            error.message.includes("Empty expression") ||
            error.message.includes("Result is not")) {
            throw error;
        }
        // Generic error for syntax issues
        throw new Error("Invalid expression: " + error.message);
    }
}

// Format result for display
function formatResult(result) {
    // Integer results don't need decimals
    if (Number.isInteger(result)) {
        return result.toString();
    }

    // Handle very large or very small numbers with scientific notation
    if (Math.abs(result) >= 1e15 || (Math.abs(result) < 1e-6 && result !== 0)) {
        return result.toExponential(6);
    }

    // Normal decimal formatting - round to 10 decimals to avoid floating point artifacts
    // Then parse back to remove trailing zeros
    return parseFloat(result.toFixed(10)).toString();
}

// Check if a string looks like a math expression
function isMathExpression(text) {
    if (!text || text.trim() === '') {
        return false;
    }

    var trimmed = text.trim();

    // Must contain at least one number or math function
    var hasNumber = /\d/.test(trimmed);
    var hasMathFunc = /\b(sin|cos|tan|sqrt|log|ln|abs|exp|pow|min|max|pi|e|sinh|cosh|tanh|cbrt|floor|ceil|round|trunc)\b/i.test(trimmed);
    var hasOperator = /[+\-*/^%()]/.test(trimmed);

    // Either has numbers with operators, or has math functions
    return (hasNumber && hasOperator) || hasMathFunc;
}

// Get list of available functions for help/documentation
function getAvailableFunctions() {
    return [
        // Basic arithmetic operators
        { category: "Basic Operators", functions: "+, -, *, /, %, ^, ()" },

        // Trigonometric functions (radians)
        { category: "Trigonometry (radians)", functions: "sin, cos, tan, asin, acos, atan, atan2" },

        // Trigonometric functions (degrees)
        { category: "Trigonometry (degrees)", functions: "sind, cosd, tand" },

        // Hyperbolic functions
        { category: "Hyperbolic", functions: "sinh, cosh, tanh, asinh, acosh, atanh" },

        // Logarithmic and exponential
        { category: "Logarithms & Exponential", functions: "log (base-10), ln (natural), exp" },

        // Roots and powers
        { category: "Roots & Powers", functions: "sqrt, cbrt, pow(x, y)" },

        // Rounding functions
        { category: "Rounding", functions: "abs, floor, ceil, round, trunc" },

        // Min/Max/Random
        { category: "Other", functions: "min, max, random" },

        // Constants
        { category: "Constants", functions: "pi, e" }
    ];
}