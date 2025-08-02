//
//  TaskEditController.swift
//  To-Do Manager
//
//  Created by Марк Фокша on 02.09.2022.
//

import UIKit

class TaskEditController: UITableViewController {

    @IBOutlet weak var taskTypeLabel: UILabel!
    @IBOutlet weak var taskTitle: UITextField!
    @IBOutlet weak var taskStatusSwitch: UISwitch!
    
    var taskText: String = ""
    var taskType: TaskPriority = .normal
    var taskStatus: TaskStatus = .planned
    
    var doAfterEdit: ((String, TaskPriority, TaskStatus) -> Void)?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskTitle.text = taskText
        taskTypeLabel.text = taskTitles[taskType]
        if taskStatus == .completed {
            taskStatusSwitch.isOn = true
        }
    }
    
    private var taskTitles: [TaskPriority: String] = [
        .normal: "Current",
        .important: "Important"
    ]
    
    @IBAction func saveTask(_ sender: UIBarButtonItem) {
        let title = taskTitle.text ?? ""
        
        if title.isEmpty || (title.first == " ") {
            let alert = UIAlertController(title: "Write your task first", message: "You didn't write anything", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(alertAction)
            present(alert, animated: true, completion: nil)
        } else {
            let type = taskType
            let status: TaskStatus = taskStatusSwitch.isOn ? .completed : .planned
            doAfterEdit?(title, type, status)
            navigationController?.popViewController(animated: true)
        }
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTaskTypeScreen" {
            let destination = segue.destination as! TaskTypeController
            destination.selectedType = taskType
            destination.doAfterTypeSelected = {[ unowned self ] selectedType in
                taskType = selectedType
                taskTypeLabel?.text = taskTitles[taskType]
            }
        }
    }

}
