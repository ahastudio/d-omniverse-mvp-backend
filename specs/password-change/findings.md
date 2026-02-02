# Findings & Decisions

> **기술적 발견, 중요한 결정이 있을 때마다 이 파일을 즉시
> 업데이트하세요.**

## Requirements

- [x] PATCH `/users/{username}/password` 엔드포인트 제공
- [x] 기존 패스워드 검증 후 변경
- [x] 잘못된 기존 패스워드 시 422 응답
- [x] 인증 필수 (401 응답)
- [x] 본인만 변경 가능 (403 응답)

## Research Findings

### Authenticatable Concern 분석

**파일**: `app/models/concerns/authenticatable.rb`

주요 메서드:
- `password=` - 패스워드 설정 및 Argon2 해싱
- `authenticate(password)` - 패스워드 검증 (boolean 반환)
- `authenticate!(password)` - 패스워드 검증 (실패 시 예외)

### 기존 인증 패턴

**파일**: `app/controllers/application_controller.rb`

주요 메서드:
- `login_required` - before_action용 인증 필터
- `current_user` - JWT에서 현재 사용자 추출
- `logged_in?` - 로그인 상태 확인

### 기존 패턴

- API 파라미터: camelCase로 받고 `transform_keys(&:underscore)`로
  snake_case 변환
- 에러 처리: `save!` + `rescue` 패턴 사용
- 컨트롤러: `before_action`으로 로직 분리
- 응답: JSON 형식 (Rails 기본 render)
- `else` 사용 금지 (early return 선호)

## Technical Decisions

| Decision | Rationale |
| -------- | --------- |
| PasswordsController 생성 | 단일 책임 원칙, 패스워드 전용 로직 분리 |
| PATCH 메서드 사용 | RESTful 규칙, 리소스 부분 업데이트 |
| `authenticate` 메서드 활용 | 기존 Authenticatable concern 재사용 |
| before_action으로 권한 검사 | 기존 패턴 따름, 로직 분리 |
| 422 상태 코드 | 검증 실패 표현에 적합 |

## Issues Encountered

(아직 없음)

## Resources

### 문서

- [Rails Routing Guide](
  https://guides.rubyonrails.org/routing.html)
- [HTTP Status Codes](
  https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)

### 코드 참조

- Authenticatable Concern: `app/models/concerns/authenticatable.rb`
- Application Controller: `app/controllers/application_controller.rb`
- User Model: `app/models/user.rb`
- Routes: `config/routes.rb`

### API 엔드포인트

- 추가할 엔드포인트: PATCH `/users/:username/password`

## Learnings

### 2026-02-02: 기존 코드 분석

- Authenticatable concern에 패스워드 검증/해싱 로직 존재
- `authenticate(password)` 메서드로 기존 패스워드 검증 가능
- `password=` setter로 새 패스워드 설정 시 자동 해싱
- JWT 기반 인증으로 current_user 접근 가능

## Next Steps

1. routes.rb에 라우트 추가
2. PasswordsController 생성
3. 테스트 작성 및 실행
