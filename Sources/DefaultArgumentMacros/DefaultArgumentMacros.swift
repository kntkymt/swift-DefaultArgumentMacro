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

        // add functionCallExpr
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

        // add defaultValues to decl
        for (argName, defaultValue) in defaults {
            guard let index = targetFuncDecl.signature.parameterClause.parameters.firstIndex(where: { $0.firstName.text == argName }) else {
                throw DefaultArgumentMacroError.argNameNotFound
            }
            targetFuncDecl.signature.parameterClause.parameters[index].defaultValue = InitializerClauseSyntax(value: defaultValue)
        }

        return [
            try ExtensionDeclSyntax(
                "extension \(type)",
                membersBuilder: {
                    targetFuncDecl
                }
            )
        ]
    }
}

@main
struct DefaultArgumentPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DefaultArgument.self,
    ]
}
