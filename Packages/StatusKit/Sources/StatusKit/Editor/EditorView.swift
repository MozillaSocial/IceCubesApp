import AppAccount
import DesignSystem
import Env
import Models
import Network
import SwiftUI

extension StatusEditor {
  @MainActor
  struct EditorView: View {
    @Environment(Theme.self) private var theme
    @Environment(UserPreferences.self) private var preferences
    @Environment(CurrentAccount.self) private var currentAccount
    @Environment(CurrentInstance.self) private var currentInstance
    @Environment(AppAccountsManager.self) private var appAccounts
    @Environment(Client.self) private var client
    #if targetEnvironment(macCatalyst)
      @Environment(\.dismissWindow) private var dismissWindow
    #else
      @Environment(\.dismiss) private var dismiss
    #endif
    
    @Bindable var viewModel: ViewModel
    @Binding var followUpSEVMs: [ViewModel]
    @Binding var editingMediaContainer: MediaContainer?

    @State private var isPhotosPickerPresented: Bool = false
    @State private var isFileImporterPresented: Bool = false
    @State private var isCameraPickerPresented: Bool = false
    @State private var isGIFPickerPresented: Bool = false

    @FocusState<UUID?>.Binding var isSpoilerTextFocused: UUID?
    @FocusState<EditorFocusState?>.Binding var editorFocusState: EditorFocusState?
    let assignedFocusState: EditorFocusState
    let isMain: Bool

    var body: some View {
      HStack(spacing: 0) {
        if !isMain {
          Rectangle()
            .fill(theme.tintColor)
            .frame(width: 2)
            .accessibilityHidden(true)
            .padding(.leading, .layoutPadding)
        }

        VStack(spacing: 0) {
          spoilerTextView
          VStack(spacing: 0) {
            accountHeaderView
            textInput
            pollView
            characterCountAndLangView
            MediaView(viewModel: viewModel, editingMediaContainer: $editingMediaContainer)
            embeddedStatus
          }
          .padding(.vertical)

          Divider()
        }
      }
      #if !os(visionOS)
      .background(theme.primaryBackgroundColor)
      #endif
      .focused($editorFocusState, equals: assignedFocusState)
      .onAppear { setupViewModel() }
    }

    @ViewBuilder
    private var spoilerTextView: some View {
      if viewModel.spoilerOn {
        TextField("status.editor.spoiler", text: $viewModel.spoilerText)
          .focused($isSpoilerTextFocused, equals: viewModel.id)
          .padding(.horizontal, .layoutPadding)
          .padding(.vertical)
          .background(theme.tintColor.opacity(0.20))
      }
    }

    @ViewBuilder
    private var accountHeaderView: some View {
      if let account = currentAccount.account, !viewModel.mode.isEditing {
        HStack {
          if viewModel.mode.isInShareExtension {
            AppAccountsSelectorView(routerPath: RouterPath(),
                                    accountCreationEnabled: false,
                                    avatarConfig: .status)
          } else {
            AvatarView(account.avatar, config: AvatarView.FrameConfig.status)
              .environment(theme)
              .accessibilityHidden(true)
          }

          EmojiTextApp(.init(stringValue: account.safeDisplayName),
                       emojis: account.emojis)
            .foregroundColor(theme.labelColor)
            .emojiSize(Font.scaledSubheadlineFont.emojiSize)
            .emojiBaselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
            .fontWeight(.semibold)
            .lineLimit(1)

          Spacer()

          if case let .followUp(id) = assignedFocusState {
            Button {
              followUpSEVMs.removeAll { $0.id == id }
            } label: {
              HStack {
                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
              }
            }
          }
        }
        .padding(.horizontal, .layoutPadding)
      }
    }

    private var textInput: some View {
      TextView(
        $viewModel.statusText,
        getTextView: { textView in viewModel.textView = textView }
      )
      .placeholder(String(localized: isMain ? "status.editor.text.placeholder" : "status.editor.follow-up.text.placeholder"))
      .setKeyboardType(preferences.isSocialKeyboardEnabled ? .twitter : .default)
      .padding(.horizontal, .layoutPadding)
      .padding(.vertical)
    }

    @ViewBuilder
    private var embeddedStatus: some View {
      if let status = viewModel.replyToStatus {
        Divider().padding(.vertical, .statusComponentSpacing)
        StatusRowView(viewModel: .init(status: status,
                                       client: client,
                                       routerPath: RouterPath(),
                                       showActions: false))
          .accessibilityLabel(status.content.asRawText)
          .environment(RouterPath())
          .allowsHitTesting(false)
          .environment(\.isStatusFocused, false)
          .environment(\.isModal, true)
          .padding(.horizontal, .layoutPadding)
          .padding(.vertical, .statusComponentSpacing)
        
      } else if let status = viewModel.embeddedStatus {
        StatusEmbeddedView(status: status, client: client, routerPath: RouterPath())
          .padding(.horizontal, .layoutPadding)
          .disabled(true)
      }
    }

