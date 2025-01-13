import Foundation

// 数据模型
struct FileItem: Codable {
    let path: String           // 文件路径
    let description: String    // 文件描述或多语言 key
    var isLocalizedKey: Bool = false // 是否为多语言 key，默认值为 false
    var isSelected: Bool       // 是否默认选中
    var isURLScheme: Bool = false // 是否是URL Scheme
    var exists: Bool = false   // 文件是否存在，默认为 false

    // 完整初始化方法
    init(path: String, description: String, isLocalizedKey: Bool = false, isSelected: Bool, isURLScheme: Bool = false, exists: Bool = false) {
        self.path = path
        self.description = description
        self.isLocalizedKey = isLocalizedKey
        self.isSelected = isSelected
        self.isURLScheme = isURLScheme
        self.exists = exists
    }

    // 用于处理缺失字段的初始化方法
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        description = try container.decode(String.self, forKey: .description)
        isLocalizedKey = try container.decodeIfPresent(Bool.self, forKey: .isLocalizedKey) ?? false
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
        isURLScheme = try container.decodeIfPresent(Bool.self, forKey: .isURLScheme) ?? false
        exists = try container.decodeIfPresent(Bool.self, forKey: .exists) ?? false
    }
}

