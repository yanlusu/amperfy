//
//  GenreMO+CoreDataProperties.swift
//  AmperfyKit
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

import CoreData
import Foundation

extension GenreMO {
  @nonobjc
  public class func fetchRequest() -> NSFetchRequest<GenreMO> {
    NSFetchRequest<GenreMO>(entityName: "Genre")
  }

  @NSManaged
  public var name: String?
  @NSManaged
  public var artistCount: Int16
  @NSManaged
  public var albumCount: Int16
  @NSManaged
  public var songCount: Int16
  @NSManaged
  public var albums: NSOrderedSet?
  @NSManaged
  public var artists: NSOrderedSet?
  @NSManaged
  public var songs: NSOrderedSet?

  static let relationshipKeyPathsForPrefetching = [
    #keyPath(GenreMO.artwork),
  ]
}

// MARK: Generated accessors for albums

extension GenreMO {
  @objc(insertObject:inAlbumsAtIndex:)
  @NSManaged
  public func insertIntoAlbums(_ value: AlbumMO, at idx: Int)

  @objc(removeObjectFromAlbumsAtIndex:)
  @NSManaged
  public func removeFromAlbums(at idx: Int)

  @objc(insertAlbums:atIndexes:)
  @NSManaged
  public func insertIntoAlbums(_ values: [AlbumMO], at indexes: NSIndexSet)

  @objc(removeAlbumsAtIndexes:)
  @NSManaged
  public func removeFromAlbums(at indexes: NSIndexSet)

  @objc(replaceObjectInAlbumsAtIndex:withObject:)
  @NSManaged
  public func replaceAlbums(at idx: Int, with value: AlbumMO)

  @objc(replaceAlbumsAtIndexes:withAlbums:)
  @NSManaged
  public func replaceAlbums(at indexes: NSIndexSet, with values: [AlbumMO])

  @objc(addAlbumsObject:)
  @NSManaged
  public func addToAlbums(_ value: AlbumMO)

  @objc(removeAlbumsObject:)
  @NSManaged
  public func removeFromAlbums(_ value: AlbumMO)

  @objc(addAlbums:)
  @NSManaged
  public func addToAlbums(_ values: NSOrderedSet)

  @objc(removeAlbums:)
  @NSManaged
  public func removeFromAlbums(_ values: NSOrderedSet)
}

// MARK: Generated accessors for artists

extension GenreMO {
  @objc(insertObject:inArtistsAtIndex:)
  @NSManaged
  public func insertIntoArtists(_ value: ArtistMO, at idx: Int)

  @objc(removeObjectFromArtistsAtIndex:)
  @NSManaged
  public func removeFromArtists(at idx: Int)

  @objc(insertArtists:atIndexes:)
  @NSManaged
  public func insertIntoArtists(_ values: [ArtistMO], at indexes: NSIndexSet)

  @objc(removeArtistsAtIndexes:)
  @NSManaged
  public func removeFromArtists(at indexes: NSIndexSet)

  @objc(replaceObjectInArtistsAtIndex:withObject:)
  @NSManaged
  public func replaceArtists(at idx: Int, with value: ArtistMO)

  @objc(replaceArtistsAtIndexes:withArtists:)
  @NSManaged
  public func replaceArtists(at indexes: NSIndexSet, with values: [ArtistMO])

  @objc(addArtistsObject:)
  @NSManaged
  public func addToArtists(_ value: ArtistMO)

  @objc(removeArtistsObject:)
  @NSManaged
  public func removeFromArtists(_ value: ArtistMO)

  @objc(addArtists:)
  @NSManaged
  public func addToArtists(_ values: NSOrderedSet)

  @objc(removeArtists:)
  @NSManaged
  public func removeFromArtists(_ values: NSOrderedSet)
}

// MARK: Generated accessors for songs

extension GenreMO {
  @objc(insertObject:inSongsAtIndex:)
  @NSManaged
  public func insertIntoSongs(_ value: SongMO, at idx: Int)

  @objc(removeObjectFromSongsAtIndex:)
  @NSManaged
  public func removeFromSongs(at idx: Int)

  @objc(insertSongs:atIndexes:)
  @NSManaged
  public func insertIntoSongs(_ values: [SongMO], at indexes: NSIndexSet)

  @objc(removeSongsAtIndexes:)
  @NSManaged
  public func removeFromSongs(at indexes: NSIndexSet)

  @objc(replaceObjectInSongsAtIndex:withObject:)
  @NSManaged
  public func replaceSongs(at idx: Int, with value: SongMO)

  @objc(replaceSongsAtIndexes:withSongs:)
  @NSManaged
  public func replaceSongs(at indexes: NSIndexSet, with values: [SongMO])

  @objc(addSongsObject:)
  @NSManaged
  public func addToSongs(_ value: SongMO)

  @objc(removeSongsObject:)
  @NSManaged
  public func removeFromSongs(_ value: SongMO)

  @objc(addSongs:)
  @NSManaged
  public func addToSongs(_ values: NSOrderedSet)

  @objc(removeSongs:)
  @NSManaged
  public func removeFromSongs(_ values: NSOrderedSet)
}
