import Foundation

/// Seed content so the app is useful the moment it opens.
enum Samples {
    static let a = """
    {
      "id": "usr_8f2a",
      "name": "Ada Lovelace",
      "active": true,
      "roles": ["admin", "engineer"],
      "meta": "{\\"lastLogin\\":\\"2026-07-20T09:14:00Z\\",\\"prefs\\":{\\"theme\\":\\"dark\\",\\"beta\\":true}}",
      "score": 98.6,
      "manager": null
    }
    """

    static let b = """
    {
      "id": "usr_8f2a",
      "name": "Ada Lovelace",
      "active": false,
      "roles": ["admin", "engineer", "reviewer"],
      "score": 91.2,
      "manager": "usr_1c00"
    }
    """
}
