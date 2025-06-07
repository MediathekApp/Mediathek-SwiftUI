//
//  ItemPlayUIKit.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

#if os(iOS)
import UIKit

func ItemPlayUIKit(_ item: Item, _ url: URL) {
    DispatchQueue.main.async {
        UIApplication.shared.open(
            url,
            options: [:],
            completionHandler: nil
        )
    }
}
    
#endif
