# 사용자 관계 점수

## OpenAPI Spec

```yaml
openapi: 3.0.3
info:
  title: User Relationship Scoring API
  version: 1.0.0

paths:
  /user-relationships:
    get:
      summary: 관계 점수 목록 조회
      description: 특정 사용자의 모든 관계를 점수 높은 순으로 조회
      security:
        - bearerAuth: []
      parameters:
        - name: userId
          in: query
          required: false
          schema:
            type: string
          description: 조회할 사용자 ID (생략 시 현재 로그인한 사용자)
      responses:
        "200":
          description: 관계 목록 조회 성공
          content:
            application/json:
              schema:
                type: object
                properties:
                  relationships:
                    type: array
                    items:
                      $ref: "#/components/schemas/UserRelationshipDetail"
        "401":
          description: 인증 실패
        "404":
          description: 사용자를 찾을 수 없음

    post:
      summary: 관계 점수 기록
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - targetUserId
                - type
              properties:
                targetUserId:
                  type: string
                  description: 대상 사용자 ID (ULID)
                type:
                  type: string
                  enum: [profile_view, reaction, post_view]
                  description: interaction 유형
      responses:
        "201":
          description: 점수 기록 성공
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/UserRelationship"
        "401":
          description: 인증 실패
        "404":
          description: 대상 사용자 없음
        "422":
          description: 유효하지 않은 요청 (자기 자신, 잘못된 type)

  /user-relationships/{id}:
    get:
      summary: 관계 점수 조회
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: 대상 사용자 ID (ULID)
      responses:
        "200":
          description: 점수 조회 성공
          content:
            application/json:
              schema:
                type: object
                properties:
                  score:
                    type: integer
        "401":
          description: 인증 실패
        "404":
          description: 대상 사용자 없음

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    UserRelationship:
      type: object
      properties:
        id:
          type: string
        userId:
          type: string
        targetUserId:
          type: string
        score:
          type: integer
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    UserRelationshipDetail:
      type: object
      properties:
        id:
          type: string
          description: 대상 사용자 ID
        username:
          type: string
          description: 대상 사용자 아이디
        nickname:
          type: string
          description: 대상 사용자 닉네임
        profileImageUrl:
          type: string
          description: 대상 사용자 프로필 이미지 URL
        score:
          type: integer
          description: 관계 점수
```

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Profile Visit Scoring (Priority: P1)

사용자가 다른 사용자의 프로필을 방문하면 관계 점수가 증가한다.

**Why this priority**: SNS의 핵심 기능으로, 사용자 간 관심도를 측정하여 추천
시스템 등에 활용

**Independent Test**: POST `/user-relationships` 엔드포인트에 요청을 보내 점수가
증가하는지 확인

**Acceptance Scenarios**:

1. 프로필 방문 점수 기록
   - **Given** 로그인한 사용자 A와 대상 사용자 B가 존재
   - **When** POST `/user-relationships` with
     `{ targetUserId, type: "profile_view" }`
   - **Then** 201 Created 응답, 관계 점수 +1
2. 동일 사용자 재방문 시 점수 누적
   - **Given** 사용자 A가 이전에 B의 프로필을 방문한 적 있음
   - **When** POST `/user-relationships` with
     `{ targetUserId, type: "profile_view" }`
   - **Then** 201 Created 응답, 기존 점수에 +1 누적
3. 자기 자신 방문 시 무시
   - **Given** 로그인한 사용자 A
   - **When** POST `/user-relationships` with
     `{ targetUserId: A, type: "profile_view" }`
   - **Then** 422 Unprocessable Entity 응답

### User Story 2 - Reaction Scoring (Priority: P1)

사용자가 다른 사용자의 게시물에 반응하면 관계 점수가 증가한다.

**Acceptance Scenarios**:

1. 반응 점수 기록 (좋아요)
   - **Given** 로그인한 사용자 A와 B의 게시물이 존재
   - **When** POST `/user-relationships` with
     `{ targetUserId, type: "reaction" }`
   - **Then** 201 Created 응답, 관계 점수 +2

### User Story 3 - Post View Scoring (Priority: P2)

사용자가 다른 사용자의 게시물을 보면 관계 점수가 증가한다.

**Acceptance Scenarios**:

1. 게시물 조회 점수 기록
   - **Given** 로그인한 사용자 A와 B의 게시물이 존재
   - **When** POST `/user-relationships` with
     `{ targetUserId, type: "post_view" }`
   - **Then** 201 Created 응답, 관계 점수 +1

### User Story 4 - Relationship Score Query (Priority: P1)

사용자가 특정 사용자와의 관계 점수를 조회할 수 있다.

**Acceptance Scenarios**:

1. 관계 점수 조회
   - **Given** 사용자 A와 B 사이에 점수가 존재
   - **When** GET `/user-relationships/:target_user_id`
   - **Then** 200 OK 응답, `{ score: N }` 반환
2. 관계 점수가 없는 경우
   - **Given** 사용자 A와 C 사이에 점수가 없음
   - **When** GET `/user-relationships/:target_user_id`
   - **Then** 200 OK 응답, `{ score: 0 }` 반환

### User Story 5 - Relationship List Query (Priority: P1)

