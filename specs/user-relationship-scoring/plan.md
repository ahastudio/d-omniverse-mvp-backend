# Project: 사용자 관계 점수

## Summary

사용자 간 interaction(프로필 방문, 반응, 게시물 보기)을 점수로 기록하여
사용자 관계 강도를 측정하는 기능을 구현한다. 이 점수는 향후 추천 시스템
등에 활용될 수 있다.

## Goal

POST `/user-relationships` 및 GET
`/user-relationships/:target_user_id` API 구현 완료

## Current Phase

✅ 완료

## Phases

### Phase 1: Requirements & Discovery ✅

- [x] 요구사항 확인 (spec.md 작성)
- [x] 기존 코드베이스 탐색
- [x] User 모델 구조 확인
- [x] 기존 컨트롤러 패턴 파악

### Phase 2: Planning & Structure ✅

- [x] 데이터베이스 스키마 설계
- [x] 라우팅 설계
- [x] 컨트롤러 액션 설계
- [x] 점수 계산 로직 설계

### Phase 3: Implementation ✅

- [x] 마이그레이션 생성 및 실행
- [x] UserRelationship 모델 구현
- [x] UserRelationshipsController 구현
- [x] 라우트 추가

### Phase 4: Testing & Verification ✅

- [x] 단위 테스트 작성
- [x] 통합 테스트 작성
- [x] 엣지 케이스 테스트

### Phase 5: Delivery ✅

- [x] 문서 업데이트
- [x] 커밋 및 푸시

## Technical Context

### Stack

- Ruby on Rails (API-only mode)
- SQLite (development/test), PostgreSQL (production)
- Minitest (테스트 프레임워크)

### Architecture

- RESTful API
- MVC 패턴 (Rails 기본)
- 새로운 user_relationships 테이블 생성

### Key Decisions

| Decision            | Rationale                               |
| ------------------- | --------------------------------------- |
| 단일 테이블 설계    | 단순한 점수 누적, 복잡한 로그 불필요    |
| 복합 unique 인덱스  | (user_id, target_user_id) 중복 방지     |
| 점수 누적 방식      | 매 interaction마다 기존 점수에 합산     |
| type별 점수 차등    | profile_view: 1, reaction: 2, post_view |
| 양방향 별도 관리    | A→B와 B→A는 독립적인 관계               |

## Project Structure

### Source Code

```text
app/
├── controllers/
│   └── user_relationships_controller.rb  (새로 생성)
├── models/
│   └── user_relationship.rb  (새로 생성)
config/
└── routes.rb  (수정)
db/
└── migrate/
    └── 20260202100000_create_user_relationships.rb
        (새로 생성)
test/
├── controllers/
│   └── user_relationships_controller_test.rb  (새로 생성)
└── fixtures/
    └── user_relationships.yml  (새로 생성)
```

## Key Questions

1. ~~User 모델에 has_many 관계 추가 필요?~~ → 선택적, 필요시 추가
2. interaction 로그를 별도 테이블로 저장? → Out of scope

## Decisions Made

| Decision                   | Rationale                           |
| -------------------------- | ----------------------------------- |
| UserRelationship 모델 생성 | 관계 점수 전용 테이블로 관심사 분리 |
| 점수 0 기본값              | 관계가 없으면 0점으로 간주          |
| camelCase API 파라미터     | 기존 API 컨벤션 따름                |

## Errors Encountered

| Error            | Attempt | Resolution                   |
| ---------------- | ------- | ---------------------------- |
| params 키 불일치 | 1       | params[:targetUserId]로 수정 |

## Notes

- 향후 점수 감쇠 로직 추가 가능 (별도 이슈)
- interaction 로그 저장은 별도 기능으로 분리 고려
