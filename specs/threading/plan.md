# Threading Feature Plan

## Goal

D-Omniverse에 트위터 스타일의 스레드 기능을 추가하여 사용자들이 답글, 인용,
리포스트를 통해 글을 서로 연결하고 대화할 수 있게 한다.

## Current Phase

⏸️ Phase 1 - 데이터베이스 스키마 확장

## Phases

### Phase 1: 데이터베이스 스키마 확장 ⏸️

- [ ] 마이그레이션 파일 생성
- [ ] `parent_id` 컬럼 추가 (답글용)
- [ ] `quoted_post_id` 컬럼 추가 (인용용)
- [ ] `reposted_post_id` 컬럼 추가 (리포스트용)
- [ ] `content` NOT NULL 제약 제거
- [ ] 카운터 컬럼 추가 (reply_count, quote_count, repost_count)
- [ ] 마이그레이션 실행 및 검증

### Phase 2: 모델 관계 및 유효성 검증 ⏸️

- [ ] 자기 참조 관계 설정 (parent, replies)
- [ ] quoted_post, reposted_post 관계 설정
- [ ] content 유효성 검증 조건부 변경
- [ ] 자기 참조 방지 검증
- [ ] 글 유형 판별 메서드 (reply?, quote?, repost?)
- [ ] 모델 테스트 작성

### Phase 3: 글 작성 API 확장 ⏸️

- [ ] parentId, quotedPostId, repostedPostId 파라미터 추가
- [ ] 참조 대상 글 존재 여부 검증
- [ ] 리포스트 시 content 비어있음 검증
- [ ] 컨트롤러 테스트 작성

### Phase 4: 글 조회 API 확장 ⏸️

- [ ] `show` 액션 추가
- [ ] 응답에 관련 글 정보 포함
- [ ] type 필터 확장 (reply, quote, repost)
- [ ] 컨트롤러 테스트 작성

### Phase 5: 스레드 전용 API ⏸️

- [ ] `GET /posts/:id/replies` 구현
- [ ] `GET /posts/:id/thread` 구현
- [ ] 페이지네이션 지원
- [ ] 컨트롤러 테스트 작성

## Key Questions

| 질문 | 답변 |
|------|------|
| 삭제된 글의 답글은 어떻게 처리? | Soft Delete로 "삭제된 글입니다" 표시 |
| 동일 글 중복 리포스트 허용? | 불허 (스팸 방지) |
| 스레드 깊이 제한? | 100단계 |

## Decisions Made

| 결정 사항 | 선택 | 이유 |
|-----------|------|------|
| 관계 구현 방식 | 자기 참조 | 단순하고 쿼리 용이 |
| content NULL | 허용 | 리포스트 지원 |
| 삭제 정책 | Soft Delete | UX 고려 |
| 카운터 | 캐싱 적용 | 조회 성능 |

## Errors Encountered

| 날짜 | 오류 | 해결책 |
|------|------|--------|
| - | - | - |

## Notes

- 기존 데이터에는 영향 없음 (새 컬럼 모두 NULL 허용)
- 외래 키 제약은 미적용 (Soft Delete 호환성)
