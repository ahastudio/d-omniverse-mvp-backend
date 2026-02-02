# Project: 패스워드 변경

## Summary

로그인한 사용자가 기존 패스워드를 확인한 후 새 패스워드로 변경할 수 있는
API 엔드포인트를 구현한다. 기존 Authenticatable concern의 패스워드 검증
및 해싱 기능을 활용한다.

## Goal

PATCH `/users/{username}/password` 엔드포인트 구현 및 테스트 완료

## Current Phase

✅ 완료

## Phases

### Phase 1: Requirements & Discovery ✅

- [x] 요구사항 확인 (spec.md 작성)
- [x] 기존 코드베이스 탐색
- [x] Authenticatable concern 분석
- [x] 기존 인증 패턴 파악

### Phase 2: Planning & Structure ✅

- [x] 라우팅 설계
- [x] 컨트롤러 액션 설계
- [x] 응답 형식 정의

### Phase 3: Implementation ✅

- [x] 라우트 추가 (`/users/:username/password`)
- [x] 컨트롤러 액션 구현
- [x] 권한 검사 구현

### Phase 4: Testing & Verification ✅

- [x] 단위 테스트 작성
- [x] 통합 테스트 작성
- [x] 엣지 케이스 테스트

### Phase 5: Delivery ✅

- [x] 문서 업데이트
- [x] 커밋 완료

## Technical Context

### Stack

- Ruby on Rails (API-only mode)
- Argon2 (패스워드 해싱)
- JWT (인증)
- Minitest (테스트 프레임워크)

### Architecture

- RESTful API
- MVC 패턴 (Rails 기본)
- 기존 users 테이블 활용

### Key Decisions

| Decision                    | Rationale                                |
| --------------------------- | ---------------------------------------- |
| PATCH 메서드 사용           | 리소스 부분 업데이트 의미론적으로 적합   |
| 별도 passwords 컨트롤러     | 단일 책임 원칙, 패스워드 전용 로직 분리  |
| 기존 패스워드 필수 검증     | 보안 강화, 탈취된 토큰 악용 방지         |
| 422 Unprocessable Entity    | 검증 실패 표현에 적합                    |

## Project Structure

### Source Code

```text
app/
├── controllers/
│   └── passwords_controller.rb  (새로 생성)
├── models/
│   └── user.rb  (기존 활용)
│   └── concerns/
│       └── authenticatable.rb  (기존 활용)
config/
└── routes.rb  (수정)
test/
└── controllers/
    └── passwords_controller_test.rb  (새로 생성)
```

## Key Questions

1. 기존 패스워드 검증 로직이 Authenticatable에 있는가? ✅
2. 현재 User에 password= setter가 있는가? ✅
3. 다른 사용자 패스워드 변경 방지 로직은? → before_action으로 구현

## Decisions Made

| Decision                       | Rationale                            |
| ------------------------------ | ------------------------------------ |
| PasswordsController 생성       | 단일 책임 원칙, 명확한 역할 분리     |
| PATCH 메서드 사용              | RESTful 규칙, 부분 업데이트          |
| camelCase 파라미터 받기        | 기존 API 컨벤션 따름                 |
| before_action으로 권한 검사    | 기존 패턴 따름, 로직 분리            |

## Errors Encountered

| Error | Attempt | Resolution |
| ----- | ------- | ---------- |
| -     | -       | -          |

## Notes

- Authenticatable concern의 authenticate 메서드 활용
- 패스워드 복잡도 검증은 별도 이슈로 분리
- 패스워드 변경 후 토큰 재발급은 현재 범위 외
