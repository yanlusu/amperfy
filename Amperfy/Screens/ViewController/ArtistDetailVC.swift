//
//  ArtistDetailVC.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 09.03.19.
//  Copyright (c) 2019 Maximilian Bauer. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import AmperfyKit
import CoreData
import UIKit

class ArtistDetailVC: MultiSourceTableViewController {
  override var sceneTitle: String? { artist.name }

  var artist: Artist!
  var albumToScrollTo: Album?
  private var albumsFetchedResultsController: ArtistAlbumsItemsFetchedResultsController!
  private var songsFetchedResultsController: ArtistSongsItemsFetchedResultsController!
  private var optionsButton: UIBarButtonItem!
  private var detailOperationsView: GenericDetailTableHeader?

  override func viewDidLoad() {
    super.viewDidLoad()
    appDelegate.userStatistics.visited(.artistDetail)

    optionsButton = OptionsBarButton()

    albumsFetchedResultsController = ArtistAlbumsItemsFetchedResultsController(
      for: artist,
      coreDataCompanion: appDelegate.storage.main,
      isGroupedInAlphabeticSections: false
    )
    albumsFetchedResultsController.delegate = self
    songsFetchedResultsController = ArtistSongsItemsFetchedResultsController(
      for: artist,
      displayFilter: appDelegate.storage.settings.artistsFilterSetting,
      coreDataCompanion: appDelegate.storage.main,
      isGroupedInAlphabeticSections: false
    )
    songsFetchedResultsController.delegate = self
    tableView.register(nibName: GenericTableCell.typeName)
    tableView.register(nibName: PlayableTableCell.typeName)

    configureSearchController(placeholder: "Albums and Songs", scopeButtonTitles: ["All", "Cached"])
    let playShuffleInfoConfig = PlayShuffleInfoConfiguration(
      infoCB: {
        "\(self.artist.albumCount) Album\(self.artist.albumCount == 1 ? "" : "s") \(CommonString.oneMiddleDot) \(self.artist.songCount) Song\(self.artist.songCount == 1 ? "" : "s")"
      },
      playContextCb: { () in
        let songs = self.songsFetchedResultsController
          .getContextSongs(onlyCachedSongs: self.appDelegate.storage.settings.isOfflineMode) ?? []
        let sortedSongs = songs.filterSongs().sortByAlbum()
        return PlayContext(containable: self.artist, playables: sortedSongs)
      },
      player: appDelegate.player,
      isInfoAlwaysHidden: true
    )
    let detailHeaderConfig = DetailHeaderConfiguration(
      entityContainer: artist,
      rootView: self,
      tableView: tableView,
      playShuffleInfoConfig: playShuffleInfoConfig
    )
    detailOperationsView = GenericDetailTableHeader
      .createTableHeader(configuration: detailHeaderConfig)

    optionsButton.menu = UIMenu.lazyMenu(deferredMenuMightBeBroken: true) {
      EntityPreviewActionBuilder(container: self.artist, on: self).createMenu()
    }
    navigationItem.rightBarButtonItem = optionsButton

    containableAtIndexPathCallback = { indexPath in
      switch indexPath.section + 2 {
      case LibraryElement.Album.rawValue:
        return self.albumsFetchedResultsController.getWrappedEntity(at: IndexPath(
          row: indexPath.row,
          section: 0
        ))
      case LibraryElement.Song.rawValue:
        return self.songsFetchedResultsController.getWrappedEntity(at: IndexPath(
          row: indexPath.row,
          section: 0
        ))
      default:
        return nil
      }
    }
    playContextAtIndexPathCallback = { indexPath in
      switch indexPath.section + 2 {
      case LibraryElement.Album.rawValue:
        let album = self.albumsFetchedResultsController.getWrappedEntity(at: IndexPath(
          row: indexPath.row,
          section: 0
        ))
        Task { @MainActor in do {
          try await album.fetch(
            storage: self.appDelegate.storage,
            librarySyncer: self.appDelegate.librarySyncer,
            playableDownloadManager: self.appDelegate.playableDownloadManager
          )
        } catch {
          self.appDelegate.eventLogger.report(topic: "Album Sync", error: error)
        }}
        return PlayContext(containable: album)
      case LibraryElement.Song.rawValue:
        let songIndexPath = IndexPath(row: indexPath.row, section: 0)
        return self.convertIndexPathToPlayContext(songIndexPath: songIndexPath)
      default:
        return nil
      }
    }
    swipeCallback = { indexPath, completionHandler in
      switch indexPath.section + 2 {
      case LibraryElement.Album.rawValue:
        let album = self.albumsFetchedResultsController.getWrappedEntity(at: IndexPath(
          row: indexPath.row,
          section: 0
        ))
        Task { @MainActor in
          do {
            try await album.fetch(
              storage: self.appDelegate.storage,
              librarySyncer: self.appDelegate.librarySyncer,
              playableDownloadManager: self.appDelegate.playableDownloadManager
            )
          } catch {
            self.appDelegate.eventLogger.report(topic: "Album Sync", error: error)
          }
          completionHandler(SwipeActionContext(containable: album))
        }
      case LibraryElement.Song.rawValue:
        let songIndexPath = IndexPath(row: indexPath.row, section: 0)
        let song = self.songsFetchedResultsController.getWrappedEntity(at: songIndexPath)
        let playContext = self.convertIndexPathToPlayContext(songIndexPath: songIndexPath)
        completionHandler(SwipeActionContext(containable: song, playContext: playContext))
      default:
        completionHandler(nil)
      }
    }
  }

