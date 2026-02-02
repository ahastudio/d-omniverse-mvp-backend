# 사용자 관계 점수

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Profile Visit Scoring (Priority: P1)

사용자가 다른 사용자의 프로필을 방문하면 관계 점수가 증가한다.

**Why this priority**: SNS의 핵심 기능으로, 사용자 간 관심도를 측정하여
추천 시스템 등에 활용

**Independent Test**: POST `/user-relationships` 엔드포인트에 요청을
보내 점수가 증가하는지 확인

**Acceptance Scenarios**:

1. 프로필 방문 점수 기록
   - **Given** 로그인한 사용자 A와 대상 사용자 B가 존재
   - **When** POST `/user-relationships` with `{ targetUserId, type: "profile_view" }`
   - **Then** 201 Created 응답, 관계 점수 +1
2. 동일 사용자 재방문 시 점수 누적
   - **Given** 사용자 A가 이전에 B의 프로필을 방문한 적 있음
   - **When** POST `/user-relationships` with `{ targetUserId, type: "profile_view" }`
   - **Then** 201 Created 응답, 기존 점수에 +1 누적
3. 자기 자신 방문 시 무시
   - **Given** 로그인한 사용자 A
   - **When** POST `/user-relationships` with `{ targetUserId: A, type: "profile_view" }`
   - **Then** 422 Unprocessable Entity 응답

### User Story 2 - Reaction Scoring (Priority: P1)

사용자가 다른 사용자의 게시물에 반응하면 관계 점수가 증가한다.

**Acceptance Scenarios**:

1. 반응 점수 기록 (좋아요)
   - **Given** 로그인한 사용자 A와 B의 게시물이 존재
   - **When** POST `/user-relationships` with `{ targetUserId, type: "reaction" }`
   - **Then** 201 Created 응답, 관계 점수 +2

### User Story 3 - Post View Scoring (Priority: P2)

사용자가 다른 사용자의 게시물을 보면 관계 점수가 증가한다.

**Acceptance Scenarios**:

1. 게시물 조회 점수 기록
   - **Given** 로그인한 사용자 A와 B의 게시물이 존재
   - **When** POST `/user-relationships` with `{ targetUserId, type: "post_view" }`
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

### Edge Cases

- 인증되지 않은 요청: 401 Unauthorized
- 존재하지 않는 대상 사용자: 404 Not Found
- 잘못된 interaction type: 422 Unprocessable Entity
- 동일 사용자를 대상으로 한 요청: 422 Unprocessable Entity

### Manual Testing with HTTPie

```bash
# 프로필 방문 점수 기록 (201 Created 예상)
http POST https://local-d-omniverse-api.a99.dev/user-relationships \
  Authorization:"Bearer <token>" \
  targetUserId=<user_id> \
  type=profile_view

# 관계 점수 조회 (200 OK 예상)
http GET https://local-d-omniverse-api.a99.dev/user-relationships/<target_user_id> \
  Authorization:"Bearer <token>"
```

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 시스템은 POST `/user-relationships` 엔드포인트를 제공해야 함
- **FR-002**: 시스템은 GET `/user-relationships/:target_user_id`
  엔드포인트를 제공해야 함
- **FR-003**: 시스템은 interaction type별로 다른 점수를 부여해야 함
  - `profile_view`: +1점
  - `reaction`: +2점
  - `post_view`: +1점
- **FR-004**: 시스템은 동일 사용자 간 중복 interaction을 누적 처리해야 함
- **FR-005**: 시스템은 자기 자신에 대한 interaction을 거부해야 함
- **FR-006**: 시스템은 인증된 사용자만 접근을 허용해야 함

### Non-Functional Requirements

- **NFR-001**: 응답 시간은 100ms 이하여야 함
- **NFR-002**: 복합 인덱스를 통한 쿼리 최적화
- **NFR-003**: 동시 요청 처리 (race condition 고려)

### Key Entities

- **UserRelationship**: 두 사용자 간의 관계 점수를 저장
  - `user_id`: 점수를 기록하는 주체 (외래키)
  - `target_user_id`: 점수를 받는 대상 (외래키)
  - `score`: 누적 점수 (정수)

## Success Criteria *(mandatory)*

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
