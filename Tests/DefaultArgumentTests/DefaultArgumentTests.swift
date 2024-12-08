import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(DefaultArgumentMacros)
import DefaultArgumentMacros

let testMacros: [String: Macro.Type] = [
    "DefaultArgument": DefaultArgument.self
]
#endif

final class DefaultArgumentTests: XCTestCase {
    func testDefaultArgument() throws {
        #if canImport(DefaultArgumentMacros)
        assertMacroExpansion(
            """
            @DefaultArgument(funcName: "getItems", defaultValues: ["pageSize": 20, "pageToken": nil])
            protocol ItemRepositoryProtocol {
                func getItems(pageSize: Int, pageToken: String?) -> [Item]
            }
            """,
            expandedSource: """
            protocol ItemRepositoryProtocol {
                func getItems(pageSize: Int, pageToken: String?) -> [Item]
            }
            
            extension ItemRepositoryProtocol {
                func getItems(pageSize: Int = 20, pageToken: String? = nil) -> [Item] {
                    getItems(pageSize: pageSize, pageToken: pageToken)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDefaultArgumentAsyncThrows() throws {
        #if canImport(DefaultArgumentMacros)
        assertMacroExpansion(
            """
            @DefaultArgument(funcName: "getItems", defaultValues: ["pageSize": 20, "pageToken": nil])
            protocol ItemRepositoryProtocol {
                func getItems(pageSize: Int, pageToken: String?) async throws -> [Item]
            }
            """,
            expandedSource: """
            protocol ItemRepositoryProtocol {
                func getItems(pageSize: Int, pageToken: String?) async throws -> [Item]
            }
            
            extension ItemRepositoryProtocol {
                func getItems(pageSize: Int = 20, pageToken: String? = nil) async throws -> [Item] {
                    try await getItems(pageSize: pageSize, pageToken: pageToken)
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
