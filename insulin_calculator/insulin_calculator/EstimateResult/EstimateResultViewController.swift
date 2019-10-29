//
//  EstimateResultViewController.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/21/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import UIKit

class EstimateResultViewController: UIViewController {

    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var carbsLabel: UILabel!
    
    @IBOutlet weak var entitySelectCollectionView: UICollectionView!
    @IBOutlet weak var candidateSelectTableView: UITableView!
    
    var sessionRecognitionResult: SessionRecognitionResult?
    
    private var selectedEntityIndex: Int {
        get {
            guard entitySelectCollectionView.indexPathsForSelectedItems?.first != nil else {return -1}
            return entitySelectCollectionView.indexPathsForSelectedItems!.first!.row - 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        entitySelectCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .left)
        setRecognitionResult()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func setRecognitionResult() {
        entitySelectCollectionView.reloadData()
        candidateSelectTableView.reloadData()
        setInfoPanel()
    }
    
    private func setInfoPanel() {
        if selectedEntityIndex == -1 {
            nameLabel.text = "All Items"
            /**
             - TODO:
                Use some ways to estimate the size of all dishes, combine volume and area, the result could
                be "large size", "medium size" or some similar terms.
             */
            sizeLabel.text = "Not Available"
            weightLabel.text = sessionRecognitionResult?.results.filter({$0.weight > 0}).map({$0.weight}).reduce(0.0, +).weightString()
            carbsLabel.text = sessionRecognitionResult?.results.filter({$0.carbs > 0}).map({$0.carbs}).reduce(0.0, +).weightString()
        } else {
            let selectedEntity = sessionRecognitionResult!.results[selectedEntityIndex]
            nameLabel.text = selectedEntity.selectedCandidate.name
            if selectedEntity.selectedCandidate.areaDensity > 0 {
                sizeLabel.text = selectedEntity.area.areaString()
            } else if selectedEntity.selectedCandidate.volumeDensity > 0 {
                sizeLabel.text = selectedEntity.volume.volumeString()
            } else {
                sizeLabel.text = selectedEntity.volume.volumeString()
            }
            /**
            - TODO:
               Handle the possible negative values of weight and carbs properly here.
            */
            weightLabel.text = selectedEntity.weight.weightString()
            carbsLabel.text = selectedEntity.carbs.weightString()
        }
    }

}

extension EstimateResultViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        if selectedEntityIndex == -1 {
            return sessionRecognitionResult!.results.count
        } else {
            return sessionRecognitionResult!.results[selectedEntityIndex].candidates.count
        }
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
        let cell = cell as! CandidateTableViewCell
        if selectedEntityIndex == -1 {
            cell.candidate = sessionRecognitionResult?.results[indexPath.row].selectedCandidate
        } else {
            cell.candidate = sessionRecognitionResult?.results[selectedEntityIndex].candidates[indexPath.row]
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        if selectedEntityIndex == -1 {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        for path in tableView.indexPathsForSelectedRows! {
            if path != indexPath {
                tableView.deselectRow(at: path, animated: true)
            }
        }
        let selectedEntity = entitySelectCollectionView.indexPathsForSelectedItems!.first!.row - 1
        sessionRecognitionResult?.results[selectedEntity].selectedCandidateIndex = indexPath.row
        setInfoPanel()
    }
}

extension EstimateResultViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return sessionRecognitionResult!.results.count + 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: "entitySelectCollectionViewCell",
            for: indexPath
        )
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let cell = cell as! EntitySelectCollectionViewCell
        if indexPath.row == 0 {
            cell.indexLabel.text = "All"
        } else {
            cell.indexLabel.text = String(indexPath.row)
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        for path in collectionView.indexPathsForSelectedItems! {
            if path != indexPath {
                collectionView.deselectItem(at: indexPath, animated: true)
            }
        }
        candidateSelectTableView.reloadData()
        if selectedEntityIndex != -1 {
            candidateSelectTableView.selectRow(
                at: IndexPath(row: sessionRecognitionResult!.results[selectedEntityIndex].selectedCandidateIndex, section: 0),
                animated: false,
                scrollPosition: .none
            )
        }
        setInfoPanel()
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 100, height: 40)
    }
}
