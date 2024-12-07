import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(DefaultArgumentMacro)
import DefaultArgumentMacro

let testMacros: [String: Macro.Type] = [
    "DefaultArgument": DefaultArgument.self
]
#endif

final class DefaultArgumentTests: XCTestCase {
    func testDefaultArgument() throws {
        #if canImport(DefaultArgumentMacro)
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
                func getItems(pageToken: String?) -> [Item] {
                    getItems(pageSize: 20, pageToken: pageToken)
                }
                func getItems() -> [Item] {
                    getItems(pageSize: 20, pageToken: nil)
                }
                func getItems(pageSize: Int) -> [Item] {
                    getItems(pageSize: pageSize, pageToken: nil)
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
        #if canImport(DefaultArgumentMacro)
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
                func getItems(pageToken: String?) async throws -> [Item] {
                    try await getItems(pageSize: 20, pageToken: pageToken)
                }
                func getItems() async throws -> [Item] {
                    try await getItems(pageSize: 20, pageToken: nil)
                }
                func getItems(pageSize: Int) async throws -> [Item] {
                    try await getItems(pageSize: pageSize, pageToken: nil)
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
