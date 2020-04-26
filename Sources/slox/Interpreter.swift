
import Foundation

class Interpreter {

    init() {}

    var environment = Environment()

    func interpret(_ statements: [Statement]) throws {
        for statement in statements {
            try evaluate(statement)
        }
    }
}

enum Value {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case `nil`
}

// MARK: - Statements

extension Interpreter {

    fileprivate func evaluate(_ statement: Statement) throws {
        switch statement {
        case let .print(expression): Swift.print(try evaluateExpression(expression))
        case let .expression(expression): _ = try evaluateExpression(expression)
        case let .var(variable, expression): environment.set(expression, for: variable)
        }
    }
}

// MARK: - Expressions

extension Interpreter {

    fileprivate func evaluateExpression(_ expression: Expression) throws -> Value {
        switch expression {
        case let .literal(literal): return evaluateLiteral(literal)
        case let .unary(unary): return try evaluateUnary(unary)
        case let .binary(binary): return try evaluateBinary(binary)
        case let .grouping(grouping): return try evaluateGrouping(grouping)
        case let .variable(variable): return try evaluateVariable(variable)
        }
    }

    fileprivate func evaluateLiteral(_ literal: Expression.Literal) -> Value {
        switch literal {
        case .number(let value): return .number(value)
        case .string(let value): return .string(value)
        case .false: return .boolean(false)
        case .true: return .boolean(true)
        case .nil: return .nil
        }
    }

    fileprivate func evaluateUnary(_ unary: Expression.Unary) throws -> Value {

        let value = try evaluateExpression(unary.expression)

        switch (unary.operator, value) {
        case (.negative, .number(let number)): return .number(-number)
        case (.negative, _): throw TypeMismatch(value: value, expected: .number(0))
        case (.not, _): return .boolean(value.isTruthy)
        }
    }

    fileprivate func evaluateBinary(_ binary: Expression.Binary) throws -> Value {

        let lhs = try evaluateExpression(binary.lhs)
        let rhs = try evaluateExpression(binary.rhs)

        switch (binary.operator, lhs, rhs) {

        case let (.plus, .number(lhs), .number(rhs)): return .number(lhs + rhs)
        case let (.minus, .number(lhs), .number(rhs)): return .number(lhs - rhs)
        case let (.divide, .number(lhs), .number(rhs)): return .number(lhs / rhs)
        case let (.multiply, .number(lhs), .number(rhs)): return .number(lhs * rhs)

        case let (.plus, .string(lhs), .string(rhs)): return .string(lhs + rhs)

        case let (.less, .number(lhs), .number(rhs)): return .boolean(lhs < rhs)
        case let (.lessEqual, .number(lhs), .number(rhs)): return .boolean(lhs <= rhs)
        case let (.greater, .number(lhs), .number(rhs)): return .boolean(lhs > rhs)
        case let (.greaterEqual, .number(lhs), .number(rhs)): return .boolean(lhs >= rhs)

        case (.equalEqual, _, _): return .boolean(lhs.isEqual(to: rhs))
        case (.notEqual, _, _): return .boolean(!lhs.isEqual(to: rhs))

        default: throw BinaryOperationFailure(operator: binary.operator, lhs: lhs, rhs: rhs)
        }
    }

    fileprivate func evaluateGrouping(_ grouping: Expression.Grouping) throws -> Value {
        try evaluateExpression(grouping.expression)
    }

    fileprivate func evaluateVariable(_ variable: Expression.Variable) throws -> Value {
        guard let expression = try environment.get(variable) else { return .nil }
        return try evaluateExpression(expression)
    }
}

extension Value {

    fileprivate var isTruthy: Bool {
        switch self {
        case .boolean(let value): return value
        case .nil: return false
        default: return true
        }
    }

    fileprivate func isEqual(to other: Self) -> Bool {
        switch (self, other) {
        case let (.number(lhs), .number(rhs)): return lhs == rhs
        case let (.string(lhs), .string(rhs)): return lhs == rhs
        case let (.boolean(lhs), .boolean(rhs)): return lhs == rhs
        case (.nil, .nil): return true
        default: return false
        }
    }
}

extension Value: CustomStringConvertible {

    var description: String {
        switch self {
        case let .boolean(value): return value.description
        case let .number(value): return value.description
        case let .string(value): return value
        case .nil: return "nil"
        }
    }
}

extension Value {

    fileprivate var typeName: String {
        switch self {
        case .boolean: return "Boolean"
        case .number: return "Number"
        case .string: return "String"
        case .nil: return "Nil"
        }
    }
}

// MARK: - Errors

struct BinaryOperationFailure: LocalizedError {
    let `operator`: Expression.Binary.Operator
    let lhs: Value
    let rhs: Value

    var errorDescription: String? {
        "Cannot perform operation \(`operator`) between operands \(lhs) and \(rhs)"
    }
}

struct TypeMismatch: LocalizedError {

    let value: Value
    let expected: Value

    var errorDescription: String? {
        "Expected \(expected.typeName) but found \(value.typeName)."
    }
}
