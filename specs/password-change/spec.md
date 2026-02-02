# 패스워드 변경

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Password Change (Priority: P1)

로그인한 사용자가 기존 패스워드를 확인한 후 새 패스워드로 변경한다.

**Why this priority**: 보안 필수 기능으로, 사용자가 패스워드 유출 시
즉시 변경할 수 있어야 함

**Independent Test**: `/users/{username}/password` 엔드포인트에 PATCH
요청을 보내 응답 코드를 확인하는 것으로 독립적으로 테스트 가능

**Acceptance Scenarios**:

1. 올바른 기존 패스워드로 변경 성공
   - **Given** 사용자가 로그인 상태이고 기존 패스워드가 "oldpass123"
   - **When** PATCH `/users/{username}/password` 요청
     (`oldPassword`: "oldpass123", `newPassword`: "newpass456")
   - **Then** 200 OK 응답
2. 잘못된 기존 패스워드로 변경 실패
   - **Given** 사용자가 로그인 상태이고 기존 패스워드가 "oldpass123"
   - **When** PATCH `/users/{username}/password` 요청
     (`oldPassword`: "wrongpass", `newPassword`: "newpass456")
   - **Then** 422 Unprocessable Entity 응답
3. 인증 없이 변경 시도
   - **Given** Authorization 헤더 없음
   - **When** PATCH `/users/{username}/password` 요청
   - **Then** 401 Unauthorized 응답
4. 다른 사용자의 패스워드 변경 시도
   - **Given** 사용자 A가 로그인 상태
   - **When** PATCH `/users/{B}/password` 요청 (다른 사용자)
   - **Then** 403 Forbidden 응답

### Edge Cases

- 새 패스워드가 기존 패스워드와 동일한 경우: 허용 (변경 성공)
- 빈 문자열 패스워드: 422 에러 반환
- 존재하지 않는 사용자: 404 Not Found

### Manual Testing with HTTPie

```bash
# 패스워드 변경 성공 (200 OK 예상)
http PATCH https://local-d-omniverse-api.a99.dev/users/dancer/password \
  Authorization:"Bearer <token>" \
  oldPassword=oldpass123 \
  newPassword=newpass456

# 잘못된 기존 패스워드 (422 예상)
http PATCH https://local-d-omniverse-api.a99.dev/users/dancer/password \
  Authorization:"Bearer <token>" \
  oldPassword=wrongpass \
  newPassword=newpass456

# 인증 없이 요청 (401 예상)
http PATCH https://local-d-omniverse-api.a99.dev/users/dancer/password \
  oldPassword=oldpass123 \
  newPassword=newpass456
```

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 시스템은 PATCH `/users/{username}/password` 엔드포인트를
  제공해야 함
- **FR-002**: 시스템은 기존 패스워드 검증 후 새 패스워드로 변경해야 함
- **FR-003**: 시스템은 기존 패스워드가 틀린 경우 422 상태 코드로
  응답해야 함
- **FR-004**: 시스템은 인증되지 않은 요청에 401 상태 코드로 응답해야 함
- **FR-005**: 시스템은 다른 사용자의 패스워드 변경 시도에 403 상태
  코드로 응답해야 함
- **FR-006**: 새 패스워드는 Argon2로 해싱되어 저장되어야 함

### Non-Functional Requirements

- **NFR-001**: 패스워드 검증 및 해싱은 Argon2 알고리즘 사용
- **NFR-002**: 요청/응답 파라미터는 camelCase 사용

### Key Entities

- **User**: password_digest 속성을 가진 사용자 엔티티

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 올바른 기존 패스워드로 변경 시 100% 성공 (200 응답)
- **SC-002**: 잘못된 기존 패스워드로 변경 시 100% 실패 (422 응답)
- **SC-003**: 인증 없는 요청은 100% 거부 (401 응답)
- **SC-004**: 타인 패스워드 변경 시도는 100% 거부 (403 응답)

## Assumptions

- 기존 User 모델에 Authenticatable concern이 포함되어 있음
- Argon2 기반 패스워드 해싱이 구현되어 있음
- JWT 기반 인증 시스템이 작동 중
- API는 JSON 응답을 기본으로 함

## Out of Scope

- 패스워드 복잡도 검증 (최소 길이, 특수문자 등)
- 패스워드 변경 이력 관리
- 패스워드 변경 후 기존 세션 무효화
- 이메일/SMS 알림
- Rate limiting

## Dependencies

- User 모델 (app/models/user.rb)
- Authenticatable concern (app/models/concerns/authenticatable.rb)
- ApplicationController 인증 메서드 (login_required, current_user)
