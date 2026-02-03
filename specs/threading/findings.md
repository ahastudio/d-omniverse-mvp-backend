# Findings & Decisions

> **기술적 발견, 중요한 결정이 있을 때마다 이 파일을 즉시 업데이트하세요.**

## Requirements

- [ ] 글에 parent_id를 지정하여 다른 글에 연결
- [ ] 특정 글의 자식 글(replies) 목록 조회
- [ ] 특정 글의 상위 스레드(ancestors) 조회
- [ ] 자식 글 수(reply_count) 표시

## Research Findings

### 코드베이스 구조

- 백엔드: Rails 8.1 API 모드
- DB: PostgreSQL (개발), SQLite3 (테스트)
- ID: ULID 기반 문자열
- 인증: JWT + Argon2

### 기존 패턴

- 모델: `app/models/` 디렉토리
- 컨트롤러: `app/controllers/` 디렉토리
- 라우트: `config/routes.rb`
- 마이그레이션: `db/migrate/`

### Post 모델 현황

```ruby
class Post < ApplicationRecord
  include VideoProcessable
  video_attribute :video_url
  belongs_to :user
  validates :content, presence: true
end
```

### Posts 테이블 스키마

```ruby
create_table :posts, id: false do |t|
  t.string :id, null: false, primary_key: true  # ULID
  t.string :user_id, null: false, index: true
  t.string :content, null: false
  t.text :video_url
  t.timestamps
end
```

## Technical Decisions

| Decision            | Rationale        |
| ------------------- | ---------------- |
| parent_id 자기 참조 | 단순하고 직관적  |
| Soft Delete         | 스레드 구조 유지 |
| 자식 글 개수 캐시   | 조회 성능 최적화 |

## Issues Encountered

(아직 없음)

## Resources

### 코드 참조

- Post 모델: `app/models/post.rb`
- Posts 컨트롤러: `app/controllers/posts_controller.rb`
- 마이그레이션: `db/migrate/20251113231533_create_posts.rb`
- 라우트: `config/routes.rb`

### API 엔드포인트

- GET `/posts` - 글 목록 조회
- POST `/posts` - 글 작성

## Learnings

### 코드베이스 분석 (2026-01-26)

- Post는 ULID 기반 문자열 ID 사용
- User와 belongs_to 관계
- content는 현재 NOT NULL 제약
- VideoProcessable concern으로 동영상 처리
