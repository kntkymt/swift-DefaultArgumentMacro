import DefaultArgument

struct Item {}
enum SortKind {
    case name
    case like
}

@DefaultArgument(funcName: "getUseritems", defaultValues: ["sortKind": SortKind.name, "pageSize": 20, "pageToken": nil])
@DefaultArgument(funcName: "getItems", defaultValues: ["sortKind": SortKind.name, "pageSize": 20, "pageToken": nil])
protocol ItemRepositoryProtocol {
    func getItem(id: String) async throws -> Item
    func getItems(sortKind: SortKind, pageSize: Int, pageToken: String?) async throws -> [Item]
    func getUseritems(userID: String, sortKind: SortKind, pageSize: Int, pageToken: String?) async throws -> [Item]
}

struct ItemRepository: ItemRepositoryProtocol {
    func getItem(id: String) async throws -> Item {
        .init()
    }

    func getItems(sortKind: SortKind, pageSize: Int, pageToken: String?) async -> [Item] {
        []
    }

    func getUseritems(userID: String, sortKind: SortKind, pageSize: Int, pageToken: String?) async throws -> [Item] {
        []
    }
}

do {
    let itemRepository: any ItemRepositoryProtocol = ItemRepository()
    _ = try await itemRepository.getItems()
    _ = try await itemRepository.getUseritems(userID: "1234")
} catch {

}
