# Findings & Decisions

> **기술적 발견, 중요한 결정이 있을 때마다 이 파일을 즉시 업데이트하세요.**

## Requirements

- [x] PATCH `/users/{username}/password` 엔드포인트 제공
- [x] 기존 패스워드 검증 후 변경
- [x] 잘못된 기존 패스워드 시 422 응답
- [x] 인증 필수 (401 응답)
- [x] 본인만 변경 가능 (403 응답)

## Research Findings

### 코드베이스 구조

- 백엔드: Ruby on Rails (API-only)
- 컨트롤러: `app/controllers/` 디렉토리
- 모델: `app/models/` 디렉토리
- 테스트: Minitest 사용 (`test/` 디렉토리)

### 기존 패턴

- API 파라미터: camelCase로 받고 `transform_keys(&:underscore)`로 변환
- 에러 처리: `save!` + `rescue` 패턴 사용
- 컨트롤러: `before_action`으로 로직 분리
- 응답: JSON 형식
- `else` 사용 금지 (early return 선호)

## Resources

### 문서

- [Rails Routing Guide](https://guides.rubyonrails.org/routing.html)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)

### 코드 참조

- Authenticatable Concern: `app/models/concerns/authenticatable.rb`
- Application Controller: `app/controllers/application_controller.rb`
- User Model: `app/models/user.rb`

### API 엔드포인트

- PATCH `/users/:username/password`

## Technical Decisions

| Decision                    | Rationale                          |
| --------------------------- | ---------------------------------- |
| PasswordsController 생성    | 단일 책임 원칙, 패스워드 전용 분리 |
| PATCH 메서드 사용           | RESTful 규칙, 부분 업데이트        |
| `authenticate` 메서드 활용  | 기존 Authenticatable concern 재사용 |
| before_action으로 권한 검사 | 기존 패턴 따름, 로직 분리          |
| 422 상태 코드               | 검증 실패 표현에 적합              |

## Issues Encountered

(발생한 이슈 없음)

## Learnings

### Authenticatable Concern 분석

- `password=` setter: 패스워드 설정 및 Argon2 해싱
- `authenticate(password)`: 패스워드 검증 (boolean 반환)
- `authenticate!(password)`: 패스워드 검증 (실패 시 예외)

### 인증 시스템

- JWT 기반 인증으로 `current_user` 접근 가능
- `login_required` before_action으로 인증 필터링
