//
//  String+Extension.swift
//  InteractiveAvatarDemo
//
//  Created by Hwan Moon Lee on 3/19/25.
//

import Foundation

extension String {
    var url: URL? { URL(string: self) }
}
