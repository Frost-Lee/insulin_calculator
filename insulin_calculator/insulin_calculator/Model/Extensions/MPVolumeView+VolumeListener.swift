//
//  MPVolumeView+VolumeListener.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 11/22/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import MediaPlayer

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
