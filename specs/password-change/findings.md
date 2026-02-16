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

| Decision                    | Rationale                           |
| --------------------------- | ----------------------------------- |
| PasswordsController 생성    | 단일 책임 원칙, 패스워드 전용 분리  |
| PATCH 메서드 사용           | RESTful 규칙, 부분 업데이트         |
| `authenticate` 메서드 활용  | 기존 Authenticatable concern 재사용 |
| before_action으로 권한 검사 | 기존 패턴 따름, 로직 분리           |
| 422 상태 코드               | 검증 실패 표현에 적합               |

## Issues Encountered

### 1. 빈 패스워드 검증 실패 (2026-02-16)

**문제**:

빈 문자열을 새 패스워드로 설정 시 422 응답이 나와야 하는데 200 응답이 발생

**원인**:

Authenticatable concern의 `password=` setter에서 빈 문자열을 받으면
`password_digest`를 설정하지 않고 early return하여 기존 값이 유지됨.
이로 인해 `validates :password_digest, presence: true`가 작동하지 않음

**해결**:

```ruby
# Before
def password=(unencrypted_password)
  @password = unencrypted_password
  return if unencrypted_password.blank?
  self.password_digest = hash_password(unencrypted_password)
end

# After
def password=(unencrypted_password)
  @password = unencrypted_password
  if unencrypted_password.blank?
    self.password_digest = nil
    return
  end
  self.password_digest = hash_password(unencrypted_password)
end
```

**결과**:

테스트 통과 (빈 패스워드 → 422 응답)

## Learnings

### Authenticatable Concern 분석 (2026-02-02)

- `password=` setter: 패스워드 설정 및 Argon2 해싱
- `authenticate(password)`: 패스워드 검증 (boolean 반환)
- `authenticate!(password)`: 패스워드 검증 (실패 시 예외)

### 인증 시스템 (2026-02-02)

- JWT 기반 인증으로 `current_user` 접근 가능
- `login_required` before_action으로 인증 필터링

### Outside-In TDD (2026-02-14)

- **순서**: 테스트 먼저 (Red) → 최소 구현 (Green) → 리팩토링 (Refactor)
- **레이어**: Controller → Service → Domain (바깥에서 안으로)
- **이점**: 사용자 관점에서 시작, 불필요한 코드 방지

### File-Based Planning Workflow (2026-02-16)

- **6-File 템플릿 구조**: README.md, spec.md, tasks.md, plan.md,
  findings.md, progress.md
- **progress.md 구조**: Session → Phase → 작업 내역 → 생성/수정 파일 →
  (모든 세션 다음) Test Results → Error Log → 5-Question Reboot Check
- **각 Phase 필수 섹션**: 작업 내역 + 생성/수정 파일 (일관성 유지)
- **문서 동기화 중요성**: spec.md ↔ plan.md ↔ tasks.md ↔ findings.md ↔
  progress.md 모든 정보가 일치해야 함
- **마크다운 린트**: MD032 (리스트 앞 빈 줄), 템플릿 구조 준수 필수
- **즉시 문서 업데이트**: 코드 작성 후 progress.md → findings.md →
  AGENTS.md 순서로 즉시 기록

### 입력 방어와 정규화 (2026-02-16)

- `authenticate`는 nil/빈 문자열 입력을 명시적으로 거부해 예외를
  방지한다
- 사용자명은 컨트롤러 간 동일한 규칙으로 정규화해야 한다

### 스펙 완전성 (2026-02-16)

- Acceptance Scenarios와 Functional Requirements는 1:1 대응되어야 한다
- Success Criteria는 모든 시나리오를 커버해야 한다
- OpenAPI 스펙의 응답 스키마는 일관성 있게 정의되어야 한다
- 구현된 테스트가 있다면 반드시 스펙에도 시나리오로 명시해야 한다

### 보안 강화 및 에러 처리 개선 (2026-02-16)

- 동일 패스워드 변경 방지로 보안 강화 (무의미한 변경 차단)
- 패스워드 최대 길이 제한 (128자)으로 DoS 공격 방지
- 에러 응답 형식을 `{ error: "..." }` 단일 형식으로 통일하여 API
  일관성 확보
- validation 에러는 첫 번째 메시지만 반환하여 클라이언트 처리 단순화

### before_action 패턴 활용 (2026-02-16)

- 검증 로직은 before_action으로 분리하여 책임 분리
- `verify_current_password`: 기존 패스워드 검증
- `prevent_same_password`: 동일 패스워드 방지
- 이점: 코드 가독성 향상, 로직 재사용 가능, 테스트 용이성
- 메서드 순서: before_action 호출 순서대로 배치 (가독성 향상)
- helper 메서드 (`password_params`)는 마지막에 배치
- `set_password_params` before_action 대신 memoization 패턴 사용
