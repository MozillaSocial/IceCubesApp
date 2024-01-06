import DesignSystem
import EmojiText
import Foundation
import SwiftUI
import Models
import SwiftData


extension StatusEditorAutoCompleteView {
  struct MentionsView: View {
    @Environment(Theme.self) private var theme
    
    var viewModel: StatusEditorViewModel
  
    var body: some View {
      ForEach(viewModel.mentionsSuggestions) { account in
        Button {
          viewModel.selectMentionSuggestion(account: account)
        } label: {
          HStack {
            AvatarView(account.avatar, config: AvatarView.FrameConfig.badge)
            VStack(alignment: .leading) {
              EmojiTextApp(.init(stringValue: account.safeDisplayName),
                           emojis: account.emojis)
                .emojiSize(Font.scaledFootnoteFont.emojiSize)
                .emojiBaselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
                .font(.scaledFootnote)
                .fontWeight(.bold)
                .foregroundColor(theme.labelColor)
              Text("@\(account.acct)")
                .font(.scaledFootnote)
                .foregroundStyle(theme.tintColor)
            }
          }
        }
      }
    }
  }
}