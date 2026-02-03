# Username 중복 검사

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Username Availability Check (Priority: P1)

사용자가 회원가입 과정에서 원하는 username이 사용 가능한지 확인한다.

**Why this priority**: MVP의 핵심 기능으로, 사용자가 중복되지 않는 username을
선택할 수 있도록 즉각적인 피드백을 제공

**Independent Test**: `/username-seats/{username}` 엔드포인트에 GET 요청을 보내
응답 코드를 확인하는 것으로 독립적으로 테스트 가능

**Acceptance Scenarios**:

1. Username이 존재하지 않는 경우
   - **Given** 데이터베이스에 username "available_user"가 존재하지 않음
   - **When** GET `/username-seats/available_user` 요청
   - **Then** 200 OK 응답
2. Username이 이미 존재하는 경우
   - **Given** 데이터베이스에 username "john_doe"가 존재함
   - **When** GET `/username-seats/john_doe` 요청
   - **Then** 409 Conflict 응답
3. 특수 문자가 포함된 Username
   - **Given** 특수 문자가 포함된 username "user@123"
   - **When** GET `/username-seats/user@123` 요청
   - **Then** 적절한 응답 (URL 인코딩 처리 확인)

### Edge Cases

- 대소문자 변환: 대문자 입력 시 자동으로 소문자로 변환하여 검사
- 빈 문자열 요청: `/username-seats/` 요청 시 처리 방식
- 길이 제한: 3자 미만 또는 100자 초과 username 처리
- 공백 포함: username에 공백이 포함된 경우 자동 제거 후 검사
- 특수 문자: 영문 소문자와 숫자만 허용, 기타 문자는 유효하지 않음
- 시작 문자: 반드시 영문 소문자로 시작 (숫자 시작 불가)
- URL 인코딩: 특수 문자가 포함된 username의 URL 인코딩 처리

### Manual Testing with HTTPie

```bash
# 사용 가능한 username 확인 (200 OK 예상)
http GET https://local-d-omniverse-api.a99.dev/username-seats/available_user

# 이미 존재하는 username 확인 (409 Conflict 예상)
http GET https://local-d-omniverse-api.a99.dev/username-seats/john_doe

# 대소문자 혼합 (자동으로 소문자 변환 후 검사)
http GET https://local-d-omniverse-api.a99.dev/username-seats/JohnDoe
```

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: 시스템은 GET `/username-seats/{username}` 엔드포인트를 제공해야 함
- **FR-002**: 시스템은 요청된 username이 이미 존재하는 경우 409 Conflict 상태
  코드로 응답해야 함
- **FR-003**: 시스템은 요청된 username이 존재하지 않는 경우 200 OK 상태 코드로
  응답해야 함
- **FR-004**: 시스템은 username 조회를 데이터베이스에서 수행해야 함
- **FR-005**: 시스템은 URL 파라미터로 전달된 username을 적절히 디코딩 해야 함
- **FR-006**: 시스템은 username을 자동으로 정규화해야 함 (소문자 변환, 공백
  제거)
- **FR-007**: Username 형식 규칙: 3-100자, 영문 소문자로 시작, 영문 소문자와
  숫자만 사용

### Non-Functional Requirements

- **NFR-001**: 응답 시간은 100ms 이하여야 함 (데이터베이스 인덱스 활용)
- **NFR-002**: 엔드포인트는 인증 없이 접근 가능해야 함 (public API)
- **NFR-003**: 동시 요청 처리 가능해야 함 (race condition 고려)

### Key Entities

- **User**: username 속성을 가진 사용자 엔티티 (기존 users 테이블 활용)

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: 존재하는 username 조회 시 100% 정확하게 409 응답
- **SC-002**: 존재하지 않는 username 조회 시 100% 정확하게 200 응답
- **SC-003**: 평균 응답 시간 100ms 이하 달성
- **SC-004**: 동시 요청 1000건 처리 시 오류율 0%

## Assumptions

- 기존 User 모델에 username 필드가 존재하고 unique 제약 조건이 있음
- 데이터베이스 username 컬럼에 인덱스가 존재함
- Username은 자동으로 정규화됨 (소문자 변환, 공백 제거)
- Username 형식: 3-100자, 영문 소문자 시작, 영문 소문자+숫자만
- Rails의 기본 라우팅 및 컨트롤러 구조 사용
- API는 JSON 응답을 기본으로 함

## Out of Scope

- Username 예약 기능 (조회만 수행, 예약은 하지 않음)
- Username 형식 검증의 상세한 규칙 정의 (별도 기능으로 분리)
- 사용자 인증/인가
- Rate limiting
- 응답 메시지 본문 내용 (상태 코드만 중요)

## Dependencies

- User 모델 (app/models/user.rb)
- Users 테이블의 username 컬럼
- Rails 라우팅 시스템
