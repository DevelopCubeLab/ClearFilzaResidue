import Foundation
import UIKit

class FileRuleUtils {
    
    /// 默认内置规则
    /// Powered By Reveil3 database
    private let defaultRuleItems: [FileItem] = [
        FileItem(path: "Filza://", description: "Filza URL Scheme", isLocalizedKey: false, isSelected: true),
        FileItem(path: "/var/mobile/Library/Caches/com.tigisoftware.Filza", description: "Rule_1", isLocalizedKey: true, isSelected: true),
        FileItem(path: "/var/mobile/Library/SplashBoard/Snapshots/com.tigisoftware.Filza", description: "Rule_2", isLocalizedKey: true, isSelected: true),
        FileItem(path: "/var/mobile/Library/Application Support/Containers/com.tigisoftware.Filza", description: "Rule_3", isLocalizedKey: true, isSelected: true),
        FileItem(path: "/var/mobile/Library/Saved Application State/com.tigisoftware.Filza.savedState", description: "Rule_4", isLocalizedKey: true, isSelected: true),
        FileItem(path: "/var/mobile/Library/HTTPStorages/com.tigisoftware.Filza", description: "Rule_5", isLocalizedKey: true, isSelected: true),
        FileItem(path: "/var/mobile/Library/Filza", description: "Rule_6", isLocalizedKey: true, isSelected: false),
        FileItem(path: "/var/mobile/Library/Preferences/com.tigisoftware.Filza.plist", description: "Rule_7", isLocalizedKey: true, isSelected: false)
    ]
    
    /// 从 JSON 文件解析数据
    func loadItemsFromJSON(fileName: String) throws -> [FileItem]? {
        let fileManager = FileManager.default

        // 优先从沙盒的 Documents 目录加载规则文件
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let sandboxFileURL = documentsURL.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: sandboxFileURL.path) {
                do {
                    let data = try Data(contentsOf: sandboxFileURL)
                    let decoder = JSONDecoder()
                    var items = try decoder.decode([FileItem].self, from: data)
                    for index in items.indices {
                        items[index].exists = false
                        items[index].isLocalizedKey = false // 忽略用户导入的规则的i18n
                    }
                    print("使用沙盒中的 JSON 文件")
                    return items
                } catch {
                    print("解析沙盒 JSON 文件失败: \(error)")
                    throw error
                }
            }
        }

        // 如果沙盒中没有规则文件
        return nil
    }
    
    /// 获取默认规则
    func getDefaultRuleItems() -> [FileItem] {
        return self.defaultRuleItems
    }
    
    /// 判断文件/文件夹是否存在并且可写入
    /// 检查指定路径是否存在以及是否具有写权限
    /// - Parameter path: 需要检查的路径
    /// - Returns: 如果路径存在并具有写权限，则返回 `true`，否则返回 `false`
    func hasWritePermission(at path: String) -> Bool {
        // 检查路径是否存在
        guard FileManager.default.fileExists(atPath: path) else {
            return false
        }
        // 检查路径是否可写
        return access(path, W_OK) == 0
    }
    
    /// 判断传入的路径是否是文件路径
    /// - Parameter path: 要判断的路径字符串
    /// - Returns: `true` 如果是文件路径，`false` 如果是 URL Scheme
    func isFilePath(_ path: String) -> Bool {
        // 检查是否是文件路径
        if path.hasPrefix("/") {
            return true
        }
        
        // 检查是否是 URL Scheme
        if let url = URL(string: path),
           let scheme = url.scheme,
           path.contains("://"),
           isValidURLScheme(scheme) {
            return false
        }
        
        // 默认返回 false，表示无法识别为文件路径或 URL Scheme
        return false
    }
    
    /// 检查 URL Scheme 是否有效
    /// - Parameter scheme: URL 的 Scheme 部分
    /// - Returns: `true` 如果是合法的 Scheme，`false` 否则
    private func isValidURLScheme(_ scheme: String) -> Bool {
        // Scheme 必须以字母开头，且只能包含字母、数字、+、-、.
        let schemeRegex = "^[a-zA-Z][a-zA-Z0-9+\\-.]*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", schemeRegex)
        return predicate.evaluate(with: scheme)
    }
    
    /// 检查 URL Scheme 是否可用
    private func canOpenURLScheme(_ scheme: String) -> Bool {
        guard let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) else {
            return false
        }
        return true
    }
    
    /// 检查Root权限的方法
    func checkInstallPermission() -> Bool {
        return hasWritePermission(at: "/var/mobile/Library/Preferences")
    }
    
    /// 遍历 [FileItem] 数组并更新 `exists` 和 `isURLScheme` 属性
    /// - Parameter items: 待检查的 [FileItem] 数组
    /// - Returns: 更新后的 [FileItem] 数组
    func checkFileExistence(for items: [FileItem]) -> [FileItem] {
        var updatedItems = items
        for index in updatedItems.indices {
            let path = updatedItems[index].path
            if isFilePath(path) {
                // 文件路径处理
                updatedItems[index].exists = hasWritePermission(at: path)
                updatedItems[index].isURLScheme = false
            } else {
                // URL Scheme 处理
                updatedItems[index].exists = canOpenURLScheme(path)
                updatedItems[index].isURLScheme = true
            }
        }
        return updatedItems
    }
    
    /// 获取 isURLScheme 为 true 的列表, 这个是URL Scheme的列表
    func getURLSchemeItems(for items: [FileItem]) -> [FileItem] {
        return items.filter { $0.isURLScheme }
    }

    // 删除 isURLScheme 为 true 的 items, 这个是文件列表
    func removeURLSchemeItems(from items: [FileItem]) -> [FileItem] {
        return items.filter { !$0.isURLScheme }
    }
    
    /// 计算选中数量
    func getFileItemsSelectedCount(for items: [FileItem]) -> Int {
        return items.filter { $0.isSelected }.count
    }

    
    /// 删除指定路径的文件或文件夹
    /// - Parameter path: 需要删除的文件或文件夹路径
    /// - Returns: 如果删除成功返回 `true`，否则返回 `false`
    func deleteItem(at path: String) -> Bool {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) { // 文件不存在，直接不用删除，肯定成功
            return true
        }
        do {
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }
    
    // 删除规则内选中的文件
    func deleteItems(for items: [FileItem]) -> Bool {
        for item in items {
            if item.isSelected && !item.isURLScheme {
                if !deleteItem(at: item.path) {
                    return false
                }
            }
        }
        return true
    }
    
    /// 创建一个提示文件，让App的沙盒目录下的Document可以显示在文件App里
    func createTipsFile() {
        let fileManager = FileManager.default

        // 获取沙盒目录路径
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        // 定义文件路径
        let fileURL = documentsURL.appendingPathComponent(NSLocalizedString("Customer_Rule_Tips_FileName", comment: ""))

        // 检查文件是否存在
        if !fileManager.fileExists(atPath: fileURL.path) {
            do {
                // 如果文件不存在，则创建文件并写入内容
                // 文件内容
                let fileContent = NSLocalizedString("Customer_Rule_Tips_Content", comment: "")
                try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("无法创建文件: \(error)")
            }
        }
    }

}
