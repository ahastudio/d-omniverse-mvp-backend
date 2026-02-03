# Findings & Decisions

> **기술적 발견, 중요한 결정이 있을 때마다 이 파일을 즉시 업데이트하세요.**

## Requirements

- [x] 글에 parent_id를 지정하여 다른 글에 연결
- [x] 특정 글의 자식 글(replies) 목록 조회
- [x] 특정 글의 상위 스레드(ancestors) 조회
- [x] 자식 글 수(reply_count) 표시
- [x] 부모 글 정보(parent) 임베드
- [x] 깊이(depth) 표시

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

### Post 모델 현황 (변경 전 스냅샷)

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

| Decision            | Rationale                |
| ------------------- | ------------------------ |
| parent_id 자기 참조 | 단순하고 직관적          |
| Soft Delete         | 스레드 구조 유지         |
| 자식 글 개수 캐시   | 조회 성능 최적화         |
| depth 컬럼 추가     | O(1) 조회, N+1 쿼리 방지 |

## Issues Encountered

| Issue                   | Resolution                           |
| ----------------------- | ------------------------------------ |
| bundle install 실패     | 마이그레이션 파일 직접 생성          |
| fixture ID 순서 문제    | ULID가 피드 알고리즘에 영향, ID 수정 |
| parent_payload 무한재귀 | 간략한 ParentPost 스키마로 분리      |

## Resources

### 코드 참조

- Post 모델: `app/models/post.rb`
- Posts 컨트롤러: `app/controllers/posts_controller.rb`
- 마이그레이션: `db/migrate/20251113231533_create_posts.rb`
- 라우트: `config/routes.rb`

### API 엔드포인트

- GET `/posts` - 글 목록 조회
- POST `/posts` - 글 작성 (parentId 지원)
- GET `/posts/:id` - 단일 글 조회 (parent, depth 포함)
- DELETE `/posts/:id` - 글 삭제 (Soft Delete)
- GET `/posts/:id/replies` - 답글 목록 조회
- GET `/posts/:id/thread` - 스레드 전체 조회

## Learnings

### 코드베이스 분석 (2026-01-26)

- Post는 ULID 기반 문자열 ID 사용
- User와 belongs_to 관계
- content는 현재 NOT NULL 제약
- VideoProcessable concern으로 동영상 처리

### 구현 (2026-01-28)

- Rails counter_cache로 replies_count 자동 관리
- Soft delete는 deleted_at 컬럼으로 구현
- 삭제된 글도 스레드 구조 유지 (parent_id 참조 허용)

### 확장 (2026-02-03)

- 목록 API에서 parent 객체 임베드 시 무한재귀 주의
- ParentPost는 간략한 정보만 포함 (id, content, deleted, parentId)
- depth를 DB 컬럼으로 캐싱하여 O(1) 조회 가능

### depth 컬럼 구현 (2026-02-04)

- before_save 콜백으로 depth 자동 계산 (`parent.depth + 1`)
- fixture는 콜백을 트리거하지 않으므로 depth 값 직접 설정 필요
- 기존 ancestors_count 메서드는 유지 (하위 호환성)
- DB 마이그레이션 순서: 테스트 환경 → 개발 환경 (둘 다 실행해야 schema.rb 정상)
