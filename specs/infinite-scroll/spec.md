# 무한 스크롤 API 스펙

## 개요

프론트엔드 무한 스크롤 지원을 위한 GET /posts API 페이지네이션 구현.

## API 변경

### GET /posts

#### Query Parameters

| 파라미터 | 타입   | 필수 | 기본값 | 설명                                   |
| -------- | ------ | ---- | ------ | -------------------------------------- |
| username | string | ❌   | -      | 특정 사용자의 게시물만 (프로필 페이지) |
| type     | string | ❌   | -      | "video" 지정 시 비디오 게시물만        |
| cursor   | string | ❌   | -      | 서버가 제공한 다음 페이지 토큰         |
| limit    | number | ❌   | 10     | 한 번에 가져올 게시물 수               |

#### 사용 예시

```bash
# 피드 (추천 정렬)
GET /posts?limit=10

# 비디오 피드
GET /posts?type=video&limit=10

# 프로필 페이지 (최신순)
GET /posts?username=dancer&limit=10

# 프로필 + 비디오만
GET /posts?username=dancer&type=video&limit=10
```

#### Response

```json
{
  "posts": [
    {
      "id": "01KG...",
      "content": "게시물 내용",
      "videoUrl": "/videos/hls/.../playlist.m3u8",
      "createdAt": "2025-01-20T14:00:00Z",
      "user": {
        "id": "01JCS...",
        "username": "dancer",
        "nickname": "DanceMaster",
        "avatarUrl": "https://..."
      }
    }
  ],
  "nextCursor": "abc123" | null
}
```

#### 필드 설명

- `posts`: 게시물 배열 (최대 limit 개)
- `nextCursor`: 다음 페이지 요청 시 전달할 토큰 (null이면 마지막 페이지)

## 구현 세부사항

### Opaque Cursor 패턴

- 프론트엔드는 cursor의 내부 구조를 알 필요 없음
- 서버가 제공한 값을 그대로 다음 요청에 전달
- 서버 내부적으로는 offset으로 처리 (추후 변경 가능)

### 프론트엔드 사용 예시

```typescript
const [cursor, setCursor] = useState<string | null>(null);

// 첫 페이지
const { posts, nextCursor } = await fetchPosts({ limit: 10 });

// 다음 페이지 (무한 스크롤 트리거)
if (nextCursor) {
  const next = await fetchPosts({ limit: 10, cursor: nextCursor });
  setPosts([...posts, ...next.posts]);
  setCursor(next.nextCursor);
}
```

### 내부 구현

```ruby
# cursor는 내부적으로 offset (프론트는 모름)
offset = params[:cursor].present? ? params[:cursor].to_i : 0
posts = all_posts.drop(offset).take(limit)
next_cursor = has_more ? (offset + limit).to_s : nil
```

### 주의사항

- 새 게시물 추가 시 중복 가능 (새로고침으로 해결)
- cursor 형식이 바뀌어도 프론트엔드 변경 불필요
