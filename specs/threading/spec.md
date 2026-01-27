# 스레드 기능 사양서 (Threading Feature Specification)

## 개요

D-Omniverse 소셜 미디어에 스레드(Threading) 기능을 추가한다. 현재는 각
글(Post)이 독립적으로 존재하지만, 이 기능을 통해 글들이 `parent_id`로 서로
연결되어 대화 형태의 스레드를 형성할 수 있다.

## 목표

1. 모든 글은 다른 글의 자식이 될 수 있다 (스레드 연결)
2. 특정 글의 하위 스레드(답글 목록)를 조회할 수 있다
3. 특정 글의 상위 스레드(조상 목록)를 조회할 수 있다

## 용어 정의

| 용어 | 설명 |
|------|------|
| 루트 글 (Root Post) | parent_id가 NULL인 글, 스레드의 시작점 |
| 자식 글 (Child Post) | parent_id가 있는 글, 다른 글에 연결된 글 |
| 부모 글 (Parent Post) | 현재 글이 연결된 대상 글 |
| 스레드 (Thread) | 부모-자식 관계로 연결된 글들의 집합 |

## 데이터 모델

### Posts 테이블 확장

기존 posts 테이블에 다음 컬럼을 추가한다:

| 컬럼 | 타입 | 설명 | NULL |
|------|------|------|------|
| parent_id | string | 부모 글의 ID | 허용 |

### 제약 조건

1. `parent_id`는 posts.id를 참조 (자기 참조 관계)
2. 자기 자신을 참조할 수 없음
3. 순환 참조 불가 (A → B → A)

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
  "parentId": "부모 글 ID (선택)"
}
```

**유효성 검증**:

- `parentId` 지정 시 해당 글이 존재해야 함
- 자기 자신을 부모로 지정 불가

### 2. 글 목록 조회 (기존 확장)

```
GET /posts
GET /posts?type=video
```

**응답에 추가될 필드**:

```json
{
  "id": "...",
  "content": "...",
  "parentId": "...",
  "replyCount": 0
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
  "replyCount": 0,
  "createdAt": "...",
  "updatedAt": "..."
}
```

### 4. 글의 답글 목록 조회 (신규)

```
GET /posts/:id/replies
```

**응답**: 해당 글을 parent로 가진 글 목록

### 5. 스레드 조회 (신규)

```
GET /posts/:id/thread
```

**응답**: 상위 스레드와 하위 답글을 함께 반환

```json
{
  "ancestors": [ ... ],
  "post": { ... },
  "replies": [ ... ]
}
```

## 카운터 캐싱

| 컬럼 | 설명 |
|------|------|
| reply_count | 자식 글 수 (replies_count) |

## 삭제 정책

- **Soft Delete**: deleted_at 컬럼으로 삭제 여부 표시
- 삭제된 글은 "삭제된 글입니다"로 표시되고 스레드 구조는 유지됨

## 성능 고려사항

1. `parent_id`에 인덱스 추가
2. 답글 목록 조회 시 페이지네이션
3. 스레드 깊이 제한 (예: 최대 100단계)

## 마이그레이션 계획

기존 데이터에는 영향 없음 (parent_id는 NULL 허용)
