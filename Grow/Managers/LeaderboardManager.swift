import FirebaseFirestore
import FirebaseAuth
import Foundation

enum LeaderboardType {
    case allTime, weekly
}

class LeaderboardManager {
    static let shared = LeaderboardManager()
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    func signInAnonymously(completion: @escaping (Bool) -> Void) {
        auth.signInAnonymously { result, error in
            completion(error == nil)
        }
    }
    
    func updateEntry(_ entry: LeaderboardEntry) {
        guard auth.currentUser != nil else {
            signInAnonymously { success in
                if success { self.updateEntry(entry) }
            }
            return
        }
        
        let data: [String: Any] = [
            "userId": entry.userId,
            "displayName": entry.displayName,
            "playerClass": entry.playerClass,
            "level": entry.level,
            "totalExp": entry.totalExp,
            "weeklyExp": entry.weeklyExp,
            "bestStreak": entry.bestStreak,
            "updatedAt": Timestamp(date: entry.updatedAt)
        ]
        
        db.collection("leaderboard").document(entry.userId).setData(data, merge: true)
    }
    
    func fetchLeaderboard(type: LeaderboardType, completion: @escaping ([LeaderboardEntry]) -> Void) {
        guard auth.currentUser != nil else {
            signInAnonymously { success in
                if success { self.fetchLeaderboard(type: type, completion: completion) }
            }
            return
        }
        
        let field = type == .allTime ? "totalExp" : "weeklyExp"
        
        db.collection("leaderboard")
            .order(by: field, descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                var entries = documents.compactMap { doc -> LeaderboardEntry? in
                    let data = doc.data()
                    guard let userId = data["userId"] as? String,
                          let displayName = data["displayName"] as? String,
                          let playerClass = data["playerClass"] as? String,
                          let level = data["level"] as? Int,
                          let totalExp = data["totalExp"] as? Int,
                          let weeklyExp = data["weeklyExp"] as? Int,
                          let bestStreak = data["bestStreak"] as? Int,
                          let timestamp = data["updatedAt"] as? Timestamp else {
                        return nil
                    }
                    
                    return LeaderboardEntry(
                        userId: userId,
                        displayName: displayName,
                        playerClass: playerClass,
                        level: level,
                        totalExp: totalExp,
                        weeklyExp: weeklyExp,
                        bestStreak: bestStreak,
                        updatedAt: timestamp.dateValue()
                    )
                }
                
                for (index, _) in entries.enumerated() {
                    entries[index].rank = index + 1
                }
                
                completion(entries)
            }
    }
}