    @ViewBuilder
    private var pollView: some View {
      if viewModel.showPoll {
        PollView(viewModel: viewModel, showPoll: $viewModel.showPoll)
          .padding(.horizontal)
      }
    }
    
    
    @ViewBuilder
    private var characterCountAndLangView: some View {
      let value = (currentInstance.instance?.configuration?.statuses.maxCharacters ?? 500) + viewModel.statusTextCharacterLength
      HStack(alignment: .center, spacing: 20) {
        Menu {
          Button {
            isPhotosPickerPresented = true
          } label: {
            Label("status.editor.photo-library", systemImage: "photo")
          }
          .buttonStyle(.plain)

          #if !targetEnvironment(macCatalyst)
          Button {
            isCameraPickerPresented = true
          } label: {
            Label("status.editor.camera-picker", systemImage: "camera")
          }
          .buttonStyle(.plain)
          #endif

          Button {
            isFileImporterPresented = true
          } label: {
            Label("status.editor.browse-file", systemImage: "folder")
          }
          .buttonStyle(.plain)

          #if !os(visionOS)
          Button {
            isGIFPickerPresented = true
          } label: {
            Label("GIPHY", systemImage: "party.popper")
          }
          .buttonStyle(.plain)
          #endif

        } label: {
          if viewModel.isMediasLoading {
            ProgressView()
          } else {
            Image(systemName: "photo.on.rectangle.angled")
          }
        }
        .padding(.leading, .layoutPadding)
        .buttonStyle(.plain)
        .photosPicker(isPresented: $isPhotosPickerPresented,
                      selection: $viewModel.mediaPickers,
                      maxSelectionCount: 4,
                      matching: .any(of: [.images, .videos]),
                      photoLibrary: .shared())
        .fileImporter(isPresented: $isFileImporterPresented,
                      allowedContentTypes: [.image, .video],
                      allowsMultipleSelection: true)
        { result in
          if let urls = try? result.get() {
            viewModel.processURLs(urls: urls)
          }
        }
        .fullScreenCover(isPresented: $isCameraPickerPresented, content: {
          CameraPickerView(selectedImage: .init(get: {
            nil
          }, set: { image in
            if let image {
              viewModel.processCameraPhoto(image: image)
            }
          }))
          .background(.black)
        })
        .sheet(isPresented: $isGIFPickerPresented, content: {
        #if !os(visionOS) && !DEBUG
          #if targetEnvironment(macCatalyst)
          NavigationStack {
            giphyView
              .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                  Button {
                    isGIFPickerPresented = false
                  } label: {
                    Image(systemName: "xmark.circle")
                  }
                }
              }
          }
          .presentationDetents([.medium, .large])
          #else
          giphyView
            .presentationDetents([.medium, .large])
          #endif
        #else
          EmptyView()
        #endif
        })
        .accessibilityLabel("accessibility.editor.button.attach-photo")
        .disabled(viewModel.showPoll)

        Button {
          withAnimation {
            viewModel.showPoll.toggle()
            viewModel.resetPollDefaults()
          }
        } label: {
          Image(systemName: viewModel.showPoll ? "chart.bar.fill" : "chart.bar")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("accessibility.editor.button.poll")
        .disabled(viewModel.shouldDisablePollButton)

        Button {
          withAnimation {
            viewModel.spoilerOn.toggle()
          }
          isSpoilerTextFocused = viewModel.id
        } label: {
          Image(systemName: viewModel.spoilerOn ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("accessibility.editor.button.spoiler")
        
        Spacer()

        LangButton(viewModel: viewModel)

        Text("\(value)")
          .foregroundColor(value < 0 ? .red : .primary)
          .font(.footnote.monospacedDigit())
          .accessibilityLabel("accessibility.editor.button.characters-remaining")
          .accessibilityValue("\(value)")
          .accessibilityRemoveTraits(.isStaticText)
          .accessibilityAddTraits(.updatesFrequently)
          .accessibilityRespondsToUserInteraction(false)
          .padding(.trailing, .layoutPadding)
      }
      .padding(.vertical, 8)
    }
    
    private func setupViewModel() {
      viewModel.client = client
      viewModel.currentAccount = currentAccount.account
      viewModel.theme = theme
      viewModel.preferences = preferences
      viewModel.prepareStatusText()
      if !client.isAuth {
        #if targetEnvironment(macCatalyst)
          dismissWindow()
        #else
          dismiss()
        #endif
        NotificationCenter.default.post(name: .shareSheetClose, object: nil)
      }

      Task { await viewModel.fetchCustomEmojis() }
    }
  }

}
