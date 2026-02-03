# Project: 무한 스크롤 API

## Goal

프론트엔드 무한 스크롤 지원을 위한 GET /posts API 페이지네이션 구현.

## Current Phase

✅ Phase 2: 구현

## Phases

### Phase 1: 스펙 작성 ✅

- [x] 기존 API 응답 형식 분석
- [x] 페이지네이션 방식 결정 (opaque cursor 패턴)
- [x] spec.md 작성

### Phase 2: 구현 ✅

- [x] 컨트롤러 테스트 작성
- [x] 컨트롤러 구현 (offset, limit, paginated_response)
- [x] username 파라미터 구현
- [x] 테스트 통과 확인 (17개)

## Key Questions

1. 추천 시스템 정렬과 페이지네이션을 어떻게 조합할 것인가?
   → Opaque cursor 패턴으로 해결 (내부적으로 offset 사용)
2. username 파라미터 구현 시점은?
   → 완료 (프로필 페이지는 최신순 정렬)

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Opaque cursor 패턴 | 추천 정렬에서 lastPostId 방식 불가 |
| 내부적으로 offset 사용 | 점수 기반 정렬과 호환 |
| hasMore 필드 제거 | nextCursor가 null이면 마지막 페이지 |
| limit 최대 100 | 서버 부하 방지 |

## Errors Encountered

| Error | Attempt | Resolution |
|-------|---------|------------|
| N/A | - | - |

## Notes

- 새 게시물 추가 시 중복 가능 (새로고침으로 해결)
- cursor 형식이 바뀌어도 프론트엔드 변경 불필요
