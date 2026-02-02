# Project: Username 중복 검사

## Summary

사용자가 원하는 username의 사용 가능 여부를 확인할 수 있는 공개 API
엔드포인트를 구현한다. 기존 User 모델의 username 조회를 통해 중복 여부를
판단하고 적절한 HTTP 상태 코드로 응답한다.

## Goal

GET `/username-seats/{username}` 엔드포인트 구현 및 테스트 완료

## Current Phase

✅ 완료

## Phases

### Phase 1: Requirements & Discovery ✅

- [x] 요구사항 확인 (spec.md 작성)
- [x] 기존 코드베이스 탐색
- [x] User 모델의 username 필드 확인
- [x] 기존 컨트롤러 구조 파악

### Phase 2: Planning & Structure ✅

- [x] 라우팅 설계
- [x] 컨트롤러 액션 설계
- [x] 응답 형식 정의

### Phase 3: Implementation ✅

- [x] 라우트 추가 (`/username-seats/:username`)
- [x] 컨트롤러 및 액션 구현
- [x] 에러 처리 구현

### Phase 4: Testing & Verification ✅

- [x] 단위 테스트 작성
- [x] 통합 테스트 작성
- [x] 엣지 케이스 테스트

### Phase 5: Delivery ✅

- [x] 문서 업데이트 (HTTPie 테스트 예시 추가)
- [x] 커밋 완료

## Technical Context

### Stack

- Ruby on Rails (API-only mode)
- SQLite (development/test), PostgreSQL (production 가능성)
- Minitest (테스트 프레임워크)

### Architecture

- RESTful API
- MVC 패턴 (Rails 기본)
- 기존 users 테이블 활용

### Key Decisions

| Decision                  | Rationale                                  |
| ------------------------- | ------------------------------------------ |
| GET 메서드 사용           | 리소스 조회 의미론적으로 적합              |
| 409 Conflict 사용         | RFC 7231 표준, 리소스 충돌 표현에 적합     |
| 인증 불필요               | 공개 API, 회원가입 전 사용 가능해야 함     |
| 별도 컨트롤러 생성 가능성 | UsernameSeatController vs UsersController  |

## Project Structure

### Source Code

```text
app/
├── controllers/
│   └── username_seats_controller.rb  (새로 생성)
├── models/
│   └── user.rb  (기존 활용)
config/
└── routes.rb  (수정)
test/
└── controllers/
    └── username_seats_controller_test.rb  (새로 생성)
```

## Key Questions

1. User 모델에 username 필드가 존재하는가?
2. username에 unique 제약 조건이 있는가?
3. username 대소문자 구분 정책은?

## Decisions Made

| Decision                       | Rationale                            |
| ------------------------------ | ------------------------------------ |
| 별도 컨트롤러 생성             | 단일 책임 원칙, 명확한 엔드포인트    |
| camelCase 파라미터 받기        | 기존 API 컨벤션 따름                 |
| 간단한 JSON 응답 (상태 코드만) | 요구사항이 상태 코드에만 집중        |
| before_action 최소화           | 단순 조회 API, 복잡한 필터링 불필요  |

## Errors Encountered

| Error | Attempt | Resolution |
| ----- | ------- | ---------- |
| -     | -       | -          |

## Notes

- username 유효성 검증 규칙은 별도 이슈로 분리 고려
- 대소문자 구분 정책은 User 모델 조사 후 결정
- 응답 본문에 추가 정보(예: 사용 가능 여부 메시지)는 요구사항에
  없으므로 최소한으로 유지
