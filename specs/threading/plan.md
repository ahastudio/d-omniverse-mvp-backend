# Threading Feature Plan

## Goal

D-Omniverse에 스레드 기능을 추가하여 글들이 `parent_id`로 서로 연결되어
대화 형태의 스레드를 형성할 수 있게 한다.

## Current Phase

⏸️ Phase 1 - 데이터베이스 스키마 확장

## Phases

### Phase 1: 데이터베이스 스키마 확장 ⏸️

- [ ] 마이그레이션 파일 생성
- [ ] `parent_id` 컬럼 추가 (string, null: true, index: true)
- [ ] `replies_count` 컬럼 추가 (카운터 캐시용)
- [ ] 마이그레이션 실행 및 검증

### Phase 2: 모델 관계 설정 ⏸️

- [ ] 자기 참조 관계 설정 (parent, replies)
- [ ] counter_cache 설정
- [ ] 자기 참조 방지 유효성 검증
- [ ] 모델 테스트 작성

### Phase 3: 글 작성 API 확장 ⏸️

- [ ] parentId 파라미터 추가
- [ ] 부모 글 존재 여부 검증
- [ ] 컨트롤러 테스트 작성

### Phase 4: 글 조회 API 확장 ⏸️

- [ ] `show` 액션 추가
- [ ] 응답에 parentId, replyCount 포함
- [ ] 라우트 설정
- [ ] 컨트롤러 테스트 작성

### Phase 5: 스레드 전용 API ⏸️

- [ ] `GET /posts/:id/replies` 구현
- [ ] `GET /posts/:id/thread` 구현 (ancestors + replies)
- [ ] 페이지네이션 지원
- [ ] 컨트롤러 테스트 작성

## Key Questions

| 질문 | 답변 |
|------|------|
| 부모 글 삭제 시 처리? | Nullify (자식 글이 루트가 됨) |
| 스레드 깊이 제한? | 100단계 |

## Decisions Made

| 결정 사항 | 선택 | 이유 |
|-----------|------|------|
| 관계 구현 방식 | 자기 참조 (parent_id) | 단순하고 직관적 |
| 삭제 정책 | Nullify | 자식 글 보존 |
| 카운터 | counter_cache | 조회 성능 |

## Errors Encountered

| 날짜 | 오류 | 해결책 |
|------|------|--------|
| - | - | - |

## Notes

- 기존 데이터에는 영향 없음 (parent_id는 NULL 허용)
- 인용/리포스트는 범위에서 제외됨
