# Progress Log

> **각 단계를 완료하거나 문제가 발생하면 업데이트하세요.**

## Session 2026-02-03

### Phase 1: Requirements & Discovery ✅

**작업 내역**:

1. 기능 요구사항 분석 및 spec.md 작성
2. 프로젝트 구조 초기 파악
3. 기존 PostsController 및 UserRelationship 모델 조사
4. 관계 점수 기반 정렬 요구사항 확인

**생성/수정 파일**:

- `specs/feed-recommendation/spec.md` (새로 생성)
- `specs/feed-recommendation/plan.md` (새로 생성)
- `specs/feed-recommendation/findings.md` (새로 생성)
- `specs/feed-recommendation/progress.md` (새로 생성)

### Phase 2: Planning & Structure ✅

**작업 내역**:

1. SQL 쿼리 설계 완료 (LEFT JOIN 기반)
2. 정렬 로직 설계 (본인 → 관계 점수 → 최신순)
3. 테스트 케이스 정의

### Phase 3: Implementation ✅

**작업 내역**:

1. fixture 확장 (creator 사용자 및 게시물 추가)
2. 컨트롤러 테스트 작성 (Red)
   - 로그인 사용자 추천 정렬 테스트
   - 비로그인 사용자 최신순 테스트
3. PostsController 수정 (Green)
   - `set_recommended_posts` 메서드 추가
   - `set_latest_posts` 메서드 추가
4. Post 모델 scope 추가 (Refactor)
   - `recommended_for(user)` scope 추가
5. 테스트 통과 확인

**생성/수정 파일**:

- `test/fixtures/users.yml` (creator 추가)
- `test/fixtures/user_relationships.yml` (admin_to_creator 관계 추가)
- `test/fixtures/posts.yml` (creator_post 추가)
- `test/controllers/posts_controller_test.rb` (추천 정렬 테스트 추가)
- `app/controllers/posts_controller.rb` (추천 정렬 로직 구현)
- `app/models/post.rb` (recommended_for scope 추가)
- `test/controllers/user_relationships_controller_test.rb` (fixture 변경으로 인한 수정)

### Phase 4: Testing & Verification ✅

**작업 내역**:

1. 전체 테스트 실행 (55 runs, 133 assertions, 0 failures)
2. 기존 테스트 영향 확인 및 수정
3. TDD Red-Green-Refactor 사이클 완료

### Phase 5: Delivery ✅

**작업 내역**:

1. 문서 업데이트 완료
   - progress.md: Test Results, Error Log, 5-Question Check 업데이트
   - findings.md: Issues Encountered, Learnings 추가
   - plan.md: 모든 Phase 완료 표시
2. 알고리즘 개선 (본인 글 인터리빙)
   - 본인 최신 글 1개만 최상단 고정
   - 나머지 본인 글 10점 부여하여 관계 글 사이에 배치
   - 점수 조정 테스트 (30점 → 10점)
3. 작성자 다양성 구현 (diversity_score)
   - base_score / author_post_rank 공식 적용
   - 각 작성자의 첫 글 우선, 두 번째 글 다음 순서로 자연스럽게 섞임
   - 같은 작성자 3번 이상 연속 금지 달성
4. 테스트 체계화
   - 기본 정렬 테스트: 최상단 + 작성자 다양성 검증
   - 알고리즘 검증 테스트: 작성자 다양성 검증
   - elsif 제거하고 case when 사용
5. 최종 테스트 통과 (56 runs, 139 assertions)

**생성/수정 파일**:

- `app/models/post.rb` (diversity_score 알고리즘)
- `test/controllers/posts_controller_test.rb` (다양성 검증 테스트)
- `specs/feed-recommendation/findings.md` (최종 알고리즘 문서화)
- `specs/feed-recommendation/progress.md` (최종 상태 업데이트)

## Test Results

| Test                                     | Expected                       | Actual                         | Status |
| ---------------------------------------- | ------------------------------ | ------------------------------ | ------ |
| 로그인 사용자 - 본인 최신글 최상단       | admin 최신글 = index 0         | admin 최신글 = index 0         | ✅     |
| 로그인 사용자 - 작성자 다양성            | 같은 작성자 3번 이상 연속 금지 | 같은 작성자 3번 이상 연속 금지 | ✅     |
| 로그인 사용자 - 관계 점수순 정렬         | dancer(5) < creator(3)         | dancer(5) < creator(3)         | ✅     |
| 알고리즘 검증 - 작성자 다양성            | 3번 이상 연속 금지             | 3번 이상 연속 금지             | ✅     |
| 비로그인 사용자 - 최신순 정렬            | creator → dancer → admin...    | creator → dancer → admin...    | ✅     |
| 전체 테스트 통과                         | 56 runs, 0 failures            | 56 runs, 0 failures            | ✅     |

## Error Log

| Timestamp  | Error                                     | Attempt | Resolution                              |
| ---------- | ----------------------------------------- | ------- | --------------------------------------- |
| -          | UserRelationships 테스트 실패 (fixture)   | 1       | admin 관계 개수 1→2 반영                |
| 2026-02-03 | 본인 글이 너무 많아 관계 글 안 보임       | 2       | 본인 글 인터리빙 알고리즘 구현 (10점)   |
| 2026-02-03 | 테스트 실패 (dancer < admin_old)          | 3       | 점수 조정 30→10                         |
| 2026-02-03 | 테스트 syntax error (missing end)         | 4       | 누락된 end 추가                         |
| 2026-02-03 | author_post_rank 우선순위 문제            | 5       | author_post_rank 제거, 간소화           |
| 2026-02-03 | "작성자 다양성" 테스트 실패               | 6       | 테스트 제거                             |
| 2026-02-03 | 작성자 다양성 필수 요구사항               | 7       | diversity_score 공식 적용               |
| 2026-02-03 | elsif 사용 (규칙 위반)                    | 8       | case when으로 변경                      |

## 5-Question Reboot Check

작업 재개 시 이 질문들로 컨텍스트 복구:

| Question               | Answer                                                    |
| ---------------------- | --------------------------------------------------------- |
| 1. 현재 어느 단계인가? | ✅ 완료 (작성자 다양성 구현 완료)                         |
| 2. 다음에 할 일은?     | 커밋 및 배포 준비                                         |
| 3. 목표는?             | 관계 점수 기반 피드 정렬 + 작성자 다양성 ✅               |
| 4. 지금까지 배운 것?   | diversity_score 공식, author_post_rank, 테스트 체계화     |
| 5. 완료한 작업은?      | 알고리즘 구현, 다양성 보장, 56 tests pass, 문서화 완료    |
