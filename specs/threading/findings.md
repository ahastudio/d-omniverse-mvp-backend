# 기술적 발견사항 (Technical Findings)

## 기존 코드베이스 분석

### 1. Post 모델 현황

**파일**: `app/models/post.rb`

```ruby
class Post < ApplicationRecord
  include VideoProcessable

  video_attribute :video_url

  belongs_to :user

  validates :content, presence: true
end
```

**특징**:
- `VideoProcessable` concern 사용
- User와 belongs_to 관계
- content가 필수 (validates :content, presence: true)

**변경 필요 사항**:
- 리포스트 지원을 위해 content 유효성 검증 조건부 변경 필요
- 새로운 관계(parent, quoted_post, reposted_post) 추가 필요
- 자기 참조(self-referential) 관계 설정

### 2. Posts 테이블 스키마

**파일**: `db/migrate/20251113231533_create_posts.rb`

```ruby
create_table :posts, id: false do |t|
  t.string :id, null: false, primary_key: true
  t.string :user_id, null: false, index: true
  t.string :content, null: false
  t.text :video_url
  t.timestamps
end
```

**특징**:
- ULID 기반 문자열 ID 사용 (id: false + string :id)
- content가 NOT NULL 제약 있음

**변경 필요 사항**:
- content의 NOT NULL 제약 제거 (리포스트용)
- parent_id, quoted_post_id, reposted_post_id 컬럼 추가
- 각 참조 컬럼에 인덱스 추가
- 외래 키 제약 조건은 선택적 (soft delete 고려)

### 3. PostsController 현황

**파일**: `app/controllers/posts_controller.rb`

**액션**:
- `index`: 글 목록 조회
- `create`: 글 작성

**파라미터 처리**:
```ruby
params.permit(:content, :videoUrl)
      .transform_keys(&:underscore)
```

**변경 필요 사항**:
- `show` 액션 추가
- `parentId`, `quotedPostId`, `repostedPostId` 파라미터 허용
- 응답에 관련 글 정보 포함
- 카운터 필드 포함

### 4. 라우트 현황

**파일**: `config/routes.rb`

```ruby
resources :posts, only: [ :index, :create ]
```

**변경 필요 사항**:
- `show` 액션 추가
- 중첩 라우트 추가: `posts/:id/replies`, `posts/:id/thread`

## 기술적 의사결정

### 결정 1: 자기 참조 관계 구현

| 방안 | 장점 | 단점 | 결정 |
|------|------|------|------|
| 단일 테이블 + 자기 참조 | 단순, 쿼리 용이 | 복잡한 관계 표현 제한 | **채택** |
| 별도 관계 테이블 | 유연성 높음 | 복잡도 증가, 조인 필요 | 미채택 |

**결정 근거**: MVP 단계에서는 단순한 구조가 유리. 자기 참조 관계로
충분히 스레드 기능 구현 가능.

### 결정 2: content NULL 허용 방식

| 방안 | 장점 | 단점 | 결정 |
|------|------|------|------|
| 컬럼 제약 제거 | 단순 | DB 레벨 보호 약화 | **채택** |
| 빈 문자열 허용 | 제약 유지 | 의미적 혼란 | 미채택 |
| 별도 repost 테이블 | 명확한 분리 | 복잡도 증가 | 미채택 |

**결정 근거**: 모델 레벨 유효성 검증으로 보완.
리포스트 시에만 content NULL 허용.

### 결정 3: 삭제 정책

| 방안 | 장점 | 단점 | 결정 |
|------|------|------|------|
| Soft Delete | 데이터 보존, UX 우수 | 쿼리 복잡 | **채택** |
| Nullify | 단순 | 컨텍스트 손실 | 대안 |
| Cascade | 일관성 | 데이터 손실 | 미채택 |

**결정 근거**: 삭제된 글의 답글이 갑자기 사라지면 사용자 혼란.
"이 글은 삭제되었습니다" 표시가 더 나은 UX.

### 결정 4: 카운터 캐싱

| 방안 | 장점 | 단점 | 결정 |
|------|------|------|------|
| 카운터 캐시 컬럼 | 조회 성능 우수 | 동기화 필요 | **채택** |
| 매번 COUNT 쿼리 | 항상 정확 | 성능 저하 | 미채택 |
| 비동기 집계 | 부하 분산 | 지연 발생 | 향후 고려 |

**결정 근거**: Rails의 counter_cache 기능 활용.
글 수가 많아지면 COUNT 쿼리는 병목.

## 참조 코드 위치

| 항목 | 파일 경로 | 라인 |
|------|-----------|------|
| Post 모델 | `app/models/post.rb` | 전체 |
| Posts 컨트롤러 | `app/controllers/posts_controller.rb` | 전체 |
| Posts 마이그레이션 | `db/migrate/20251113231533_create_posts.rb` | 전체 |
| 라우트 | `config/routes.rb` | posts 리소스 |
| VideoProcessable | `app/models/concerns/video_processable.rb` | 전체 |
| ULID 생성 | `app/controllers/posts_controller.rb` | create 액션 |

## 외부 참조

- [Rails Self-Referential Association](https://guides.rubyonrails.org/association_basics.html)
- [Twitter Threading Model](https://developer.twitter.com/en/docs/twitter-api)
- [Counter Cache in Rails](https://guides.rubyonrails.org/association_basics.html#options-for-belongs-to-counter-cache)
