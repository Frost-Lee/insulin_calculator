//
//  CandidateSelectTableViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 2/7/20.
//  Copyright © 2020 李灿晨. All rights reserved.
//

import UIKit

protocol CandidateSelectDelegate {
    func candidateDidSelected(index: Int)
}

class CandidateSelectTableViewController: UITableViewController {
    
    var recognitionResult: RecognitionResult!
    var delegate: CandidateSelectDelegate?
    private var selectedIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = recognitionResult.selectedCandidateIndex
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        delegate?.candidateDidSelected(index: selectedIndex)
    }

}

extension CandidateSelectTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }
    
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return recognitionResult.candidates.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "candidateSelectTableViewCell")!
        return cell
    }
    
    override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let candidateCell = cell as! CandidateSelectTableViewCell
        candidateCell.candidate = recognitionResult.candidates[indexPath.row]
    }
    
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.cellForRow(at: IndexPath(row: selectedIndex, section: 0))?.setSelected(false, animated: true)
        tableView.cellForRow(at: indexPath)?.setSelected(true, animated: true)
        selectedIndex = indexPath.row
    }
}
