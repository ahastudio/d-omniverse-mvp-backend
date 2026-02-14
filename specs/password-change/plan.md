# Implementation Plan: 패스워드 변경

## Summary

기존 Authenticatable concern의 `authenticate` 메서드로 기존 패스워드를
검증하고, `password=` setter로 새 패스워드를 해싱하여 저장한다.
PasswordsController를 새로 생성하여 단일 책임 원칙을 따른다.

## Requirements

1. PATCH `/users/{username}/password` 엔드포인트 제공
2. 기존 패스워드 검증 후 새 패스워드로 변경
3. 본인만 변경 가능 (권한 검사)
4. 인증 필수

## Critical Files

### New Files

- `app/controllers/passwords_controller.rb`
- `test/controllers/passwords_controller_test.rb`

### Modified Files

- `config/routes.rb`

### Reference Files

- `app/models/concerns/authenticatable.rb`
- `app/controllers/application_controller.rb`
- `app/models/user.rb`

## Architecture

Outside-In 순서로 다이어그램을 표현합니다.

### User Flow

```text
사용자 → [PATCH /users/:username/password] → PasswordsController
                                                     ↓
                                             before_action 검사
                                             (인증, 권한)
                                                     ↓
                                             기존 패스워드 검증
                                             (User#authenticate)
                                                     ↓
                                             새 패스워드 저장
                                             (User#password=, save!)
                                                     ↓
                                             200 OK 응답
```

### Domain Model

```text
User (기존)
├── authenticate(password)  ← 기존 패스워드 검증
├── password=               ← 새 패스워드 해싱
└── save!                   ← 저장
```

## Implementation Steps (Outside-In TDD)

### Step 1: Route 추가

**File:** `config/routes.rb`

```ruby
resources :users, only: [ :create, :show, :update ], param: :username do
  resource :password, only: [ :update ]
end
```

### Step 2: Controller 테스트 작성 (Red)

**File:** `test/controllers/passwords_controller_test.rb`

```ruby
class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "올바른 기존 패스워드로 변경 성공" do
    patch user_password_url(user_username: @user.username),
          params: { oldPassword: "password123", newPassword: "newpass456" },
          headers: @auth_header,
          as: :json

    assert_response :ok
  end
end
```

테스트 케이스:
- 올바른 기존 패스워드로 변경 성공 (200)
- 잘못된 기존 패스워드로 변경 실패 (422)
- 인증 없이 요청 시 (401)
- 다른 사용자 패스워드 변경 시 (403)
- 존재하지 않는 사용자 (404)

### Step 3: Controller 구현 (Green)

**File:** `app/controllers/passwords_controller.rb`

```ruby
class PasswordsController < ApplicationController
  before_action :login_required
  before_action :set_user
  before_action :verify_owner

  def update
    # 최소한의 코드로 테스트 통과
  end
end
```

### Step 4: Refactor

- 중복 제거
- 코드 정리
- 80컬럼 맞추기

## Verification

### Build

```bash
bin/rails runner "puts 'OK'"
```

### Test

```bash
bin/rails test test/controllers/passwords_controller_test.rb
```

### Manual Test

```bash
# 패스워드 변경 성공 (200 OK 예상)
http PATCH localhost:3000/users/dancer/password \
  Authorization:"Bearer <token>" \
  oldPassword=password123 \
  newPassword=newpass456

# 잘못된 기존 패스워드 (422 예상)
http PATCH localhost:3000/users/dancer/password \
  Authorization:"Bearer <token>" \
  oldPassword=wrongpass \
  newPassword=newpass456
```

## Considerations

### 기존 코드 재사용

- Authenticatable concern의 `authenticate` 메서드 활용
- ApplicationController의 `login_required`, `current_user` 활용

### 호환성

- 기존 User 모델 변경 없음
- 기존 인증 시스템과 호환
