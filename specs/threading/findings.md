# Threading Feature Findings

## Requirements

- [ ] 글에 parent_id를 지정하여 다른 글에 연결
- [ ] 특정 글의 자식 글(replies) 목록 조회
- [ ] 특정 글의 상위 스레드(ancestors) 조회
- [ ] 자식 글 수(reply_count) 표시

## Research Findings

### 현재 Post 모델 구조

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  include VideoProcessable
  video_attribute :video_url
  belongs_to :user
  validates :content, presence: true
end
```

### 현재 Posts 테이블 스키마

```ruby
# db/migrate/20251113231533_create_posts.rb
create_table :posts, id: false do |t|
  t.string :id, null: false, primary_key: true  # ULID
  t.string :user_id, null: false, index: true
  t.string :content, null: false
  t.text :video_url
  t.timestamps
end
```

### 현재 PostsController 액션

- `index`: 글 목록 조회 (type=video 필터 지원)
- `create`: 글 작성 (인증 필요)

### 현재 라우트

```ruby
resources :posts, only: [ :index, :create ]
```

## Technical Decisions

| 항목 | 선택 | 대안 | 선택 이유 |
|------|------|------|-----------|
| 관계 모델링 | parent_id 자기 참조 | 별도 테이블 | 단순하고 직관적 |
| 삭제 처리 | Nullify | Cascade | 자식 글 보존 |
| 성능 최적화 | counter_cache | 매번 COUNT | 조회 성능 |

## Issues Encountered

*(아직 없음)*

## Resources

- `app/models/post.rb` - Post 모델
- `app/controllers/posts_controller.rb` - Posts 컨트롤러
- `db/migrate/20251113231533_create_posts.rb` - Posts 마이그레이션
- `config/routes.rb` - 라우트 설정

## Learnings

### 2026-01-26

- 프로젝트는 Rails 8.1 API 모드, PostgreSQL, ULID 기반 ID 사용
- Post는 User와 belongs_to 관계
- 스레드는 parent_id 하나로 단순하게 구현 (인용/리포스트 제외)
