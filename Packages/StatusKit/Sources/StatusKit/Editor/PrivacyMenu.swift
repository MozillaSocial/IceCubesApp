import Models
import SwiftUI

extension StatusEditor {
  struct PrivacyMenu: View {
    @Binding var visibility: Models.Visibility
    let foregroundColor: Color

    var body: some View {
      Menu {
        ForEach(Models.Visibility.allCases, id: \.self) { vis in
          Button { visibility = vis } label: {
            Label(vis.title, systemImage: vis.iconName)
          }
        }
      } label: {
        HStack(spacing: 7) {
          Image(systemName: visibility.iconName)
          Text(visibility.title)
          Image(systemName: "chevron.down")
        }
        .foregroundStyle(foregroundColor)
        .font(.footnote)
        .accessibilityLabel("accessibility.editor.privacy.label")
        .accessibilityValue(visibility.title)
        .accessibilityHint("accessibility.editor.privacy.hint")
      }
    }
  }

}