사용자가 특정 사용자의 모든 관계를 점수 높은 순으로 조회할 수 있다.

**Why this priority**: 프로필 페이지에서 관계가 가까운 사용자를 우선 표시하여
사용자 간 연결성을 강화. 다른 사용자의 프로필을 방문해도 해당 사용자와 관련된
사용자 목록을 볼 수 있어야 함.

**Independent Test**: GET `/user-relationships?userId=<user_id>` 엔드포인트에
요청을 보내 점수 순으로 정렬된 목록이 반환되는지 확인

**Acceptance Scenarios**:

1. 자신의 관계 목록 조회
   - **Given** 로그인한 사용자 A가 여러 사용자와 관계를 가지고 있음
   - **When** GET `/user-relationships`
   - **Then** 200 OK 응답, 점수 높은 순으로 정렬된 관계 목록 반환
2. 다른 사용자의 관계 목록 조회
   - **Given** 로그인한 사용자 A와 사용자 B가 존재
   - **When** GET `/user-relationships?userId=<B의 ID>`
   - **Then** 200 OK 응답, B의 관계 목록이 점수 높은 순으로 반환
3. 관계가 없는 경우
   - **Given** 사용자 C가 아무와도 관계가 없음
   - **When** GET `/user-relationships?userId=<C의 ID>`
   - **Then** 200 OK 응답, 빈 배열 반환
4. 존재하지 않는 사용자
   - **Given** 존재하지 않는 사용자 ID
   - **When** GET `/user-relationships?userId=<존재하지 않는 ID>`
   - **Then** 404 Not Found 응답

### Edge Cases

- 인증되지 않은 요청: 401 Unauthorized
- 존재하지 않는 대상 사용자: 404 Not Found
- 잘못된 interaction type: 422 Unprocessable Entity
- 동일 사용자를 대상으로 한 요청: 422 Unprocessable Entity

### Manual Testing with HTTPie

```bash
# 자신의 관계 목록 조회 (200 OK 예상)
http GET \
  https://local-d-omniverse-api.a99.dev/user-relationships \
  Authorization:"Bearer <token>"

# 다른 사용자의 관계 목록 조회 (200 OK 예상)
http GET \
  "https://local-d-omniverse-api.a99.dev/user-relationships?userId=<user_id>" \
  Authorization:"Bearer <token>"

# 프로필 방문 점수 기록 (201 Created 예상)
http POST \
  https://local-d-omniverse-api.a99.dev/user-relationships \
  Authorization:"Bearer <token>" \
  targetUserId=<user_id> \
  type=profile_view

# 관계 점수 조회 (200 OK 예상)
http GET \
  https://local-d-omniverse-api.a99.dev/user-relationships/<target_user_id> \
  Authorization:"Bearer <token>"
```

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: 시스템은 POST `/user-relationships` 엔드포인트를 제공해야 함
- **FR-002**: 시스템은 GET `/user-relationships/:target_user_id` 엔드포인트를
  제공해야 함
- **FR-003**: 시스템은 GET `/user-relationships` 엔드포인트를 제공해야 함
- **FR-004**: GET `/user-relationships`는 userId 쿼리 파라미터로 특정 사용자의
  관계 목록을 조회할 수 있어야 함 (생략 시 현재 로그인한 사용자)
- **FR-005**: 시스템은 interaction type별로 다른 점수를 부여해야 함
  - `profile_view`: +1점
  - `reaction`: +2점
  - `post_view`: +1점
- **FR-006**: 시스템은 동일 사용자 간 중복 interaction을 누적 처리해야 함
- **FR-007**: 시스템은 자기 자신에 대한 interaction을 거부해야 함
- **FR-008**: 시스템은 인증된 사용자만 접근을 허용해야 함
- **FR-009**: 관계 목록은 점수 높은 순으로 정렬되어야 함
- **FR-010**: 관계 목록에는 대상 사용자의 id, username, nickname,
  profileImageUrl, score가 포함되어야 함

### Non-Functional Requirements

- **NFR-001**: 응답 시간은 100ms 이하여야 함
- **NFR-002**: 복합 인덱스를 통한 쿼리 최적화
- **NFR-003**: 동시 요청 처리 (race condition 고려)

### Key Entities

- **UserRelationship**: 두 사용자 간의 관계 점수를 저장
  - `user_id`: 점수를 기록하는 주체 (외래키)
  - `target_user_id`: 점수를 받는 대상 (외래키)
  - `score`: 누적 점수 (정수)

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: 모든 interaction type에 대해 정확한 점수 부여
- **SC-002**: 중복 요청 시 정확한 점수 누적
- **SC-003**: 평균 응답 시간 100ms 이하
- **SC-004**: 인증 없는 요청 100% 거부

## Assumptions

- User 모델이 존재하고 ULID 기반 id를 사용
- JWT 기반 인증 시스템이 구현되어 있음
- 양방향 관계 (A→B와 B→A는 별도 점수)

## Out of Scope

- 점수 감소 (차단, 신고 등)
- 점수 기반 추천 알고리즘
- 점수 만료/감쇠
- 일일 점수 제한

## Dependencies

- User 모델 (app/models/user.rb)
- ApplicationController의 인증 로직
- ULID 생성기
