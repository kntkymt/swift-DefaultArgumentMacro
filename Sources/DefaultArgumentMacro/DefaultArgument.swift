import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

private extension StringLiteralExprSyntax {
    var contentText: String? {
        if let stringSegment = self.segments.first, case .stringSegment(let segment) = stringSegment {
            return segment.content.text
        }
        else {
            return nil
        }
    }
}

private extension FunctionDeclSyntax {
    var isAsyncFunc: Bool {
        signature.effectSpecifiers?.asyncSpecifier != nil
    }

    var isThrowsFunc: Bool {
        signature.effectSpecifiers?.throwsClause != nil
    }
}

private extension SyntaxProtocol {
    var extractFunctionCallIgnoreTryAwait: FunctionCallExprSyntax? {
        if let functionCall = self.as(FunctionCallExprSyntax.self) {
            return functionCall
        } else if let awaitExpr = self.as(AwaitExprSyntax.self) {
            return awaitExpr.expression.extractFunctionCallIgnoreTryAwait
        } else if let tryExpr = self.as(TryExprSyntax.self) {
            return tryExpr.expression.extractFunctionCallIgnoreTryAwait
        } else {
            return nil
        }
    }
}

public struct DefaultArgument: ExtensionMacro {
    enum DefaultArgumentMacroError: Error {
        case invalidArgument
        case functionNotFound
        case argNameNotFound
    }

    public static func getFuncName(of node: AttributeSyntax) throws -> String {
        let labeledExprList = node.arguments?.as(LabeledExprListSyntax.self)
        guard let funcName = labeledExprList?.first(where: { $0.label?.text == "funcName" })?.expression.as(StringLiteralExprSyntax.self)?.contentText else {
            throw DefaultArgumentMacroError.invalidArgument
        }

        return funcName
    }

    public static func getDefaults(of node: AttributeSyntax) throws -> [String: ExprSyntax] {
        let labeledExprList = node.arguments?.as(LabeledExprListSyntax.self)
        guard let dictionaryElements = labeledExprList?.first(where: { $0.label?.text == "defaultValues" })?.expression.as(DictionaryExprSyntax.self)?.content.as(DictionaryElementListSyntax.self) else {
            throw DefaultArgumentMacroError.invalidArgument
        }

        var result: [String: ExprSyntax] = [:]
        for dictionaryElement in dictionaryElements {
            if let argName = dictionaryElement.key.as(StringLiteralExprSyntax.self)?.contentText {
                result[argName] = dictionaryElement.value
            }
        }

        return result
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let funcName = try getFuncName(of: node)
        let defaults = try getDefaults(of: node)

        let targetDecl = declaration.memberBlock.members.first {
            $0.decl.as(FunctionDeclSyntax.self)?.name.text == funcName
        }?.decl

        guard var targetFuncDecl = FunctionDeclSyntax(targetDecl) else {
            throw DefaultArgumentMacroError.functionNotFound
        }

        do {
            let parameters = targetFuncDecl.signature.parameterClause.parameters
            let callParameters = parameters.map { parameter in
                let parameterLabel = parameter.firstName.text
                return "\(parameterLabel): \(parameterLabel)"
            }.joined(separator: ", ")

            var callBase = "\(funcName)(\(callParameters))"
            if targetFuncDecl.isAsyncFunc {
                callBase = "await " + callBase
            }
            if targetFuncDecl.isThrowsFunc {
                callBase = "try " + callBase
            }
            targetFuncDecl.body = CodeBlockSyntax(stringLiteral: "{\(callBase)}")
        }

        var overloadeds: [FunctionDeclSyntax] = []
        for (argName, defaultValue) in defaults.sorted(by: { $0.key < $1.key }) {
            try overloadeds.append(
                contentsOf: overloadeds.map { try apply(base: $0, argName: argName, defaultValue: defaultValue) }
            )

            overloadeds.append(
                try apply(base: targetFuncDecl, argName: argName, defaultValue: defaultValue)
            )
        }

        return [
            try ExtensionDeclSyntax(
                "extension \(type)",
                membersBuilder: {
                    overloadeds
                }
            )
        ]
    }

    public static func apply(base functionDecl: FunctionDeclSyntax, argName: String, defaultValue: ExprSyntax) throws -> FunctionDeclSyntax {
        var new = functionDecl
        do {
            // remove arg
            guard let index = new.signature.parameterClause.parameters.firstIndex(where: { syntax in
                syntax.firstName.text == argName
            }) else {
                throw DefaultArgumentMacroError.argNameNotFound
            }
            new.signature.parameterClause.parameters.remove(at: index)

            // remove trailing "," if exist (is there any better way...?)
            if !new.signature.parameterClause.parameters.isEmpty, let lastIndex = new.signature.parameterClause.parameters.lastIndex(where: { $0 == new.signature.parameterClause.parameters.last }) {
                new.signature.parameterClause.parameters[lastIndex].trailingComma = nil
            }
        }

        do {
            // add default value to the call
            guard var functionCall = new.body?.statements.first?.item.extractFunctionCallIgnoreTryAwait, let index = functionCall.arguments.firstIndex(where: { $0.label?.text == argName }) else {
                throw DefaultArgumentMacroError.argNameNotFound
            }
            functionCall.arguments[index].expression = defaultValue

            // FIXME: dirty codes
            var blockItem: ExprSyntaxProtocol? = functionCall
            if let call = blockItem, functionDecl.isAsyncFunc {
                blockItem = AwaitExprSyntax(expression: call)
            }
            if let call = blockItem, functionDecl.isThrowsFunc {
                blockItem = TryExprSyntax(expression: call)
            }
            if let blockItem {
                new.body?.statements = CodeBlockItemListSyntax(itemsBuilder: {
                    blockItem
                })
            }
        }

        return new
    }
}