  override func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    albumsFetchedResultsController?.delegate = self
    songsFetchedResultsController?.delegate = self
    Task { @MainActor in
      do {
        try await artist.fetch(
          storage: self.appDelegate.storage,
          librarySyncer: self.appDelegate.librarySyncer,
          playableDownloadManager: self.appDelegate.playableDownloadManager
        )
      } catch {
        self.appDelegate.eventLogger.report(topic: "Artist Sync", error: error)
      }
      self.detailOperationsView?.refresh()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    albumsFetchedResultsController?.delegate = nil
    songsFetchedResultsController?.delegate = nil
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    defer { albumToScrollTo = nil }
    guard let albumToScrollTo = albumToScrollTo,
          let indexPath = albumsFetchedResultsController.fetchResultsController
          .indexPath(forObject: albumToScrollTo.managedObject)
    else { return }
    let adjustedIndexPath = IndexPath(row: indexPath.row, section: 0)
    tableView.scrollToRow(at: adjustedIndexPath, at: .top, animated: true)
  }

  func convertIndexPathToPlayContext(songIndexPath: IndexPath) -> PlayContext? {
    guard let songs = songsFetchedResultsController
      .getContextSongs(onlyCachedSongs: appDelegate.storage.settings.isOfflineMode)
    else { return nil }
    let selectedSong = songsFetchedResultsController.getWrappedEntity(at: songIndexPath)
    guard let playContextIndex = songs.firstIndex(of: selectedSong) else { return nil }
    return PlayContext(containable: artist, index: playContextIndex, playables: songs)
  }

