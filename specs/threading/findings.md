# Threading Feature Findings

## Requirements

- [ ] 답글(Reply): 기존 글에 답글 작성
- [ ] 인용(Quote): 다른 글을 인용하며 새 글 작성
- [ ] 리포스트(Repost): 다른 글을 그대로 공유
- [ ] 스레드 조회: 답글 목록 및 상위 스레드 조회
- [ ] 카운터 표시: 답글/인용/리포스트 수

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
| 관계 모델링 | 자기 참조 | 별도 관계 테이블 | MVP 단계에서 단순함 우선 |
| content NULL | 컬럼 제약 제거 | 빈 문자열 허용 | 의미적 명확성 |
| 삭제 처리 | Soft Delete | Cascade/Nullify | 답글 보존, UX 우수 |
| 성능 최적화 | 카운터 캐시 | 매번 COUNT | 조회 성능 |

## Issues Encountered

*(아직 없음)*

## Resources

- `app/models/post.rb` - Post 모델
- `app/controllers/posts_controller.rb` - Posts 컨트롤러
- `db/migrate/20251113231533_create_posts.rb` - Posts 마이그레이션
- `config/routes.rb` - 라우트 설정
- `app/models/concerns/video_processable.rb` - 동영상 처리 concern

## Learnings

### 2026-01-26

- 프로젝트는 Rails 8.1 API 모드, PostgreSQL, ULID 기반 ID 사용
- Post는 User와 belongs_to 관계
- content는 현재 NOT NULL 제약이 있어 리포스트 지원 시 변경 필요
- VideoProcessable concern으로 동영상 URL 처리
