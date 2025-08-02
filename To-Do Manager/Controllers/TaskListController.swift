//
//  TaskListController.swift
//  To-Do Manager
//
//  Created by Марк Фокша on 01.09.2022.
//

import UIKit

class TaskListController: UITableViewController {

    var tasksStorage: TasksStorageProtocol = TasksStorage()
    var tasks: [TaskPriority: [TaskProtocol]] = [:] {
        didSet {
            for (tasksGroupPriority, tasksGroup) in tasks {
                tasks[tasksGroupPriority] = tasksGroup.sorted(by: { task1, task2 in
                    let task1Position = taskStatusPosition.firstIndex(of: task1.status) ?? 0
                    let task2Position = taskStatusPosition.firstIndex(of: task2.status) ?? 0
                    return task1Position < task2Position
                })
            }
            
            var savingArray: [TaskProtocol] = []
            tasks.forEach { _, value in
                savingArray += value
            }
            tasksStorage.saveTasks(savingArray)
        }
    }
    
    var sectionsTypePosition: [TaskPriority] = [.important, .normal]
    var taskStatusPosition: [TaskStatus] = [.planned, .completed]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    func setTasks(_ tasksCollection: [TaskProtocol]) {
        sectionsTypePosition.forEach { taskType in
            tasks[taskType] = []
        }
        tasksCollection.forEach { task in
            tasks[task.type]?.append(task)
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let taskType = sectionsTypePosition[section]
        guard let currentTasksType = tasks[taskType] else { return 0 }
        return currentTasksType.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //return getConfiguredTaskCell_constraints(for: indexPath)
        return getConfiguredTaskCell_stack(for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let taskType = sectionsTypePosition[indexPath.section]
        tasks[taskType]?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let taskTypeFrom = sectionsTypePosition[sourceIndexPath.section]
        let taskTypeTo = sectionsTypePosition[destinationIndexPath.section]
        
        guard let movedTask = tasks[taskTypeFrom]?[sourceIndexPath.row] else { return }
        tasks[taskTypeFrom]!.remove(at: sourceIndexPath.row)
        tasks[taskTypeTo]!.insert(movedTask, at: destinationIndexPath.row)
        
        if taskTypeFrom != taskTypeTo {
            tasks[taskTypeTo]![destinationIndexPath.row].type = taskTypeTo
        }
        tableView.reloadData()
    }
    
    //MARK: - Constraints prototype
    private func getConfiguredTaskCell_constraints(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCelConstraints", for: indexPath)
        let taskType = sectionsTypePosition[indexPath.section]
        guard let currentTask = tasks[taskType]?[indexPath.row] else { return cell }
        
        let symbolLabel = cell.viewWithTag(1) as? UILabel
        let titleLabel = cell.viewWithTag(2) as? UILabel
        
        symbolLabel?.text = getSymbolForTask(with: currentTask.status)
        titleLabel?.text = currentTask.title
        
        if currentTask.status == .planned {
            symbolLabel?.textColor = .black
            titleLabel?.textColor = .black
        } else {
            symbolLabel?.textColor = .lightGray
            titleLabel?.textColor = .lightGray
        }
        return cell
    }
    
    private func getSymbolForTask(with status: TaskStatus) -> String {
        var resultSymbol: String
        if status == .planned {
            resultSymbol = "\u{25CB}"
        } else if status == .completed {
            resultSymbol = "\u{25C9}"
        } else {
            resultSymbol = ""
        }
        return resultSymbol
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        let typeTask = sectionsTypePosition[section]
        if typeTask == .important {
            title = "Important"
        } else {
            title = "Current"
        }
        return title
    }

    //MARK: - Horizontal stack prototype
    private func getConfiguredTaskCell_stack(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCellStack", for: indexPath) as! TaskCell
        let taskType = sectionsTypePosition[indexPath.section]
        guard let currentTask = tasks[taskType]?[indexPath.row] else { return cell }
        
        cell.title.text = currentTask.title
        cell.symbol.text = getSymbolForTask(with: currentTask.status)
        
        if currentTask.status == .planned {
            cell.title.textColor = .black
            cell.symbol.textColor = .black
        } else {
            cell.title.textColor = .lightGray
            cell.symbol.textColor = .lightGray
        }
        return cell
    }
    
    //MARK: - Delegate methods
    
    //MARK: Touch to be set completed
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let typeTask = sectionsTypePosition[indexPath.section]
        guard let _ = tasks[typeTask]?[indexPath.row] else { return }
        guard tasks[typeTask]![indexPath.row].status == .planned else {
            return tableView.deselectRow(at: indexPath, animated: true)
        }
        tasks[typeTask]![indexPath.row].status = .completed
        tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
    }
    
    //MARK: Swipe right to set planned again
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let typeTask = sectionsTypePosition[indexPath.section]
        guard let _ = tasks[typeTask]?[indexPath.row] else { return nil }
        
        let actionSwipe = UIContextualAction(style: .normal, title: "Not completed") { _, _, _ in
            self.tasks[typeTask]![indexPath.row].status = .planned
            self.tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
        }
        
        let actionEdit = UIContextualAction(style: .normal, title: "Edit") { _, _, _ in
            let editScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TaskEditController") as! TaskEditController
            
            editScreen.taskText = self.tasks[typeTask]![indexPath.row].title
            editScreen.taskType = self.tasks[typeTask]![indexPath.row].type
            editScreen.taskStatus = self.tasks[typeTask]![indexPath.row].status
            
            editScreen.doAfterEdit = { [ unowned self ] title, type, status in
                let editedTask = Task(title: title, type: type, status: status)
                tasks[typeTask]![indexPath.row] = editedTask
                tableView.reloadData()
            }
            self.navigationController?.pushViewController(editScreen, animated: true)
        }
        
        actionEdit.backgroundColor = .darkGray
        let actionsConfiguration: UISwipeActionsConfiguration
        
        if tasks[typeTask]![indexPath.row].status == .planned {
            actionsConfiguration = UISwipeActionsConfiguration(actions: [actionEdit])
        } else {
            actionsConfiguration = UISwipeActionsConfiguration(actions: [actionSwipe, actionEdit])
        }
        return actionsConfiguration
    }
    
    //MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCreateScreen" {
            let destination = segue.destination as! TaskEditController
            destination.doAfterEdit = { [ unowned self ] title, type, status in
                let newTask = Task(title: title, type: type, status: status)
                tasks[type]?.append(newTask)
                tableView.reloadData()
            }
        }
    }
    

}
