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

| Issue                            | Resolution                           |
| -------------------------------- | ------------------------------------ |
| bundle install 실패              | 마이그레이션 파일 직접 생성          |
| fixture ID 순서 문제             | ULID가 피드 알고리즘에 영향, ID 수정 |
| parent_payload 무한재귀          | 간략한 ParentPost 스키마로 분리      |
| 존재하지 않는 게시물 404에러     | set_post에 rescue 처리 추가          |
| fixture ID 길이 불일치           | 모든 ID를 26자로 통일 (008, 009)     |
| post_payload에서 parent N+1 쿼리 | includes(:user, :parent) 추가        |
| 승인 없이 spec 수정 및 구현      | 작업 되돌리고 AGENTS.md 규칙 강화    |

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

### 에러 처리 (2026-02-03)

- `ActiveRecord::RecordNotFound` rescue로 일관된 JSON 응답
- `set_post` 메서드에 rescue 블록 추가로 show/replies/thread 액션 통합
  처리
- UsersController 패턴과 동일하게 `{ error: "Post not found" }` 형식
  사용

### 문서화 규칙 강화 (2026-02-03)

- 코드 작성과 문서 업데이트는 분리할 수 없는 하나의 작업
- 구현 순서 명확화: 문서 확인 → 테스트 작성 → 구현 → 테스트 실행 → 문서
  업데이트
- progress.md, findings.md 업데이트는 사용자 요청 전에 자동으로 해야 함
- AGENTS.md에 피드백 루프 규칙을 매우 구체적으로 강화

### Fixture 관리 (2026-02-03)

- fixture ID 길이 일관성이 매우 중요 (lexicographic ordering 영향)
- ULID 형식의 모든 ID는 동일한 길이(26자)를 유지해야 함
- `order(id: :desc)` 같은 정렬이 문자열 길이에 의존하므로 비일관성 시 테스트 깨질
  수 있음

### N+1 쿼리 최적화 (2026-02-03)

- `post_payload`에서 parent를 참조하면 각 게시물마다 추가 쿼리 발생 (N+1)
- `includes(:user, :parent)`로 preload하면 O(1) 쿼리로 최적화
- `includes`는 별도 쿼리로 로드하지만 N+1을 방지 (메인 1개 + preload 1개 = 총 2개)
- ActiveSupport::Notifications로 쿼리 수 검증 테스트 작성 가능

### API 스키마 일관성 (2026-02-03)

- ParentPost에도 user 정보 포함 필요 (UI에서 작성자 표시)
- user 객체는 일관되게 id, username, nickname, avatarUrl 포함
- 스키마 변경 시 spec.md 먼저 업데이트 후 구현
- parent.user는 includes로 preload되어 추가 쿼리 없음

### ParentPost 스키마 확장 (2026-02-03)

- ParentPost는 Post와 동일한 필드를 모두 포함해야 함
- videoUrl, depth, repliesCount, createdAt, updatedAt 추가
- 스키마 일관성 확보로 프론트엔드에서 동일한 방식으로 렌더링 가능
- "요약 정보"라는 설명에도 불구하고 전체 정보 제공이 UX 개선에 유리

### ParentPost 스키마 완성 구현 (2026-02-03)

- TDD: 테스트 먼저 작성 → 실패 확인 → 구현 → 통과 확인
- parent_payload에 필드 추가 시 `.compact` 호출로 nil 값 자동 제거
- videoUrl이 nil인 경우 `assert_nil` 사용으로 경고 방지
- 전체 테스트로 다른 기능에 영향 없음 확인 (83 pass, 224 assertions)

### 확장 (2026-02-03)

- 목록 API에서 parent 객체 임베드 시 무한재귀 주의
- ParentPost는 간략한 정보만 포함 (id, content, deleted, parentId)
- depth를 DB 컬럼으로 캐싱하여 O(1) 조회 가능

### depth 컬럼 구현 (2026-02-03)

- before_save 콜백으로 depth 자동 계산 (`parent.depth + 1`)
- fixture는 콜백을 트리거하지 않으므로 depth 값 직접 설정 필요
- 기존 ancestors_count 메서드는 유지 (하위 호환성)
- DB 마이그레이션 순서: 테스트 환경 → 개발 환경 (둘 다 실행해야 schema.rb 정상)

### 개발 프로세스 교훈 (2026-02-03)

- spec에 없는 필드 발견 시 **절대** 바로 추가하지 말 것
- "챙겨줘" 같은 요청에도 먼저 사용자에게 보고하고 승인 받아야 함
- 문서 업데이트 후 **"이제 구현해도 될까요?"** 반드시 질문
- 승인 없이 진행 → 작업 되돌리기 + AGENTS.md 규칙 강화로 대응
