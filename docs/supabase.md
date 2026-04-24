# Supabase Swift SDK 레퍼런스 (2.0+)

## 클라이언트 초기화

```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://xxx.supabase.co")!,
    supabaseKey: "anon-key"
)
```

DearSong 프로젝트에서는 Info.plist에서 읽기:
```swift
let url = Bundle.main.infoDictionary?["SupabaseURL"] as? String ?? ""
let key = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String ?? ""

let supabase = SupabaseClient(
    supabaseURL: URL(string: url)!,
    supabaseKey: key
)
```

## Auth: Apple Sign In

```swift
import AuthenticationServices

// 1. ASAuthorizationController로 Apple ID 토큰 획득
// 2. Supabase에 전달

let session = try await supabase.auth.signInWithIdToken(
    credentials: OpenIDConnectCredentials(
        provider: .apple,
        idToken: "apple-id-token",
        nonce: "nonce"
    )
)

// 현재 세션 확인
let session = try await supabase.auth.session
let userId = session.user.id  // UUID — owner_id로 사용

// 로그아웃
try await supabase.auth.signOut()
```

## Database: SELECT

```swift
// 전체 조회
let memories: [SongMemory] = try await supabase
    .from("song_memories")
    .select()
    .execute()
    .value

// 필터 + 정렬
let memories: [SongMemory] = try await supabase
    .from("song_memories")
    .select()
    .eq("owner_id", value: userId)
    .order("listened_at", ascending: false)
    .limit(20)
    .execute()
    .value

// 특정 곡 조회
let memory: [SongMemory] = try await supabase
    .from("song_memories")
    .select()
    .eq("apple_music_id", value: musicId)
    .eq("owner_id", value: userId)
    .execute()
    .value
```

## Database: INSERT

```swift
struct NewSongMemory: Encodable {
    let ownerId: UUID
    let appleMusicId: String?
    let songTitle: String
    let artistName: String
    let artworkUrl: String?
    let listenedAt: String       // "2016-01-01" 형식
    let moodTags: [String]
    let location: String?
    let entries: [Entry]
}

try await supabase
    .from("song_memories")
    .insert(newMemory)
    .execute()
```

## Database: UPDATE

```swift
// entries 업데이트 (jsonb 배열 교체)
try await supabase
    .from("song_memories")
    .update(["entries": updatedEntries, "updated_at": "now()"])
    .eq("id", value: memoryId)
    .execute()
```

## Database: DELETE

```swift
try await supabase
    .from("song_memories")
    .delete()
    .eq("id", value: memoryId)
    .execute()
```

## Database: UPSERT

```swift
try await supabase
    .from("song_memories")
    .upsert(memory)
    .execute()
```

## RLS 참고

- `owner_rw` 정책: `owner_id = auth.uid()`
- 인증된 사용자는 자동으로 본인 데이터만 접근
- 클라이언트에서 별도 owner_id 필터 없어도 되지만, 명시적 필터 권장

## CodingKeys (snake_case ↔ camelCase)

supabase-swift는 기본적으로 snake_case 컬럼을 사용.
Swift 모델에서 CodingKeys로 매핑:

```swift
struct SongMemory: Codable {
    let id: UUID
    let ownerId: UUID
    // ...
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case appleMusicId = "apple_music_id"
        case songTitle = "song_title"
        case artistName = "artist_name"
        case artworkUrl = "artwork_url"
        case listenedAt = "listened_at"
        case moodTags = "mood_tags"
        case location
        case entries
        case attachments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```
