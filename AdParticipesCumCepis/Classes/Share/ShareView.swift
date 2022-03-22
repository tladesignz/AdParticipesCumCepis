//
//  ShareView.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 09.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI

public struct ShareView: View {

    @StateObject private var model: ShareModel

    @State private var showingBridgesConf = false

    @State private var showingImagePicker = false

    @State private var showingDocPicker = false

    @State private var heights: [CGFloat] = [100, 340]

    @State private var drawerOpen = false

    @State private var stopSharingAfterSend = true

    @State private var publicService = true

    @State private var customTitle = ""

    @State private var presentAddressShareSheet = false

    @State private var presentKeyShareSheet = false


    public var body: some View {
        GeometryReader { _ in
            if model.items.isEmpty {
                VStack(alignment: .center) {
                    if let name = model.emptyBackgroundImage {
                        Image(name)
                            .padding()
                    }

                    Text(NSLocalizedString("Nothing here yet.", comment: ""))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()

                    Button(action: {
                        showingDocPicker = true
                    }) {
                        Text(NSLocalizedString("Add Files", comment: ""))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            else {
                List {
                    ForEach(model.items) { item in
                        HStack {
                            AsyncImage(item)
                                .frame(minWidth: 64, idealWidth: 64, maxWidth: 64, maxHeight: 64)

                            Text(item.basename ?? item.id.debugDescription)
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            if let file = model.items[i] as? File {
                                try? FileManager.default.removeItem(at: file.url)
                            }
                        }

                        model.items.remove(atOffsets: offsets)
                    }
                    .deleteDisabled(model.state != .stopped)
                }

                Drawer(open: $drawerOpen, minHeight: 64, maxHeight: 400) {
                    Status(model.state, model.progress, model.error)

                    Divider()

                    if model.state == .running {
                        VStack(alignment: HorizontalAlignment.leading) {
                            Text((model.key?.isEmpty ?? true) ? model.addressLbTextNoPrivateKey : model.addressLbTextWithPrivateKey)
                                .padding(.bottom, 4)

                            HStack {
                                Text(model.address?.absoluteString ?? "")
                                    .font(.system(size: 15, design: .monospaced))

                                Button {
                                    Dimmer.shared.stop()

                                    presentAddressShareSheet = true
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                .popover(isPresented: $presentAddressShareSheet) {
                                    ShareSheet(shareItems(), restartDimmer)
                                }
                            }
                            .padding(.bottom, 8)

                            if let key = model.key, !key.isEmpty {
                                Text(NSLocalizedString("Private Key:", comment: ""))
                                    .padding(.bottom, 4)

                                HStack {
                                    Text(key)
                                        .font(.system(size: 15, design: .monospaced))

                                    Button {
                                        Dimmer.shared.stop()

                                        presentKeyShareSheet = true
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                    .popover(isPresented: $presentKeyShareSheet) {
                                        ShareSheet(shareItems(reversed: true), restartDimmer)
                                    }
                                }
                            }
                        }
                        .font(.system(size: 15))
                        .padding()
                    }
                    else {
                        VStack {
                            Toggle(model.stopSharingAfterSendLb,
                                   isOn: $stopSharingAfterSend)
                                .disabled(model.state != .stopped)
                                .padding([.leading, .trailing], 8)

                            Divider()

                            Toggle(NSLocalizedString(
                                "This is a public service (disables private key)", comment: ""),
                                   isOn: $publicService)
                                .disabled(model.state != .stopped)
                                .padding([.leading, .trailing], 8)

                            Divider()

                            TextField(NSLocalizedString("Custom title", comment: ""), text: $customTitle)
                                .disabled(model.state != .stopped)
                                .padding(8)
                        }
                        .padding(8)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .padding()
                    }

                    switch model.state {
                    case .stopped:
                        Button(action: {
                            model.start(publicService, stopSharingAfterSend, customTitle)
                        }) {
                            Text(NSLocalizedString("Start Sharing", comment: ""))
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                    case .starting:
                        Button(action: {
                            model.stop()
                        }) {
                            Text(NSLocalizedString("Starting…", comment: ""))
                                .fontWeight(.bold)
                                .font(.body.italic())
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(true)

                    case .running:
                        Button(action: {
                            model.stop()
                        }) {
                            Text(NSLocalizedString("Stop Sharing", comment: ""))
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(model.state != .stopped)
        .navigationTitle(model.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: {
                    Dimmer.shared.stop()

                    showingBridgesConf = true
                }) {
                    Image(systemName: "network.badge.shield.half.filled")
                }
                .sheet(isPresented: $showingBridgesConf) {
                    BridgesConf(restartDimmer)
                        .background(Color(.secondarySystemBackground).padding(-80))
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    Dimmer.shared.stop()

                    showingImagePicker = true
                }) {
                    Image(systemName: "photo")
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker({
                        model.items += $0
                    }, restartDimmer)
                }
                .disabled(model.state != .stopped)

                Button(action: {
                    Dimmer.shared.stop()

                    showingDocPicker = true
                }) {
                    Image(systemName: "doc")
                }
                .sheet(isPresented: $showingDocPicker) {
                    DocPicker({
                        model.items += $0
                    }, restartDimmer)
                    .padding(0)
                }
                .disabled(model.state != .stopped)
            }
        }
    }


    public init(_ model: ShareModel) {
        _model = StateObject(wrappedValue: model)

        _stopSharingAfterSend = State(wrappedValue: model.stopSharingAfterSendInitialValue)
    }


    // MARK: Private Methods

    private func shareItems(reversed: Bool = false) -> [Any] {
        var items = [Any]()

        if let url = model.address {
            items.append(url)
        }

        if let key = model.key, !key.isEmpty {
            items.append(key)
        }

        return reversed ? items.reversed() : items
    }

    /**
     User returned from a subview. Might need to start the dimmer again.
     */
    private func restartDimmer() {
        if WebServer.shared?.running ?? false {
            Dimmer.shared.start()
        }
    }
}

struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView(ShareModel())
    }
}
