//
//  AsyncImage.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI

open class ImageLoader: ObservableObject {

    @Published
    open var image: UIImage?

    public init(_ item: Item) {
        item.getThumbnail { image, info in
            self.image = image
        }
    }
}

public struct AsyncImage: View {

    @StateObject public var loader: ImageLoader

    public let placeholder: String

    public init(_ item: Item) {
        _loader = StateObject(wrappedValue: ImageLoader(item))

        if item.isDir {
            placeholder = "folder"
        }
        else if item is Asset {
            placeholder = "photo.on.rectangle.angled"
        }
        else {
            placeholder = "doc"
        }
    }

    public var body: some View {
        let image: Image

        if let uiImage = loader.image {
            image = Image(uiImage: uiImage)
        }
        else {
            image = Image(systemName: placeholder)
        }

        return image
            .resizable()
            .scaledToFit()
    }
}
