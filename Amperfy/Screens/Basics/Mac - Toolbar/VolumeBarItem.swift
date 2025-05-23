//
//  VolumeBarItem.swift
//  Amperfy
//
//  Created by David Klopp on 17.12.24.
//  Copyright (c) 2024 Maximilian Bauer. All rights reserved.
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
import Foundation
import UIKit

#if targetEnvironment(macCatalyst)

  fileprivate class VolumeSlider: UISlider {
    static var sliderHeight: CGFloat = 3.0
    static var sliderThumbHeight: CGFloat = 14.0

    private var thumbTouchSize = CGSize(width: 50, height: 20)

    override init(frame: CGRect) {
      super.init(frame: frame)
      self.preferredBehavioralStyle = .pad
      refreshSliderDesign()
      installScrollGestureRecognizer(sensitivity: 100)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    fileprivate func refreshSliderDesign() {
      let tint = UIColor.secondaryLabel
      setUnicolorMinimumTrackImage(
        trackHeight: Self.sliderHeight,
        color: tint,
        rounded: true,
        for: .normal
      )
      setUnicolorMaximumTrackImage(
        trackHeight: Self.sliderHeight,
        color: UIColor(dynamicProvider: { traitCollection in
          let isDark = traitCollection.userInterfaceStyle == .dark
          return isDark ? .systemGray2 : .systemGray4
        }),
        rounded: true,
        for: .normal
      )
      setUnicolorThumbImage(
        thumbSize: CGSize(width: Self.sliderThumbHeight, height: Self.sliderThumbHeight),
        color: .systemBackground,
        lineWidth: 1.0,
        strokeColor: UIColor(dynamicProvider: { traitCollection in
          let isDark = traitCollection.userInterfaceStyle == .dark
          return isDark ? tint : .systemGray4
        }),
        roundedCorners: .allCorners,
        for: .normal
      )
      backgroundColor = .clear
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
      refreshSliderDesign()
    }

    // MARK: - Increase touch area for thumb

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
      let increasedBounds = bounds.insetBy(dx: -thumbTouchSize.width, dy: -thumbTouchSize.height)
      let containsPoint = increasedBounds.contains(point)
      return containsPoint
    }

    // If we click inside the thumb's extended touch area, no event is registered.
    // We can fix this by always returning true here. Since this is macOS only, it
    // is fine to always start tracking.
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
      true
    }
  }

  class MacOsBarStackView: UIStackView {
    /// override this to allow snapshots: this is needed in macOS to show all tabs and create a new tab
    override func drawHierarchy(in rect: CGRect, afterScreenUpdates afterUpdates: Bool) -> Bool {
      true
    }
  }

  class VolumeBarItem: UIBarButtonItem, Refreshable {
    fileprivate let volumeSliderView = VolumeSlider()
    var player: PlayerFacade
    let minVolumeImage = UIImageView(image: UIImage.volumeMin)
    let maxVolumeImage = UIImageView(image: UIImage.volumeMax)
    let volumeIconHeightScale = 1.1
    let maxVolumeIconWidthScale = 1.55

    private lazy var detailContainer: MacOsBarStackView = {
      let container = MacOsBarStackView(arrangedSubviews: [
        self.minVolumeImage,
        self.volumeSliderView,
        self.maxVolumeImage,
      ])
      container.spacing = 4.0
      container.axis = .horizontal
      container.distribution = .fill
      container.alignment = .center
      return container
    }()

    init(player: PlayerFacade) {
      self.player = player
      super.init()

      self.title = "Volume Slider"

      let height = toolbarSafeAreaTop - 30

      detailContainer.translatesAutoresizingMaskIntoConstraints = false
      volumeSliderView.translatesAutoresizingMaskIntoConstraints = false
      minVolumeImage.translatesAutoresizingMaskIntoConstraints = false
      maxVolumeImage.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activate([
        detailContainer.widthAnchor.constraint(equalToConstant: 110),
        detailContainer.heightAnchor.constraint(equalToConstant: height),

        minVolumeImage.widthAnchor.constraint(equalToConstant: CustomBarButton.verySmallPointSize),
        minVolumeImage.heightAnchor
          .constraint(equalToConstant: CustomBarButton.verySmallPointSize * volumeIconHeightScale),

        maxVolumeImage.widthAnchor
          .constraint(
            equalToConstant: CustomBarButton
              .verySmallPointSize * maxVolumeIconWidthScale
          ),
        maxVolumeImage.heightAnchor
          .constraint(equalToConstant: CustomBarButton.verySmallPointSize * volumeIconHeightScale),

        // reduce the heigt of the slider to correctly center the slider inside the stack
        volumeSliderView.heightAnchor.constraint(equalToConstant: height),
      ])

      volumeSliderView.value = player.volume
      volumeSliderView.minimumValue = 0.0
      volumeSliderView.maximumValue = 1.0
      volumeSliderView.addTarget(self, action: #selector(volumeSliderChanged), for: .valueChanged)
      volumeSliderView.refreshSliderDesign()

      self.customView = detailContainer
    }

    @IBAction
    func volumeSliderChanged(_ sender: Any) {
      let newVolume = volumeSliderView.value
      guard newVolume >= 0.0, newVolume <= 1.0 else { return }
      player.volume = newVolume
      appDelegate.storage.settings.playerVolume = newVolume
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func reload() {
      minVolumeImage.tintColor = .secondaryLabel
      maxVolumeImage.tintColor = .secondaryLabel
      volumeSliderView.refreshSliderDesign()
      volumeSliderView.value = player.volume
    }
  }

#endif
