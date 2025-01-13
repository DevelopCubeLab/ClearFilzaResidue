import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    let versionCode = "1.0"
    
    var hasRootPermission = false
    
    private var tableView = UITableView()
    
    private let titleData = ["URL Scheme", NSLocalizedString("File", comment: ""), nil, NSLocalizedString("About", comment: "")]
    private let cellData = [[], [], [NSLocalizedString("Delete_Select_Files", comment: "")], [NSLocalizedString("Version_text", comment: ""), "GitHub", NSLocalizedString("Thanks_Reveil3", comment: "")]]
    
    private let fileRuleUtils: FileRuleUtils = FileRuleUtils()
    
    private var isCustomerRule = false
    
    private var ruleItems: [FileItem] = []
    private var schemeItems: [FileItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("CFBundleName", comment: "")
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        // check permission
        hasRootPermission = fileRuleUtils.checkInstallPermission()
        
        if !hasRootPermission { // 没有Root权限的弹窗
            showAlertDialog(messags: NSLocalizedString("Need_Install_With_TrollStore_text", comment: ""))
        }
        
        loadRuleData()
        
        // iOS 15 之后的版本使用新的UITableView样式
        if #available(iOS 15.0, *) {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: .zero, style: .grouped)
        }

        // 设置表格视图的代理和数据源
        tableView.delegate = self
        tableView.dataSource = self
        
        // 注册表格单元格
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        // 将表格视图添加到主视图
        view.addSubview(tableView)

        // 设置表格视图的布局
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadRuleData() {
        
        isCustomerRule = false
        // 尝试加载用户规则
        do {
            ruleItems = try fileRuleUtils.loadItemsFromJSON(fileName: "Rule.json") ?? []
        } catch {
            self.showAlertDialog(messags: String.localizedStringWithFormat(NSLocalizedString("Load_Customer_Rule_Failed", comment: ""), "\(error.localizedDescription)\n\(error)"))
        }
        
        // 创建提示文件，方便用户自己放进去自定义规则文件
        fileRuleUtils.createTipsFile()
        
        // 用户没有自定义规则则直接使用内置规则
        if ruleItems.isEmpty {
            ruleItems = fileRuleUtils.getDefaultRuleItems()
        } else {
            isCustomerRule = true
        }
        
        // 检查规则
        ruleItems = fileRuleUtils.checkFileExistence(for: ruleItems)
        
        // 获取URL Scheme的列表
        schemeItems = fileRuleUtils.getURLSchemeItems(for: ruleItems)
        
        // 从文件列表删除URL Scheme的item
        ruleItems = fileRuleUtils.removeURLSchemeItems(from: ruleItems)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return titleData.count
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return schemeItems.count
        case 1: return ruleItems.count
        default: return cellData[section].count
        }
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleData[section]
    }
    
    // MARK: - 设置每个分组的底部标题
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            if isCustomerRule {
                return NSLocalizedString("Use_Customer_Rule", comment: "")
            }
        } else if section == 3 {
            return NSLocalizedString("About_Footer_text", comment: "")
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        
        if indexPath.section == 0 {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            let rule = schemeItems[indexPath.row]
            
            cell.textLabel?.text = rule.path
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = rule.isLocalizedKey ? NSLocalizedString(rule.description, comment: "") : rule.description
            cell.detailTextLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            
            // 配置右侧文本
            let statusLabel = UILabel()
            statusLabel.text = rule.exists ? NSLocalizedString("Detected", comment: "") : NSLocalizedString("Not_Detected", comment: "")
            statusLabel.textColor = .systemGray
            statusLabel.font = UIFont.systemFont(ofSize: 14)
            statusLabel.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(statusLabel)

            // 布局右侧文本
            NSLayoutConstraint.activate([
                statusLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                statusLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
            
        } else if indexPath.section == 1 {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            let rule = ruleItems[indexPath.row]

            // 配置主标题和副标题
            cell.textLabel?.text = rule.path
            cell.textLabel?.numberOfLines = 0
            
            if hasRootPermission {
                
                cell.detailTextLabel?.text = String.localizedStringWithFormat(NSLocalizedString("Description_Status", comment: ""), rule.isLocalizedKey ? NSLocalizedString(rule.description, comment: "") : rule.description, rule.exists ? NSLocalizedString("Detected", comment: "") : NSLocalizedString("Not_Detected", comment: ""))
            } else {
                cell.detailTextLabel?.text = rule.isLocalizedKey ? NSLocalizedString(rule.description, comment: "") : rule.description
            }
            cell.detailTextLabel?.numberOfLines = 0

            // 配置复选框
            let checkbox = UIButton(type: .custom)
            if #available(iOS 13.0, *) {
                checkbox.setImage(UIImage(systemName: rule.isSelected ? "checkmark.circle.fill" : "circle"), for: .normal)
            } else {
                // Fallback on earlier versions
                // MARK: TODO
            }
            checkbox.addTarget(self, action: #selector(checkboxTapped(_:)), for: .touchUpInside)
            checkbox.tag = indexPath.row
            checkbox.translatesAutoresizingMaskIntoConstraints = false

            // 设置复选框尺寸
            NSLayoutConstraint.activate([
                checkbox.widthAnchor.constraint(equalToConstant: 44),
                checkbox.heightAnchor.constraint(equalToConstant: 32)
            ])

            // 包装主标题和副标题到垂直布局中
            let verticalStackView = UIStackView(arrangedSubviews: [cell.textLabel!, cell.detailTextLabel!])
            verticalStackView.axis = .vertical
            verticalStackView.spacing = 4
            verticalStackView.translatesAutoresizingMaskIntoConstraints = false

            // 创建水平布局，包含复选框和标题垂直布局
            let horizontalStackView = UIStackView(arrangedSubviews: [checkbox, verticalStackView])
            horizontalStackView.axis = .horizontal
            horizontalStackView.alignment = .center
            horizontalStackView.spacing = 8
            horizontalStackView.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(horizontalStackView)

            NSLayoutConstraint.activate([
                horizontalStackView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 10),
                horizontalStackView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
                horizontalStackView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                horizontalStackView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
            
        } else if indexPath.section == 2 { // 按钮
            cell.textLabel?.text = cellData[indexPath.section][indexPath.row]
            cell.textLabel?.textAlignment = .center
            if hasRootPermission {
                cell.textLabel?.textColor = .systemRed
                cell.selectionStyle = .default
            } else {
                cell.textLabel?.textColor = .gray
                cell.selectionStyle = .none
            }
            
        } else if indexPath.section == 3 { // 关于
            cell.textLabel?.text = cellData[indexPath.section][indexPath.row]
            if indexPath.row == 0 {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
                cell.textLabel?.text = cellData[indexPath.section][indexPath.row]
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? NSLocalizedString("Unknown_text", comment: "")
                if version != versionCode { // 判断版本号是不是有人篡改
                    cell.detailTextLabel?.text = versionCode
                } else {
                    cell.detailTextLabel?.text = version
                }
                cell.selectionStyle = .none
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default // 启用选中效果
            }
        } else {
            cell.textLabel?.text = cellData[indexPath.section][indexPath.row]
        }
        

        return cell
    }
    
    // 横向滑动cell的方法
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.section == 0 || indexPath.section == 1 {
            var rule = ruleItems[indexPath.row] // 获取当前规则项
            
            if indexPath.section == 0 {
                rule = schemeItems[indexPath.row]
            }

            let copyAction = UIContextualAction(style: .normal, title: NSLocalizedString("Copy_Path", comment: "")) { _, _, completionHandler in
                UIPasteboard.general.string = rule.path // 复制路径到剪贴板
                self.showAlertDialog(messags: NSLocalizedString("Copy_Successful", comment: ""))
                completionHandler(true)
            }
            copyAction.backgroundColor = .systemBlue // 设置操作的背景颜色

            return UISwipeActionsConfiguration(actions: [copyAction])
        }
        return nil
        
    }

    
    // CheckBox的复选事件
    @objc func checkboxTapped(_ sender: UIButton) {
        ruleItems[sender.tag].isSelected.toggle()
        tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 1)], with: .automatic)
    }

    /// 点击cell的响应
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 { // 选择规则分组
            ruleItems[indexPath.row].isSelected.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } else if indexPath.section == 2 { // 点击删除按钮
            if hasRootPermission {
                tableView.deselectRow(at: indexPath, animated: true)
                
                if fileRuleUtils.getFileItemsSelectedCount(for: ruleItems) == 0 {// 判断需要删除的文件数量不能是0个
                    self.showAlertDialog(messags: NSLocalizedString("Not_Select_File", comment: ""))
                } else {
                    let alert = UIAlertController(
                        title: NSLocalizedString("Alert_text", comment: ""),
                        message: NSLocalizedString("Delete_Files_By_Default_Rule_message", comment: ""),
                        preferredStyle: .alert
                    )
                    if isCustomerRule {
                        alert.message = NSLocalizedString("Delete_Files_By_Customer_Rule_message", comment: "")
                    }
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel_text", comment: ""), style: .cancel))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Determine_text", comment: ""), style: .default) { _ in
                        if self.fileRuleUtils.deleteItems(for: self.ruleItems) {
                            self.showAlertDialog(messags: NSLocalizedString("Delete_Successful", comment: ""))
                        } else {
                            self.showAlertDialog(messags: NSLocalizedString("Delete_Failed", comment: ""))
                        }
                        // 刷新数据
                        self.loadRuleData()
                        tableView.reloadData()
                        
                    })
                    DispatchQueue.main.async {
                        self.present(alert, animated: true)
                    }
                }
                
            }
            
        } else if indexPath.section == 3 {
            tableView.deselectRow(at: indexPath, animated: true)
            if indexPath.row == 1 {
                if let url = URL(string: "https://github.com/DevelopCubeLab/ClearFilzaResidue") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else if indexPath.row == 2 {
                if let url = URL(string: "https://havoc.app/package/reveil") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
        
    }
    
    func showAlertDialog(messags: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("Alert_text", comment: ""),
            message: messags,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss_text", comment: ""), style: .cancel))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }


}

