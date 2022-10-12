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

    @State private var showingFolderPicker = false

    @State private var heights: [CGFloat] = [100, 340]

    @State private var drawerOpen = false

    @State private var stopSharingAfterSend = true

    @State private var publicService = true

    @State private var customTitle = ""

    @State private var presentAddressShareSheet = false

    @State private var presentKeyShareSheet = false


    public var body: some View {
        GeometryReader { geometry in
            if model.items.isEmpty {
                VStack {
                    VStack(alignment: .center) {
                        if let name = model.emptyBackgroundImage {
                            let size = min(geometry.size.width, geometry.size.height) * 0.7

                            Image(name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: size, height: size, alignment: .center)
                        }

                        Text(NSLocalizedString("Nothing here yet.", comment: ""))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(8)

                        Button {
                            showingImagePicker = true
                        } label: {
                            Text(NSLocalizedString("Add Photos", comment: ""))
                                .frame(maxWidth: .infinity)
                                .padding(8)
                        }

                        Button {
                            showingDocPicker = true
                        } label: {
                            Text(NSLocalizedString("Add Files", comment: ""))
                                .frame(maxWidth: .infinity)
                                .padding(8)
                        }

                        Button {
                            showingFolderPicker = true
                        } label: {
                            Text(NSLocalizedString("Add Folder", comment: ""))
                                .frame(maxWidth: .infinity)
                                .padding(8)
                        }
                    }
                }
                .frame(height: geometry.size.height, alignment: .center)
                .offset(x: 0, y: -40)
            }
            else {
                List {
                    ForEach(model.items) { item in
                        HStack {
                            AsyncImage(item)
                                .frame(minWidth: 48, idealWidth: 48, maxWidth: 48, maxHeight: 48)

                            VStack(alignment: .leading) {
                                Text(item.basename ?? item.id.debugDescription)

                                Text([Formatter.format(item.lastModified), item.sizeHuman]
                                    .compactMap({ $0 })
                                    .joined(separator: " – "))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            try? model.items[i].remove()
                        }

                        model.items.remove(atOffsets: offsets)
                    }
                    .deleteDisabled(model.state != .stopped)
                }
                .frame(maxHeight: max(0, geometry.size.height - 116))

                Text([
                    String.localizedStringWithFormat(NSLocalizedString("%u item(s)", comment: "#bc-ignore!"), model.items.count),
                    Formatter.format(filesize: model.items.reduce(0, { $0 + ($1.size ?? 0) }))]
                    .compactMap({ $0 }).joined(separator: ", "))
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .offset(y: geometry.size.height - 116)

                Drawer(open: $drawerOpen, minHeight: 64) {
                    Status(model.state, model.progress, model.error, model.runningText)

                    if model.state == .running {
                        VStack(alignment: .leading) {
                            Text((model.key?.isEmpty ?? true) ? model.addressLbTextNoPrivateText : model.addressLbTextWithPrivateText)
                                .padding(.bottom, 4)

                            HStack {
                                Text(model.address?.absoluteString ?? "")
                                    .font(.system(size: 15, design: .monospaced))

                                Button {
                                    Dimmer.shared.stop()

                                    presentAddressShareSheet = true
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .frame(width: 48, height: 48)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Circle())
                                }
                                .popover(isPresented: $presentAddressShareSheet) {
                                    ShareSheet(shareItems(), restartDimmer)
                                }
                            }
                            .padding(.bottom, 8)

                            if let key = model.key, !key.isEmpty {
                                Text(NSLocalizedString("Private Key", comment: ""))
                                    .fontWeight(.bold)
                                    .padding(.bottom, 4)

                                HStack {
                                    Text(key)
                                        .font(.system(size: 15, design: .monospaced))

                                    Button {
                                        Dimmer.shared.stop()

                                        presentKeyShareSheet = true
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .frame(width: 48, height: 48)
                                            .background(Color(.secondarySystemBackground))
                                            .clipShape(Circle())
                                    }
                                    .popover(isPresented: $presentKeyShareSheet) {
                                        ShareSheet(shareItems(reversed: true), restartDimmer)
                                    }
                                }
                            }
                        }
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    else {
                        VStack {
                            Toggle(model.stopSharingAfterSendText,
                                   isOn: $stopSharingAfterSend)
                                .disabled(model.state != .stopped)

                            Divider()

                            Toggle(NSLocalizedString(
                                "This is a public service (disables private key)", comment: ""),
                                   isOn: $publicService)
                                .disabled(model.state != .stopped)

                            Divider()

                            TextField(NSLocalizedString("Custom title", comment: ""), text: $customTitle)
                                .disabled(model.state != .stopped)
                                .padding([.top, .bottom], 8)
                        }
                        .padding()
                    }

                    switch model.state {
                    case .stopped:
                        Button {
                            model.start(publicService, stopSharingAfterSend, customTitle)
                        } label: {
                            Text(model.startButtonText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding([.leading, .trailing])

                    case .starting:
                        Button {
                            model.stop()
                        } label: {
                            Text(NSLocalizedString("Starting…", comment: ""))
                                .font(.body.italic())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding([.leading, .trailing])
                        .disabled(true)

                    case .running:
                        Button {
                            model.stop()
                        } label: {
                            Text(model.stopButtonText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        }
                        .padding([.leading, .trailing])
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(model.state != .stopped)
        .navigationTitle(model.titleText)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Section {
                        Button {
                            Dimmer.shared.stop()

                            showingImagePicker = true
                        } label: {
                            Label(NSLocalizedString("Add Photos", comment: ""), systemImage: "photo")
                        }
                        .disabled(model.state != .stopped)

                        Button {
                            Dimmer.shared.stop()

                            showingDocPicker = true
                        } label: {
                            Label(NSLocalizedString("Add Files", comment: ""), systemImage: "doc.badge.plus")
                        }
                        .disabled(model.state != .stopped)

                        Button {
                            Dimmer.shared.stop()

                            showingFolderPicker = true
                        } label: {
                            Label(NSLocalizedString("Add Folder", comment: ""), systemImage: "folder.badge.plus")
                        }
                        .disabled(model.state != .stopped)
                    }

                    Section {
                        Button {
                            Dimmer.shared.stop()

                            showingBridgesConf = true
                        } label: {
                            Label(NSLocalizedString("Use Bridges", comment: ""), systemImage: "network.badge.shield.half.filled")
                        }
                    }
                }
                label: {
                    Label(NSLocalizedString("Menu", comment: ""), systemImage: "ellipsis.circle")
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker({
                        model.items += $0
                    }, restartDimmer)
                }
                .sheet(isPresented: $showingDocPicker) {
                    DocPicker(type: .item, {
                        model.items += $0
                    }, restartDimmer)
                    .padding(0)
                }
                .sheet(isPresented: $showingFolderPicker) {
                    DocPicker(type: .folder, {
                        if $0.count == 1 {
                            model.items += $0[0].children()
                        }
                        else {
                            model.items += $0
                        }
                    }, restartDimmer)
                    .padding(0)
                }
                .sheet(isPresented: $showingBridgesConf) {
                    BridgesConf(restartDimmer)
                        .background(Color(.secondarySystemBackground).padding(-80))
                }
                .alert(isPresented: $model.changedWhileRunning) {
                    Alert(
                        title: Text(NSLocalizedString("New files while running", comment: "")),
                        message: Text(
                            NSLocalizedString("You added files from elsewhere while already sharing.", comment: "")
                            + "\n\n"
                            + NSLocalizedString("Please note, that this will only take effect, after you restart.", comment: "")),
                        dismissButton: .default(Text(NSLocalizedString("OK", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!")), action: {
                            model.changedWhileRunning = false
                        }))
                }
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
