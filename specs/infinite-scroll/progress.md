# Progress Log

> **각 단계를 완료하거나 문제가 발생하면 업데이트하세요.**

## Session 2026-02-03

### Phase 1: 스펙 작성 ✅

**작업 내역**:

1. 페이지네이션 방식 논의 (lastPostId vs offset vs opaque cursor)
2. opaque cursor 패턴 채택 결정
3. hasMore 필드 제거 (nextCursor null로 판단)
4. spec.md 작성 완료

**생성/수정 파일**:

- specs/infinite-scroll/spec.md (새로 생성)

### Phase 2: 구현 ✅

**작업 내역**:

1. username 파라미터 테스트 작성 (Red)
2. filter_by_username 메서드 구현 (Green)
3. 전체 테스트 통과 확인 (17개)
4. 코드 정리 (render에서 불필요한 status: :ok 제거)

**생성/수정 파일**:

- app/controllers/posts_controller.rb (수정)
- test/controllers/posts_controller_test.rb (수정)

## Test Results

| Test                     | Input               | Expected            | Actual       | Status |
|--------------------------|---------------------|---------------------|--------------|--------|
| profile page             | username=dancer     | dancer 게시물만     | dancer만     | ✅     |
| profile with pagination  | username + cursor   | 페이지네이션 동작   | 정상 동작    | ✅     |
| response format          | GET /posts          | posts, nextCursor   | 존재         | ✅     |
| pagination limit         | limit=3             | 3개 반환            | 3개          | ✅     |
| pagination cursor        | cursor 사용         | 중복 없음           | 중복 없음    | ✅     |

## Error Log

| Timestamp | Error | Attempt | Resolution |
|-----------|-------|---------|------------|
| N/A       | -     | -       | -          |

## 5-Question Reboot Check

| Question                | Answer                                        |
|-------------------------|-----------------------------------------------|
| 1. 현재 어느 단계인가?  | Phase 2: 구현 완료                            |
| 2. 다음에 할 일은?      | 없음 (프로젝트 완료)                          |
| 3. 목표는?              | GET /posts 무한 스크롤 페이지네이션           |
| 4. 지금까지 배운 것?    | Opaque cursor 패턴으로 추천+페이지네이션 해결 |
| 5. 완료한 작업은?       | 스펙 작성, 페이지네이션, username 필터        |
