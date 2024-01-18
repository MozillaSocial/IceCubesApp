//
//  DiscoverKitTab.swift
//  IceCubesApp
//
//  Created by Conor Masterson on 2024-01-18.
//

import Foundation
import SwiftUI
import DiscoverKit
import MoSoAnalytics
import MoSoCore


struct TestDiscoverTracker: DiscoverTracker {
    func trackRecommendationOpen(recommendationID: String) {
        print("Track: \(recommendationID)")
    }

    func trackRecommendationShare(recommendationID: String) {
        print("Track: \(recommendationID)")
    }

    func trackRecommendationBookmark(recommendationID: String) {
        print("Track: \(recommendationID)")
    }

    func trackDiscoverScreenImpression() {
        print("Track impression")
    }

    func trackRecommendationImpression(recommendationID: String) {
        print("Track: \(recommendationID)")
    }
}

@MainActor
struct DiscoverTab: View {
    var body: some View {
        DiscoverProvider(session: MoSoSessionManager(user: nil), tracker: TestDiscoverTracker()).makeDiscoverRootView()
    }
}
