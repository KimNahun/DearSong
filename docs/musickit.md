# MusicKit API 레퍼런스 (iOS 17+)

## 권한 요청

```swift
import MusicKit

let status = try await MusicAuthorization.request()
// .authorized / .denied / .restricted / .notDetermined
```

## 곡 검색

```swift
var request = MusicCatalogSearchRequest(term: "검색어", types: [Song.self, Artist.self])
request.limit = 25

let response = try await request.response()
let songs: MusicItemCollection<Song> = response.songs
let artists: MusicItemCollection<Artist> = response.artists
```

## Song 모델 주요 프로퍼티

```swift
let song: Song
song.id          // MusicItemID
song.title       // String — 곡 제목
song.artistName  // String — 아티스트명
song.artwork     // Artwork? — 앨범 아트워크
song.albumTitle  // String? — 앨범 제목
```

## Artwork → URL 변환

```swift
if let artwork = song.artwork {
    let url = artwork.url(width: 300, height: 300)
    // AsyncImage(url: url) 로 표시
}
```

## 주의사항

- MusicKit은 재생 없이 카탈로그 조회만 사용 (이 프로젝트)
- MusicAuthorization.request()는 최초 1회만 시스템 팝업 표시
- 권한 거부 시 수동 입력 폴백 제공 필요
- Simulator에서는 MusicKit 검색이 제한될 수 있음 — 실기기 테스트 권장
