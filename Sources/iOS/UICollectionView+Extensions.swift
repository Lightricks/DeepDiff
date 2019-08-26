//
//  UICollectionView+Extensions.swift
//  DeepDiff
//
//  Created by Khoa Pham.
//  Copyright © 2018 Khoa Pham. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit

public extension UICollectionView {
  
  /// Animate reload in a batch update
  ///
  /// - Parameters:
  ///   - changes: The changes from diff
  ///   - section: The section that all calculated IndexPath belong
  ///   - updateData: Update your data source model
  ///   - completion: Called when operation completes
  func reload<T: DiffAware>(
    changes: [Change<T>],
    section: Int = 0,
    updateData: () -> Void,
    completion: ((Bool) -> Void)? = nil) {
    
    let changesWithIndexPath = IndexPathConverter().convert(changes: changes, section: section)
    
    performBatchUpdates({
      updateData()
      insideUpdate(changesWithIndexPath: changesWithIndexPath)
    }, completion: { finished in
      completion?(finished)
    })

    // reloadRows needs to be called outside the batch
    outsideUpdate(changesWithIndexPath: changesWithIndexPath)
  }
  
  /// Animate reload sections in a batch update
  ///
  /// - Parameters:
  ///   - changes: The changes from diff
  ///   - updateData: Update your data source model
  ///   - completion: Called when operation completes
  func reloadSections<T: DiffAware>(
    changes: [Change<T>],
    updateData: () -> Void,
    completion: ((Bool) -> Void)? = nil) {
    
    performBatchUpdates({
      updateData()
      insideUpdateSection(changes: changes)
    }, completion: { finished in
      completion?(finished)
    })
    
    // reloadRows needs to be called outside the batch
    outsideUpdateSection(changes: changes)
  }
  
  // MARK: - Helper
  
  private func insideUpdate(changesWithIndexPath: ChangeWithIndexPath) {
    changesWithIndexPath.deletes.executeIfPresent {
      deleteItems(at: $0)
    }
    
    changesWithIndexPath.inserts.executeIfPresent {
      insertItems(at: $0)
    }
    
    changesWithIndexPath.moves.executeIfPresent {
      $0.forEach { move in
        moveItem(at: move.from, to: move.to)
      }
    }
  }

  private func insideUpdateSection<T>(changes: [Change<T>]) {
    
    let deleteIndices = IndexSet(changes.compactMap { $0.delete?.index } )
    self.deleteSections(deleteIndices)
    
    let insertIndices = IndexSet(changes.compactMap({ $0.insert?.index }))
    self.insertSections(insertIndices)
    
    let moveIndexPaths = changes.filter { $0.move != nil }.map { (fromIndex: $0.move!.fromIndex, toIndex: $0.move!.toIndex) }
    moveIndexPaths.forEach { move in
      self.moveSection(move.fromIndex, toSection: move.toIndex)
    }
  }
  
  private func outsideUpdate(changesWithIndexPath: ChangeWithIndexPath) {
    changesWithIndexPath.replaces.executeIfPresent {
      self.reloadItems(at: $0)
    }
  }
  
  private func outsideUpdateSection<T>(changes: [Change<T>]) {
    let replaceIndices = IndexSet(changes.compactMap { $0.replace?.index })
    self.reloadSections(replaceIndices)
  }
}
#endif
