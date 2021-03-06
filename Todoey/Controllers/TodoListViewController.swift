//
//  ViewController.swift
//  Todoey
//
//  Created by Angela Yu on 16/11/2017.
//  Copyright © 2017 Angela Yu. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var todoItems: Results<Item>?
    let realm = try! Realm()
    
    var selectedCategory : Category? {
        didSet{
            loadItems()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))

        //title = selectedCategory?.name//navigationControllerをいじらず，titleだけを変えるならこっちの方が良い？
        
    }
    
    //画面に表示される直前
    //viewDidLoad()ではnavigationControllerは生成されておらず，navigationControllerを用いる場合，表示直前のviewWillAppear()を用いる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)//lifecycle methodではsuperで継承
        
        if let colorHex = selectedCategory?.color {

            title = selectedCategory!.name//navbarのタイトルをカテゴリ名に設定

            guard let navBar = navigationController?.navigationBar else {
                fatalError("NavigationController does not exist.")
            }

            
            if let navBarColor = UIColor(hexString: colorHex) {
                navBar.barTintColor = navBarColor
                navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)//navbarのback，buttonの色を変更
                navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColor, returnFlat: true)]//navbarのtitleのcolorを変更
                
                searchBar.barTintColor = navBarColor

            }
            searchBar.searchTextField.backgroundColor = UIColor.white//iOS13以降,searchBar.barTintColorを変えると，textFieldの色も変わってしまうので，別に設定する必要あり
            
            
        }
    }
    
    
    
    //MARK: - Tableview Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = todoItems?[indexPath.row] {
            cell.textLabel?.text = item.title
            cell.accessoryType = item.done ? .checkmark : .none
            
            let colorCategory = UIColor(hexString: selectedCategory!.color)//add new Itemsでitemを追加した時点で必ずselectedCategoryは存在するのでforce unwrappingしてもおけ
            
            //colorCategory?.darken()はcolorCategoryが存在した場合にdarken以下の処理を実行
            //optional bindingを行った場合，todoItems?.countでなく，todoItems!.countとして良い（nilでも動作が保証されるので）
            if let colorCell = colorCategory?.darken(byPercentage: CGFloat(indexPath.row)/CGFloat(todoItems!.count)) {
                cell.backgroundColor = colorCell
                cell.textLabel?.textColor = ContrastColorOf(colorCell, returnFlat: true)//backgroudcolorによって適宜textcolorを白か黒に設定
            }
                    
        } else {
            cell.textLabel?.text = "No Items Added"
        }
        
        return cell
    }
        
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let item = todoItems?[indexPath.row] {
            do {
                try realm.write {
                    //realm.delete(item)//tapした時にitemの除去
                    item.done = !item.done
                }
            } catch {
                print("Error saving done status, \(error)")
            }
        }

        tableView.reloadData()
                
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    //MARK: - Delete Data from Swipe
    override func updateModel(at indexPath: IndexPath) {
        if let item = todoItems?[indexPath.row] {
            do {
                try realm.write {
                    realm.delete(item)
                }
            } catch {
                print("Error deleting the item, \(error)")
            }
        }
    }
    
    //MARK: - Add New Items
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            //what will happen once the user clicks the Add Item button on our UIAlert
            
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm.write {
                        let newItem = Item()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                    }
                } catch {
                    print("Error saving item, \(error)")
                }
            }
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
            
        }
        
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    //MARK - Model Manupulation Methods
    func loadItems() {

        todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        
        tableView.reloadData()

    }
    
}

//MARK: - Search bar methods

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)//作成日時順でソート
        
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
          
        }
    }
}








