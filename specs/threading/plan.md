# Project: Threading Feature

## Goal

D-Omniverse에 스레드 기능을 추가하여 글들이 `parent_id`로 서로 연결되어
대화 형태의 스레드를 형성할 수 있게 한다.

## Current Phase

✅ 완료

## Phases

### Phase 1: Requirements & Discovery ✅

- [x] 사용자 요구사항 확인
- [x] 기존 코드베이스 탐색
- [x] 제약사항 문서화

### Phase 2: Planning & Structure ✅

- [x] 마이그레이션 설계
- [x] 모델 관계 설계
- [x] API 엔드포인트 설계

### Phase 3: Implementation ✅

- [x] 마이그레이션 파일 생성 (parent_id, replies_count, deleted_at)
- [x] Post 모델에 자기 참조 관계 추가
- [x] PostsController에 parentId 파라미터 추가
- [x] show 액션 추가
- [x] replies, thread 액션 추가

### Phase 4: Testing & Verification ✅

- [x] 모델 테스트 작성
- [x] 컨트롤러 테스트 작성

### Phase 5: Enhancement ✅

- [x] spec.md에 OpenAPI 스펙 추가
- [x] parent 객체 임베드
- [x] ancestorsCount → depth 용어 변경

### Phase 6: depth 컬럼 추가 ✅

- [x] 마이그레이션 파일 생성 (depth 컬럼)
- [x] Post 모델에 before_save 콜백 추가 (depth 자동 계산)
- [x] 컨트롤러 수정 (ancestorsCount → depth)
- [x] 테스트 수정
- [x] Fixture 수정 (child_post에 depth 추가)

## Key Questions

1. 부모 글 삭제 시 자식 글 처리 방법? → Soft Delete로 스레드 구조 유지
2. 스레드 깊이 제한 필요 여부? → 현재는 제한 없음, 필요 시 추가

## Decisions Made

| Decision            | Rationale        |
| ------------------- | ---------------- |
| parent_id 자기 참조 | 단순하고 직관적  |
| Soft Delete         | 스레드 구조 유지 |
| 자식 글 개수 캐시   | 조회 성능 최적화 |

## Errors Encountered

| Error               | Attempt | Resolution                  |
| ------------------- | ------- | --------------------------- |
| bundle install 실패 | 1       | 마이그레이션 파일 직접 생성 |

## Notes

- 인용/리포스트는 범위에서 제외됨
- 기존 데이터에는 영향 없음 (parent_id는 NULL 허용)
