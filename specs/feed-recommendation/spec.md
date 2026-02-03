# 피드 추천 (Feed Recommendation)

## 개요

Scene 페이지의 **피드(Feed)**에서 로그인한 사용자에게 연결된 사용자의 게시물을
우선 노출하는 기능. `UserRelationship`의 관계 점수(score)를 weight로 활용하여
친밀한 사용자의 게시물이 피드 상위에 표시되도록 함.

**핵심**: 나와 연결된 사람의 게시물이 피드에서 계속 위로 올라오는 것이 관건.

## OpenAPI Spec

```yaml
openapi: 3.0.3
info:
  title: Posts API (Recommendation)
  version: 1.0.0

paths:
  /posts:
    get:
      summary: 게시물 목록 조회 (추천 정렬)
      description: |
        로그인 사용자: 관계 점수 기반 weight 적용하여 정렬
        비로그인 사용자: 최신순 정렬
      security:
        - bearerAuth: []
        - {}
      parameters:
        - name: type
          in: query
          required: false
          schema:
            type: string
            enum: [video]
          description: 비디오 게시물만 필터링
      responses:
        "200":
          description: 게시물 목록 조회 성공
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/Post"

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    Post:
      type: object
      properties:
        id:
          type: string
        user:
          $ref: "#/components/schemas/PostUser"
        content:
          type: string
        videoUrl:
          type: string
          nullable: true
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    PostUser:
      type: object
      properties:
        id:
          type: string
        username:
          type: string
        nickname:
          type: string
        avatarUrl:
          type: string
```

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Weighted Post Recommendation (Priority: P1)

로그인한 사용자가 Scene 페이지를 조회하면 관계 점수가 높은 사용자의 게시물이
상위에 노출된다.

**Why this priority**: 핵심 기능. 사용자 경험의 핵심으로, 친밀한 사용자의
콘텐츠를 우선 보여줌으로써 engagement를 높임.

**Independent Test**: GET `/posts` 요청 시 관계 점수 높은 사용자의 게시물이
먼저 반환되는지 확인

**Acceptance Scenarios**:

1. 관계 점수 기반 정렬
   - **Given** 로그인한 사용자 A, 사용자 B(점수 10), 사용자 C(점수 5)가 존재
   - **And** B와 C가 각각 게시물을 작성함
   - **When** GET `/posts`
   - **Then** B의 게시물이 C의 게시물보다 먼저 노출됨

2. 동일 점수일 때 최신순 정렬
   - **Given** 사용자 B와 C 모두 점수 10
   - **And** C가 B보다 나중에 게시물 작성
   - **When** GET `/posts`
   - **Then** C의 게시물이 B의 게시물보다 먼저 노출됨

3. 관계 없는 사용자의 게시물은 하단에 노출
   - **Given** 사용자 B(점수 10), 사용자 D(관계 없음)
   - **When** GET `/posts`
   - **Then** B의 게시물이 D의 게시물보다 먼저 노출됨

### User Story 2 - Self Posts Always on Top (Priority: P1)

로그인한 사용자의 본인 게시물은 항상 최상단에 노출된다.

**Acceptance Scenarios**:

1. 본인 게시물 최상단 노출
   - **Given** 로그인한 사용자 A가 게시물을 작성함
   - **And** 관계 점수 높은 B도 게시물을 작성함
   - **When** GET `/posts`
   - **Then** A의 게시물이 B의 게시물보다 먼저 노출됨

### User Story 3 - Unauthenticated User (Priority: P1)

비로그인 사용자는 기존처럼 최신순 정렬된 게시물을 본다.

**Acceptance Scenarios**:

1. 최신순 정렬
   - **Given** 비로그인 상태
   - **When** GET `/posts`
   - **Then** 게시물이 최신순(id desc)으로 정렬됨

### User Story 4 - Video Filter with Recommendation (Priority: P2)

비디오 필터와 추천 정렬이 함께 동작한다.

**Acceptance Scenarios**:

1. 비디오만 추천 정렬
   - **Given** 로그인한 사용자 A, 사용자 B(점수 10)의 비디오 게시물 존재
   - **When** GET `/posts?type=video`
   - **Then** B의 비디오 게시물이 우선 노출됨

### Edge Cases

- 관계 점수가 모두 0인 경우: 최신순 정렬
- 게시물이 없는 경우: 빈 배열 반환
- 삭제된 게시물: 노출되지 않음 (기존 `visible` scope 유지)

### Manual Testing with HTTPie

```bash
# 비로그인 - 최신순 (200 OK 예상)
http GET https://local-d-omniverse-api.a99.dev/posts

# 로그인 - 추천 정렬 (200 OK 예상)
http GET https://local-d-omniverse-api.a99.dev/posts \
  Authorization:"Bearer <token>"

# 비디오 필터 + 추천 정렬 (200 OK 예상)
http GET "https://local-d-omniverse-api.a99.dev/posts?type=video" \
  Authorization:"Bearer <token>"
```

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: 로그인 사용자의 GET `/posts` 요청 시 관계 점수 기반 정렬 적용
- **FR-002**: 본인 게시물은 최상단에 노출
- **FR-003**: 관계 점수가 높을수록 상위에 노출
- **FR-004**: 동일 점수일 때 최신순(id desc) 정렬
- **FR-005**: 관계가 없는 사용자(점수 0)의 게시물은 하단에 노출
- **FR-006**: 비로그인 사용자는 기존 최신순 정렬 유지
- **FR-007**: 기존 `type=video` 필터와 호환

### Non-Functional Requirements

- **NFR-001**: 응답 시간 200ms 이하 유지
- **NFR-002**: 기존 API 응답 형식 변경 없음 (하위 호환)
- **NFR-003**: N+1 쿼리 방지

### Key Entities

- **Post**: 게시물 (기존)
- **UserRelationship**: 사용자 간 관계 점수 (기존)

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: 관계 점수 높은 사용자의 게시물이 먼저 노출됨
- **SC-002**: 본인 게시물이 항상 최상단에 노출됨
- **SC-003**: 비로그인 시 최신순 정렬 유지
- **SC-004**: 기존 테스트 모두 통과

## Assumptions

- `UserRelationship` 모델이 존재하고 정상 동작
- 현재 로그인한 사용자의 `user_id`를 `UserRelationship.user_id`로 조회
- 양방향 관계가 아닌 단방향 (A→B 점수만 A에게 적용)

## Out of Scope

- 페이지네이션 (추후 별도 기능으로)
- 추천 알고리즘 고도화 (시간 가중치, 콘텐츠 유형별 가중치 등)
- 관계 점수 실시간 반영 (기존 점수 기반)
- 사용자 차단/뮤트 기능

## Dependencies

- `UserRelationship` 모델 ([spec](../user-relationship-scoring/spec.md))
- `Post` 모델 (app/models/post.rb)
- `PostsController` (app/controllers/posts_controller.rb)

## Implementation Notes

### 정렬 로직 (Weight 계산)

```text
정렬 우선순위:
1. 본인 게시물 (최상단)
2. 관계 점수 높은 순
3. 동일 점수 시 최신순 (id desc)
```

### SQL 예시 (참고용)

```sql
SELECT posts.*,
       CASE WHEN posts.user_id = :current_user_id THEN 1 ELSE 0 END AS is_self,
       COALESCE(user_relationships.score, 0) AS relationship_score
FROM posts
LEFT JOIN user_relationships
  ON user_relationships.user_id = :current_user_id
  AND user_relationships.target_user_id = posts.user_id
WHERE posts.deleted_at IS NULL
ORDER BY is_self DESC,
         relationship_score DESC,
         posts.id DESC
```
