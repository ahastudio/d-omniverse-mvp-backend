# Progress Log

> **각 단계를 완료하거나 문제가 발생하면 업데이트하세요.**

## Session 2026-02-02

### Phase 1: Requirements & Discovery ✅

**작업 내역**:

1. 기능 요구사항 분석 및 spec.md 작성
2. 기존 코드베이스 탐색
3. User 모델 구조 확인 (ULID 기반 id, username unique)
4. 기존 스펙 템플릿 형식 파악

**생성/수정 파일**:

- `specs/user-relationship-scoring/spec.md` (새로 생성)
- `specs/user-relationship-scoring/plan.md` (새로 생성)
- `specs/user-relationship-scoring/findings.md` (새로 생성)
- `specs/user-relationship-scoring/progress.md` (새로 생성)

### Phase 2: Planning & Structure ✅

**작업 내역**:

1. 데이터베이스 스키마 설계 (user_relationships 테이블)
2. 라우팅 설계 (POST /user-relationships, GET /user-relationships/:id)
3. 컨트롤러 액션 설계 (create, show)
4. 점수 계산 로직 설계 (INTERACTION_SCORES 상수)

### Phase 3: Implementation ✅

**작업 내역**:

1. 마이그레이션 생성 (`20260202100000_create_user_relationships.rb`)
2. UserRelationship 모델 구현 (`app/models/user_relationship.rb`)
3. UserRelationshipsController 구현
4. 라우트 추가 (`config/routes.rb`)

**생성/수정 파일**:

- `db/migrate/20260202100000_create_user_relationships.rb` (새로 생성)
- `app/models/user_relationship.rb` (새로 생성)
- `app/controllers/user_relationships_controller.rb` (새로 생성)
- `config/routes.rb` (수정)

### Phase 4: Testing & Verification ✅

**작업 내역**:

1. 테스트 fixture 작성 (`test/fixtures/user_relationships.yml`)
2. 컨트롤러 테스트 작성 (`user_relationships_controller_test.rb`)
3. 12개 테스트 케이스 작성 및 통과
   - profile_view 점수 기록
   - reaction 점수 기록
   - post_view 점수 기록
   - invalid type 거부
   - self targeting 거부
   - target not found 처리
   - unauthorized 처리
   - 점수 조회 (기존 관계)
   - 점수 조회 (관계 없음)
   - 점수 누적 테스트

**생성/수정 파일**:

- `test/fixtures/user_relationships.yml` (새로 생성)
- `test/controllers/user_relationships_controller_test.rb` (새로 생성)

### Phase 5: Delivery ✅

**작업 내역**:

1. 스펙 문서 업데이트
2. 커밋 및 푸시

## Session 2026-02-03

### Phase 6: Feature Extension ✅

**작업 내역**:

1. 관계 목록 조회 API 요구사항 추가 (spec.md 업데이트)
   - GET `/user-relationships?userId=<user_id>` 엔드포인트
   - userId 생략 시 현재 사용자, 지정 시 해당 사용자
   - 점수 높은 순 정렬
   - 대상 사용자 정보 포함 (id, username, nickname, avatarUrl, score)
2. 3-File Pattern 업데이트 (plan.md, findings.md, progress.md)
3. routes.rb에 index 액션 추가
4. UserRelationshipsController에 index 액션 구현
   - userId 쿼리 파라미터 처리 (선택적)
   - includes(:target_user)로 N+1 쿼리 방지
   - order(score: :desc)로 정렬
   - User.find로 404 자동 처리
5. 테스트 작성 및 실행 (6개 추가, 총 18개 테스트 모두 통과)
   - 자신의 관계 목록 조회
   - 다른 사용자 관계 목록 조회
   - 관계 없는 경우
   - 사용자 없는 경우 (404)
   - 인증 없는 경우 (401)
   - 점수 내림차순 정렬 확인

**생성/수정 파일**:

- `specs/user-relationship-scoring/spec.md` (수정)
- `specs/user-relationship-scoring/plan.md` (수정)
- `specs/user-relationship-scoring/findings.md` (수정)
- `specs/user-relationship-scoring/progress.md` (수정)
- `config/routes.rb` (수정)
- `app/controllers/user_relationships_controller.rb` (수정)
- `test/controllers/user_relationships_controller_test.rb` (수정)

## Test Results

| Test                   | Input                  | Expected          | Actual       | Status |
| ---------------------- | ---------------------- | ----------------- | ------------ | ------ |
| profile_view 점수 기록 | targetUserId, type=... | 201 Created, +1   | 201, score=6 | ✅     |
| reaction 점수 기록     | targetUserId, type=... | 201 Created, +2   | 201, score=2 | ✅     |
| post_view 점수 기록    | targetUserId, type=... | 201 Created, +1   | 201, score=1 | ✅     |
| invalid type 거부      | type=invalid           | 422 Unprocessable | 422          | ✅     |
| self targeting 거부    | targetUserId=self      | 422 Unprocessable | 422          | ✅     |
| target not found       | nonexistent id         | 404 Not Found     | 404          | ✅     |
| unauthorized           | no token               | 401 Unauthorized  | 401          | ✅     |
| 점수 조회 (기존)       | GET /:id               | 200 OK, score=5   | 200, 5       | ✅     |
| 점수 조회 (없음)       | GET /:id (no rel)      | 200 OK, score=0   | 200, 0       | ✅     |
| 점수 누적              | 3x profile_view        | score=8 (5+3)     | 8            | ✅     |
| 자신의 관계 목록       | GET /                  | 200 OK, 1개       | 200, 1개     | ✅     |
| 다른 사용자 관계 목록  | GET /?userId=X         | 200 OK, 0개       | 200, 0개     | ✅     |
| 관계 없는 경우         | GET /                  | 200 OK, []        | 200, []      | ✅     |
| 존재하지 않는 사용자   | GET /?userId=invalid   | 404 Not Found     | 404          | ✅     |
| 목록 조회 unauthorized | GET / (no token)       | 401 Unauthorized  | 401          | ✅     |
| 점수 내림차순 정렬     | GET /                  | 정렬된 목록       | 정렬됨       | ✅     |

## Error Log

| Timestamp  | Error                        | Attempt | Resolution              |
| ---------- | ---------------------------- | ------- | ----------------------- |
| 2026-02-02 | params[:target_user_id] 없음 | 1       | params[:targetUserId]로 |

## 5-Question Reboot Check

작업 재개 시 이 질문들로 컨텍스트 복구:

| Question               | Answer                     |
| ---------------------- | -------------------------- |
| 1. 현재 어느 단계인가? | ✅ Phase 6 완료            |
| 2. 다음에 할 일은?     | 커밋 및 문서 정리          |
| 3. 목표는?             | 관계 목록 조회 API 추가 ✅ |
| 4. 지금까지 배운 것?   | See findings.md            |
| 5. 완료한 작업은?      | See above                  |
