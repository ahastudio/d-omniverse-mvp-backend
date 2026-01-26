# 스레드 기능 사양서 (Threading Feature Specification)

## 개요

D-Omniverse 소셜 미디어에 트위터 스타일의 스레드(Threading) 기능을 추가한다.
현재는 각 글(Post)이 독립적으로 존재하지만, 이 기능을 통해 글들이 서로
연결되어 대화 형태의 스레드를 형성할 수 있다.

## 목표

1. **답글(Reply)**: 기존 글에 대한 답글을 작성할 수 있다
2. **인용(Quote)**: 다른 글을 인용하면서 새 글을 작성할 수 있다
3. **리포스트(Repost)**: 다른 글을 그대로 공유할 수 있다
4. **스레드 조회**: 특정 글의 답글 목록과 상위 스레드를 조회할 수 있다

## 용어 정의

| 용어 | 설명 |
|------|------|
| 원본 글 (Original Post) | 스레드의 시작점이 되는 글 |
| 답글 (Reply) | 다른 글에 대한 응답으로 작성된 글 |
| 부모 글 (Parent Post) | 현재 글이 답글인 경우, 답글 대상이 되는 글 |
| 인용 (Quote) | 다른 글을 포함하면서 새로운 내용을 추가한 글 |
| 리포스트 (Repost) | 다른 글을 그대로 공유 (내용 없이 원본만 참조) |

## 데이터 모델

### Posts 테이블 확장

기존 posts 테이블에 다음 컬럼을 추가한다:

| 컬럼 | 타입 | 설명 | NULL |
|------|------|------|------|
| parent_id | string | 답글 대상 글의 ID | 허용 |
| quoted_post_id | string | 인용한 글의 ID | 허용 |
| reposted_post_id | string | 리포스트한 글의 ID | 허용 |

### 제약 조건

1. `parent_id`, `quoted_post_id`, `reposted_post_id`는 모두 posts.id를 참조
2. 리포스트의 경우 `content`가 비어있을 수 있음 (기존 NOT NULL 제약 조정 필요)
3. 자기 자신을 참조할 수 없음 (자기 글에 답글/인용/리포스트 불가)
4. 삭제된 글을 참조하는 경우의 처리 정책 필요

### 글 유형 판별

```
일반 글:     parent_id=NULL, quoted_post_id=NULL, reposted_post_id=NULL
답글:        parent_id!=NULL
인용:        quoted_post_id!=NULL (content 필수)
리포스트:    reposted_post_id!=NULL, content=NULL
```

## API 엔드포인트

### 1. 글 작성 (기존 확장)

```
POST /posts
```

**요청 본문**:

```json
{
  "content": "글 내용",
  "videoUrl": "동영상 URL (선택)",
  "parentId": "답글 대상 글 ID (선택)",
  "quotedPostId": "인용할 글 ID (선택)"
}
```

**리포스트 요청**:

```json
{
  "repostedPostId": "리포스트할 글 ID"
}
```

**유효성 검증**:

- `parentId`, `quotedPostId`, `repostedPostId`는 동시에 여러 개 지정 불가
- `repostedPostId` 지정 시 `content`는 비어있어야 함
- `quotedPostId` 지정 시 `content`는 필수
- 참조 대상 글이 존재해야 함

### 2. 글 목록 조회 (기존 확장)

```
GET /posts
GET /posts?type=video
GET /posts?type=reply
GET /posts?type=quote
GET /posts?type=repost
```

**응답에 추가될 필드**:

```json
{
  "id": "...",
  "content": "...",
  "parentId": "...",
  "quotedPostId": "...",
  "repostedPostId": "...",
  "quotedPost": { ... },      // 인용된 글 정보 (있는 경우)
  "repostedPost": { ... },    // 리포스트된 글 정보 (있는 경우)
  "replyCount": 0,            // 답글 수
  "quoteCount": 0,            // 인용 수
  "repostCount": 0            // 리포스트 수
}
```

### 3. 단일 글 조회 (신규)

```
GET /posts/:id
```

**응답**:

```json
{
  "id": "...",
  "content": "...",
  "user": { ... },
  "parentId": "...",
  "parentPost": { ... },      // 부모 글 정보
  "quotedPostId": "...",
  "quotedPost": { ... },
  "replyCount": 0,
  "quoteCount": 0,
  "repostCount": 0,
  "createdAt": "...",
  "updatedAt": "..."
}
```

### 4. 글의 답글 목록 조회 (신규)

```
GET /posts/:id/replies
```

**응답**: 해당 글에 달린 답글 목록 (페이지네이션 지원)

### 5. 스레드 조회 (신규)

```
GET /posts/:id/thread
```

**응답**: 해당 글의 상위 스레드 (부모 → 조부모 → ... → 원본)와 함께 반환

```json
{
  "ancestors": [ ... ],       // 상위 스레드 (오래된 순)
  "post": { ... },            // 현재 글
  "replies": [ ... ]          // 직접 답글 목록
}
```

## 카운터 캐싱

성능을 위해 다음 카운터를 posts 테이블에 추가 고려:

| 컬럼 | 설명 |
|------|------|
| reply_count | 답글 수 |
| quote_count | 인용 수 |
| repost_count | 리포스트 수 |

## 삭제 정책

원본 글이 삭제된 경우:

1. **Soft Delete 방식**: 글을 삭제 표시만 하고 참조 관계 유지
2. **Nullify 방식**: 참조하는 글의 parent_id 등을 NULL로 변경
3. **Cascade 방식**: 연결된 모든 답글도 함께 삭제

**권장**: Soft Delete 또는 Nullify 방식 (사용자 경험 고려)

## 비즈니스 규칙

1. 리포스트는 동일 사용자가 같은 글을 중복 리포스트할 수 없음
2. 비공개 글(향후 기능)은 답글/인용/리포스트 제한
3. 차단된 사용자의 글은 답글/인용/리포스트 제한 (향후 기능)

## 성능 고려사항

1. `parent_id`, `quoted_post_id`, `reposted_post_id`에 인덱스 추가
2. 답글 목록 조회 시 페이지네이션 필수
3. 깊은 스레드 조회 시 depth 제한 고려 (예: 최대 100단계)

## 마이그레이션 계획

기존 데이터에는 영향 없음 (새 컬럼은 모두 NULL 허용)
