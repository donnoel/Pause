import ActivityKit
import WidgetKit
import SwiftUI

struct PauseWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct PauseWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PauseWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension PauseWidgetAttributes {
    fileprivate static var preview: PauseWidgetAttributes {
        PauseWidgetAttributes(name: "World")
    }
}

extension PauseWidgetAttributes.ContentState {
    fileprivate static var smiley: PauseWidgetAttributes.ContentState {
        PauseWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: PauseWidgetAttributes.ContentState {
         PauseWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: PauseWidgetAttributes.preview) {
   PauseWidgetLiveActivity()
} contentStates: {
    PauseWidgetAttributes.ContentState.smiley
    PauseWidgetAttributes.ContentState.starEyes
}
