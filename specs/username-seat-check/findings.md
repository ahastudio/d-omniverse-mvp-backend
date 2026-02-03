# Findings & Decisions

> **기술적 발견, 중요한 결정이 있을 때마다 이 파일을 즉시 업데이트하세요.**

## Requirements

- [x] GET `/username-seats/{username}` 엔드포인트 제공
- [x] 중복 시 409 Conflict 응답
- [x] 사용 가능 시 200 OK 응답
- [ ] Username 유효성 검증 (추가 확인 필요)

## Research Findings

### 코드베이스 구조

- 백엔드: Ruby on Rails (API-only)
- 컨트롤러: `app/controllers/` 디렉토리
  - application_controller.rb
  - posts_controller.rb
  - sessions_controller.rb
  - users_controller.rb
- 모델: `app/models/` 디렉토리
  - user.rb
  - post.rb
  - concerns/authenticatable.rb
- 테스트: Minitest 사용 (`test/` 디렉토리)
- 라우팅: `config/routes.rb`

### 기존 패턴

- API 파라미터: camelCase로 받고 `transform_keys(&:underscore)`로 snake_case
  변환
- 에러 처리: `save!` + `rescue` 패턴 사용
- 컨트롤러: `before_action`으로 로직 분리
- 응답: JSON 형식 (Rails 기본 render)
- `else` 사용 금지 (early return 선호)

### User 모델 조사 결과

- [x] username 필드 존재 확인 ✅
- [x] unique 제약 조건 확인 ✅ (DB 레벨 + 모델 validation)
- [x] 대소문자 구분 정책: **자동으로 소문자 변환** (`normalize_username`)
- [x] username 길이 제한: **3자 이상 100자 이하**
- [x] username 형식: **소문자 영문으로 시작, 영문+숫자만 허용**
      (`/\A[a-z][a-z0-9]*\z/`)

## Technical Decisions

| Decision                           | Rationale                                        |
| ---------------------------------- | ------------------------------------------------ |
| UsernameSeatController 생성        | 단일 책임 원칙, seats 복수형 리소스 개념         |
| UsernameSeatsController 명명       | RESTful 규칙, "seats"를 리소스로 간주            |
| `head :ok` / `head :conflict` 사용 | 응답 본문 불필요, HTTP 상태 코드만으로 충분      |
| 인증 불필요                        | 공개 API, 회원가입 전 호출 가능해야 함           |
| 단일 액션 컨트롤러                 | show 액션만 구현 (index, create 등 불필요)       |
| 파라미터명 `username`              | URL path parameter, 별도 변환 불필요             |
| 단순 존재 여부 조회                | `User.exists?(username: params[:username])` 사용 |

## Issues Encountered

### 1. 대소문자 변환 불일치

**문제**: 대문자 username으로 조회 시 중복 감지 실패

**원인**: User 모델의 normalize_username은 저장 시에만 동작

**해결**: 컨트롤러에서도 동일한 정규화 적용 (`username.to_s.strip.downcase`)

**결과**: 해결됨

## Resources

### 문서

- [Rails Routing Guide](https://guides.rubyonrails.org/routing.html)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)

### 코드 참조

- Users Controller: `app/controllers/users_controller.rb`
- User Model: `app/models/user.rb`
- Routes: `config/routes.rb`
- API 파라미터 패턴: `users_controller.rb` 참고

### API 엔드포인트

- 추가할 엔드포인트: GET `/username-seats/:username`

## Learnings

### 2026-01-28: 프로젝트 구조 파악

- Rails API-only 모드 사용
- 기존 컨트롤러 4개: application, posts, sessions, users
- 모델 2개: User, Post
- Minitest 기반 테스트
- Concerns 패턴 사용 (Authenticatable, VideoProcessable)

### 다음 단계

1. User 모델 확인하여 username 필드 존재 여부 파악
2. 마이그레이션 파일 확인하여 제약 조건 파악
3. 기존 users_controller.rb의 파라미터 처리 패턴 상세 확인
4. 테스트 파일 구조 확인 (users_controller_test.rb 참고)
