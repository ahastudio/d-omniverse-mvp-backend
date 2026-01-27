# Project: Threading Feature

## Goal

D-Omniverse에 스레드 기능을 추가하여 글들이 `parent_id`로 서로 연결되어
대화 형태의 스레드를 형성할 수 있게 한다.

## Current Phase

⏸️ Phase 1: Requirements & Discovery

## Phases

### Phase 1: Requirements & Discovery ⏸️

- [x] 사용자 요구사항 확인
- [x] 기존 코드베이스 탐색
- [x] 제약사항 문서화

### Phase 2: Planning & Structure ⏸️

- [ ] 마이그레이션 설계
- [ ] 모델 관계 설계
- [ ] API 엔드포인트 설계

### Phase 3: Implementation ⏸️

- [ ] 마이그레이션 파일 생성 (parent_id, replies_count)
- [ ] Post 모델에 자기 참조 관계 추가
- [ ] PostsController에 parentId 파라미터 추가
- [ ] show 액션 추가
- [ ] replies, thread 액션 추가

### Phase 4: Testing & Verification ⏸️

- [ ] 모델 테스트 작성
- [ ] 컨트롤러 테스트 작성
- [ ] 테스트 실행 및 결과 확인

### Phase 5: Delivery ⏸️

- [ ] 최종 리뷰
- [ ] PR 생성

## Key Questions

1. 부모 글 삭제 시 자식 글 처리 방법?
2. 스레드 깊이 제한 필요 여부?

## Decisions Made

| Decision                | Rationale              |
| ----------------------- | ---------------------- |
| parent_id 자기 참조     | 단순하고 직관적        |
| Soft Delete             | 스레드 구조 유지       |
| 자식 글 개수 캐시       | 조회 성능 최적화       |

## Errors Encountered

| Error   | Attempt | Resolution |
| ------- | ------- | ---------- |
| -       | -       | -          |

## Notes

- 인용/리포스트는 범위에서 제외됨
- 기존 데이터에는 영향 없음 (parent_id는 NULL 허용)
