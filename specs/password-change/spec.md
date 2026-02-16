# Feature Specification: 패스워드 변경

## Overview

로그인한 사용자가 기존 패스워드를 확인한 후 새 패스워드로 변경할 수 있다.
패스워드 유출 시 즉시 변경할 수 있어야 하는 보안 필수 기능이다.

## User Scenarios & Testing (mandatory)

### User Story 1: 패스워드 변경

- As: 로그인한 사용자는
- I: 내 패스워드를 변경할 수 있다
- So: 보안을 강화하거나 유출된 패스워드를 교체하기 위해

#### Acceptance Scenarios

Scenario 1: **올바른 기존 패스워드로 변경 성공**

- Given: 사용자가 로그인 상태이고 기존 패스워드가 "oldpass123"
- When: PATCH `/users/{username}/password` 요청
  (`oldPassword`: "oldpass123", `newPassword`: "newpass456")
- Then: 200 OK 응답

Scenario 2: **잘못된 기존 패스워드로 변경 실패**

- Given: 사용자가 로그인 상태이고 기존 패스워드가 "oldpass123"
- When: PATCH `/users/{username}/password` 요청
  (`oldPassword`: "wrongpass", `newPassword`: "newpass456")
- Then: 422 Unprocessable Entity 응답

Scenario 3: **인증 없이 변경 시도**

- Given: Authorization 헤더 없음
- When: PATCH `/users/{username}/password` 요청
- Then: 401 Unauthorized 응답

Scenario 4: **다른 사용자의 패스워드 변경 시도**

- Given: 사용자 A가 로그인 상태
- When: PATCH `/users/{B}/password` 요청 (다른 사용자)
- Then: 403 Forbidden 응답

Scenario 5: **존재하지 않는 사용자**

- Given: 사용자가 로그인 상태
- When: PATCH `/users/{nonexistent}/password` 요청
- Then: 404 Not Found 응답

Scenario 6: **새 패스워드가 빈 문자열**

- Given: 사용자가 로그인 상태이고 기존 패스워드가 "oldpass123"
- When: PATCH `/users/{username}/password` 요청
  (`oldPassword`: "oldpass123", `newPassword`: "")
- Then: 422 Unprocessable Entity 응답

Scenario 7: **새 패스워드가 기존과 동일**

- Given: 사용자가 로그인 상태이고 기존 패스워드가 "oldpass123"
- When: PATCH `/users/{username}/password` 요청
  (`oldPassword`: "oldpass123", `newPassword`: "oldpass123")
- Then: 422 Unprocessable Entity 응답

Scenario 8: **기존 패스워드 누락**

- Given: 사용자가 로그인 상태
- When: PATCH `/users/{username}/password` 요청
  (`newPassword`: "newpass456", oldPassword 없음)
- Then: 422 Unprocessable Entity 응답

Scenario 9: **새 패스워드가 최대 길이 초과**

- Given: 사용자가 로그인 상태
- When: PATCH `/users/{username}/password` 요청 (새 패스워드 128자 초과)
- Then: 422 Unprocessable Entity 응답

## Functional Requirements (mandatory)

- FR-1: MUST 시스템은 PATCH `/users/{username}/password` 엔드포인트를
  제공해야 함
- FR-2: MUST 시스템은 기존 패스워드 검증 후 새 패스워드로 변경해야 함
- FR-3: MUST 기존 패스워드가 틀린 경우 422 상태 코드로 응답해야 함
- FR-4: MUST 인증되지 않은 요청에 401 상태 코드로 응답해야 함
- FR-5: MUST 다른 사용자의 패스워드 변경 시도에 403 상태 코드로 응답해야 함
- FR-6: MUST 새 패스워드는 Argon2로 해싱되어 저장되어야 함
- FR-7: MUST 새 패스워드가 빈 문자열인 경우 422 상태 코드로 응답해야 함
- FR-8: MUST 새 패스워드가 기존과 동일한 경우 422 상태 코드로 응답해야 함
- FR-9: MUST 새 패스워드가 128자를 초과하는 경우 422 상태 코드로
  응답해야 함

## Constraints (mandatory)

- CON-1: MUST 요청/응답 파라미터는 camelCase 사용
- CON-2: MUST 패스워드 해싱은 Argon2 알고리즘 사용
- CON-3: MUST JWT Bearer 토큰으로 인증

## Success Criteria (mandatory)

- SC-1: 올바른 기존 패스워드로 변경 시 100% 성공 (200 응답)
- SC-2: 잘못된 기존 패스워드로 변경 시 100% 실패 (422 응답)
- SC-3: 인증 없는 요청은 100% 거부 (401 응답)
- SC-4: 타인 패스워드 변경 시도는 100% 거부 (403 응답)
- SC-5: 존재하지 않는 사용자 요청은 100% 거부 (404 응답)
- SC-6: 빈 새 패스워드 설정 시도는 100% 실패 (422 응답)
- SC-7: 동일한 패스워드로 변경 시도는 100% 실패 (422 응답)
- SC-8: 128자 초과 패스워드 설정 시도는 100% 실패 (422 응답)

## OpenAPI Specification

```yaml
openapi: 3.0.3
info:
  title: Password Change API
  version: 1.0.0
  description: |
    사용자 패스워드 변경 API

paths:
  /users/{username}/password:
    patch:
      summary: 패스워드 변경
      description: |
        로그인한 사용자가 기존 패스워드를 확인한 후 새 패스워드로 변경
      operationId: updatePassword
      tags:
        - Users
      security:
        - bearerAuth: []
      parameters:
        - name: username
          in: path
          required: true
          description: 사용자 username
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - oldPassword
                - newPassword
              properties:
                oldPassword:
                  type: string
                  description: 기존 패스워드
                newPassword:
                  type: string
                  description: 새 패스워드
      responses:
        '200':
          description: 패스워드 변경 성공
        '401':
          description: 인증 실패
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: 권한 없음
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '404':
          description: 사용자 없음
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '422':
          description: 검증 실패 (기존 패스워드 오류 또는 validation 오류)
          content:
            application/json:
              schema:
                oneOf:
                  - $ref: '#/components/schemas/Error'
                  - $ref: '#/components/schemas/ValidationErrors'

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
  schemas:
    Error:
      type: object
      properties:
        error:
          type: string
      example:
        error: "Invalid current password"
    ValidationErrors:
      type: object
      properties:
        errors:
          type: array
          items:
            type: string
      example:
        errors: ["Password digest can't be blank"]
```