  func convertCellViewToPlayContext(cell: UITableViewCell) -> PlayContext? {
    guard let indexPath = tableView.indexPath(for: cell),
          indexPath.section + 2 == LibraryElement.Song.rawValue
    else { return nil }
    return convertIndexPathToPlayContext(songIndexPath: IndexPath(row: indexPath.row, section: 0))
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  override func tableView(
    _ tableView: UITableView,
    titleForHeaderInSection section: Int
  )
    -> String? {
    switch section + 2 {
    case LibraryElement.Album.rawValue:
      return "Albums"
    case LibraryElement.Song.rawValue:
      return "Songs"
    default:
      return ""
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section + 2 {
    case LibraryElement.Album.rawValue:
      return albumsFetchedResultsController.sections?[0].numberOfObjects ?? 0
    case LibraryElement.Song.rawValue:
      return songsFetchedResultsController.sections?[0].numberOfObjects ?? 0
    default:
      return 0
    }
  }

  override func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  )
    -> UITableViewCell {
    switch indexPath.section + 2 {
    case LibraryElement.Album.rawValue:
      let cell: GenericTableCell = dequeueCell(for: tableView, at: indexPath)
      let album = albumsFetchedResultsController.getWrappedEntity(at: IndexPath(
        row: indexPath.row,
        section: 0
      ))
      cell.display(container: album, rootView: self)
      return cell
    case LibraryElement.Song.rawValue:
      let cell: PlayableTableCell = dequeueCell(for: tableView, at: indexPath)
      let song = songsFetchedResultsController.getWrappedEntity(at: IndexPath(
        row: indexPath.row,
        section: 0
      ))
      cell.display(playable: song, playContextCb: convertCellViewToPlayContext, rootView: self)
      return cell
    default:
      return UITableViewCell()
    }
  }

  override func tableView(
    _ tableView: UITableView,
    heightForHeaderInSection section: Int
  )
    -> CGFloat {
    switch section + 2 {
    case LibraryElement.Album.rawValue:
      return albumsFetchedResultsController.sections?[0]
        .numberOfObjects ?? 0 > 0 ? CommonScreenOperations.tableSectionHeightLarge : 0
    case LibraryElement.Song.rawValue:
      return songsFetchedResultsController.sections?[0]
        .numberOfObjects ?? 0 > 0 ? CommonScreenOperations.tableSectionHeightLarge : 0
    default:
      return 0.0
    }
  }

  override func tableView(
    _ tableView: UITableView,
    heightForRowAt indexPath: IndexPath
  )
    -> CGFloat {
    switch indexPath.section + 2 {
    case LibraryElement.Album.rawValue:
      return GenericTableCell.rowHeight
    case LibraryElement.Song.rawValue:
      return PlayableTableCell.rowHeight
    default:
      return 0.0
    }
  }

  override func tableView(
    _ tableView: UITableView,
    estimatedHeightForRowAt indexPath: IndexPath
  )
    -> CGFloat {
    switch indexPath.section + 2 {
    case LibraryElement.Album.rawValue:
      return GenericTableCell.rowHeight
    case LibraryElement.Song.rawValue:
      return PlayableTableCell.rowHeight
    default:
      return 0.0
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section + 2 {
    case LibraryElement.Album.rawValue:
      let album = albumsFetchedResultsController.getWrappedEntity(at: IndexPath(
        row: indexPath.row,
        section: 0
      ))
      performSegue(withIdentifier: Segues.toAlbumDetail.rawValue, sender: album)
    case LibraryElement.Song.rawValue: break
    default: break
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.toAlbumDetail.rawValue {
      let vc = segue.destination as! AlbumDetailVC
      let album = sender as? Album
      vc.album = album
    }
  }

  override func updateSearchResults(for searchController: UISearchController) {
    guard let searchText = searchController.searchBar.text else { return }
    if !searchText.isEmpty, searchController.searchBar.selectedScopeButtonIndex == 0 {
      albumsFetchedResultsController.search(searchText: searchText, onlyCached: false)
      songsFetchedResultsController.search(searchText: searchText, onlyCachedSongs: false)
    } else if searchController.searchBar.selectedScopeButtonIndex == 1 {
      albumsFetchedResultsController.search(searchText: searchText, onlyCached: true)
      songsFetchedResultsController.search(searchText: searchText, onlyCachedSongs: true)
    } else {
      albumsFetchedResultsController.showAllResults()
      songsFetchedResultsController.showAllResults()
    }
    tableView.reloadData()
  }

  override func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    didChange anObject: Any,
    at indexPath: IndexPath?,
    for type: NSFetchedResultsChangeType,
    newIndexPath: IndexPath?
  ) {
    var section = 0
    switch controller {
    case albumsFetchedResultsController.fetchResultsController:
      section = LibraryElement.Album.rawValue - 2
    case songsFetchedResultsController.fetchResultsController:
      section = LibraryElement.Song.rawValue - 2
    default:
      return
    }

    resultUpdateHandler?.applyChangesOfMultiRowType(
      controller,
      didChange: anObject,
      determinedSection: section,
      at: indexPath,
      for: type,
      newIndexPath: newIndexPath
    )
  }

  override func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    didChange sectionInfo: NSFetchedResultsSectionInfo,
    atSectionIndex sectionIndex: Int,
    for type: NSFetchedResultsChangeType
  ) {}
}
