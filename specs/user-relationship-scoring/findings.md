# Findings & Decisions

> **기술적 발견, 중요한 결정이 있을 때마다 이 파일을 즉시
> 업데이트하세요.**

## Requirements

- [x] POST `/user-relationships` 엔드포인트 제공
- [x] GET `/user-relationships/:target_user_id` 엔드포인트 제공
- [ ] GET `/user-relationships?userId=<user_id>` 엔드포인트 제공
- [x] interaction type별 점수 차등 부여
- [x] 자기 자신에 대한 interaction 거부
- [x] 인증 필수
- [ ] 특정 사용자의 관계 목록 조회 (점수 높은 순)
- [ ] 대상 사용자 정보 포함 (id, username, nickname, avatarUrl,
  score)

## Research Findings

### 코드베이스 구조

- 백엔드: Ruby on Rails (API-only)
- ID 체계: ULID 기반 String id
- 인증: JWT + Argon2
- 테스트: Minitest + Fixtures

### 기존 패턴

- API 파라미터: camelCase로 받고 `transform_keys(&:underscore)`로
  snake_case 변환
- 에러 처리: `save!` + `rescue` 패턴 사용
- 컨트롤러: `before_action`으로 로직 분리
- 응답: JSON 형식 (Rails 기본 render)
- `else` 사용 금지 (early return 선호)
- Soft delete: `deleted_at` 컬럼 사용

### 관련 모델 조사 결과

- User 모델: ULID 기반 id, username unique 인덱스
- Post 모델: user_id 외래키, soft delete 구현
- 기존 관계: User has_many :posts, Post belongs_to :user

## Technical Decisions

| Decision                                      | Rationale                    |
| --------------------------------------------- | ---------------------------- |
| user_relationships 테이블 생성                | 별도 테이블로 관심사 분리    |
| (user_id, target_user_id) 복합 unique 인덱스 | 중복 방지 및 조회 성능       |
| score 컬럼 (integer, default: 0)              | 단순 누적 점수 저장          |
| INTERACTION_SCORES 상수                       | type별 점수를 한 곳에서 관리 |

## Interaction Type & Scores

| Type           | Score | Description               |
| -------------- | ----- | ------------------------- |
| `profile_view` | +1    | 프로필 페이지 방문        |
| `reaction`     | +2    | 게시물에 반응 (좋아요 등) |
| `post_view`    | +1    | 게시물 조회               |

## Issues Encountered

(없음)

## New Feature Analysis (2026-02-03)

### 관계 목록 조회 API 설계

**요구사항**:

- 프로필 페이지에서 관계가 가까운 사용자 목록 표시
- 자신의 프로필뿐 아니라 다른 사용자 프로필에서도 조회 가능
- 점수 높은 순으로 정렬
- 대상 사용자 정보 포함: id, username, nickname, avatarUrl, score

**기술적 결정**:

| Decision                     | Rationale                              |
| ---------------------------- | -------------------------------------- |
| index 액션 추가              | RESTful 패턴 따름                      |
| userId 쿼리 파라미터 (선택)  | 생략 시 현재, 지정 시 해당 사용자      |
| includes(:target_user) 사용  | N+1 쿼리 방지                          |
| order(score: :desc)          | 점수 높은 순 정렬                      |
| User의 avatar_url 매핑       | 기존 컬럼명 사용                       |

**필요한 작업**:

1. ~~UserRelationship 모델에 `belongs_to :target_user` 관계 추가~~
   (이미 존재 확인됨)
2. routes.rb에 index 액션 추가 (only 배열 수정)
3. index 액션 구현 (userId 파라미터 처리)
4. 존재하지 않는 사용자 처리 (404)
5. 테스트 케이스 추가

**구현 시 주의사항**:

1. **파라미터 처리**:
   - camelCase로 받기: `params[:userId]`
   - 생략 시: `current_user.id` 사용
   - 제공 시: 해당 사용자 ID 사용
2. **사용자 존재 확인**:
   - `User.find(user_id)` 사용 → 없으면 404
   - `find_by`가 아닌 `find` 사용하여 자동 예외 발생
3. **쿼리 최적화**:
   - `includes(:target_user)` 필수 (N+1 방지)
   - `where(user_id: user_id)` 조건
   - `order(score: :desc)` 정렬
4. **응답 형식**:
   - avatarUrl (camelCase)로 매핑
   - avatar_url이 nil일 수 있음 (그대로 전달)
5. **라우팅**:
   - `only: [:index, :create, :show]`로 수정
   - index는 collection 라우트 (자동으로
     GET /user-relationships)

## Resources

### 문서

- [Rails Migrations](
  https://guides.rubyonrails.org/active_record_migrations.html)
- [Rails Associations](
  https://guides.rubyonrails.org/association_basics.html)

### 코드 참조

- Posts Controller: `app/controllers/posts_controller.rb`
- User Model: `app/models/user.rb`
- Routes: `config/routes.rb`

## Learnings

### 2026-02-02: 프로젝트 분석

- ULID 기반 id로 시간순 정렬 가능
- JWT 인증은 ApplicationController에서 처리
- before_action :login_required 로 인증 필수 설정
- 기존 스펙 템플릿 4파일 구조 확인

## Database Schema Design

```ruby
create_table :user_relationships, id: :string do |t|
  t.string :user_id, null: false
  t.string :target_user_id, null: false
  t.integer :score, null: false, default: 0
  t.timestamps
end

add_index :user_relationships, [:user_id, :target_user_id],
          unique: true
add_index :user_relationships, :target_user_id
```
