//
//  EstimateResultViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/21/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit
import SVProgressHUD
import SwiftyJSON

class EstimateResultViewController: UIViewController {
    
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var carbsLabel: UILabel!
    
    @IBOutlet weak var boundingBoxView: BoundingBoxView!
    @IBOutlet weak var resultsTableView: UITableView!
    
    /// The primary data content of the view. Passed from `EstimateImageCaptureViewController`.
    var sessionRecord: SessionRecord?
    /// The derived data from `sessionRecord`.
    private var sessionRecognitionResult: SessionRecognitionResult?
    
    private var modifyingResultIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setRecognitionResult()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.identifier {
        case "showCandidateSelectTableViewController":
            let destination = segue.destination as! CandidateSelectTableViewController
            destination.recognitionResult = sender as? RecognitionResult
            destination.delegate = self
        default:
            break
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func setRecognitionResult() {
        do {
            sessionRecognitionResult = try SessionRecognitionResult(
                json: try JSON(
                    data: try Data(
                        contentsOf: sessionRecord!.recognitionJSONURL
                    )
                ),
                selectedCandidateIndices: sessionRecord?.selectedCandidateIndices
            )
            capturedImageView.image = UIImage(data: try Data(contentsOf: sessionRecord!.photoURL))
        } catch {
            SVProgressHUD.showError(withStatus: "Data Storage Error")
            dismiss(animated: true, completion: nil)
        }
        resultsTableView.reloadData()
        sizeLabel.text = sessionRecognitionResult?.results.reduce(0.0, {$0 + $1.volume}).volumeString()
        weightLabel.text = sessionRecognitionResult?.results.filter({$0.weight > 0}).reduce(0.0, {$0 + $1.weight}).weightString()
        carbsLabel.text = sessionRecognitionResult?.results.filter({$0.carbs > 0}).reduce(0.0, {$0 + $1.carbs}).weightString()
        boundingBoxView.boundingBoxes = sessionRecognitionResult?.results.map({$0.boundingBox})
    }

}

extension EstimateResultViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return sessionRecognitionResult!.results.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "candidateTableViewCell",
            for: indexPath
        )
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        let cell = cell as! RecognitionResultTableViewCell
        cell.recognitionResult = sessionRecognitionResult?.results[indexPath.row]
        cell.cellIndex = indexPath.row
    }
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        modifyingResultIndex = indexPath.row
        performSegue(
            withIdentifier: "showCandidateSelectTableViewController",
            sender: sessionRecognitionResult?.results[indexPath.row]
        )
    }
}

extension EstimateResultViewController: CandidateSelectDelegate {
    func candidateDidSelected(index: Int) {
        sessionRecord?.selectedCandidateIndices[modifyingResultIndex!] = index
        modifyingResultIndex = nil
        setRecognitionResult()
    }
}
