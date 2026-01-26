# 스레드 기능 구현 계획 (Implementation Plan)

## 북극성 (North Star)

**D-Omniverse에 트위터 스타일의 스레드 기능을 추가하여 사용자들이
글을 통해 대화하고 소통할 수 있게 한다.**

## Phase 개요

| Phase | 설명 | 상태 |
|-------|------|------|
| Phase 1 | 데이터베이스 스키마 확장 | ⏸️ 대기 |
| Phase 2 | 모델 관계 및 유효성 검증 | ⏸️ 대기 |
| Phase 3 | 글 작성 API 확장 | ⏸️ 대기 |
| Phase 4 | 글 조회 API 확장 | ⏸️ 대기 |
| Phase 5 | 스레드 전용 API | ⏸️ 대기 |
| Phase 6 | 카운터 캐싱 및 성능 최적화 | ⏸️ 대기 |

---

## Phase 1: 데이터베이스 스키마 확장 ⏸️

### 목표
Posts 테이블에 스레드 관련 컬럼 추가

### 체크리스트
- [ ] 마이그레이션 파일 생성
- [ ] `parent_id` 컬럼 추가 (string, null: true, index: true)
- [ ] `quoted_post_id` 컬럼 추가 (string, null: true, index: true)
- [ ] `reposted_post_id` 컬럼 추가 (string, null: true, index: true)
- [ ] `content` 컬럼 NOT NULL 제약 제거
- [ ] 카운터 컬럼 추가 (reply_count, quote_count, repost_count)
- [ ] 마이그레이션 실행 및 검증
- [ ] 테스트 환경에서 마이그레이션 확인

### 산출물
- `db/migrate/XXXXXX_add_threading_to_posts.rb`

---

## Phase 2: 모델 관계 및 유효성 검증 ⏸️

### 목표
Post 모델에 자기 참조 관계 및 유효성 검증 추가

### 체크리스트
- [ ] 자기 참조 관계 설정 (parent, replies)
- [ ] quoted_post 관계 설정
- [ ] reposted_post 관계 설정
- [ ] content 유효성 검증 조건부 변경
- [ ] 자기 참조 방지 유효성 검증
- [ ] 글 유형 판별 메서드 추가 (reply?, quote?, repost?)
- [ ] 모델 테스트 작성 및 실행

### 산출물
- `app/models/post.rb` (수정)
- `test/models/post_test.rb` (수정)

---

## Phase 3: 글 작성 API 확장 ⏸️

### 목표
기존 글 작성 API에 답글/인용/리포스트 기능 추가

### 체크리스트
- [ ] 파라미터에 parentId, quotedPostId, repostedPostId 추가
- [ ] 참조 대상 글 존재 여부 검증
- [ ] 리포스트 시 content 비어있음 검증
- [ ] 인용 시 content 필수 검증
- [ ] 동시에 여러 참조 불가 검증
- [ ] 응답에 관련 필드 포함
- [ ] 컨트롤러 테스트 작성 및 실행

### 산출물
- `app/controllers/posts_controller.rb` (수정)
- `test/controllers/posts_controller_test.rb` (수정)

---

## Phase 4: 글 조회 API 확장 ⏸️

### 목표
글 목록 및 단일 글 조회 시 스레드 정보 포함

### 체크리스트
- [ ] `show` 액션 추가
- [ ] 라우트에 `show` 추가
- [ ] 응답에 parent, quotedPost, repostedPost 정보 포함
- [ ] 응답에 카운터 정보 포함
- [ ] type 필터 확장 (reply, quote, repost)
- [ ] 컨트롤러 테스트 작성 및 실행

### 산출물
- `app/controllers/posts_controller.rb` (수정)
- `config/routes.rb` (수정)
- `test/controllers/posts_controller_test.rb` (수정)

---

## Phase 5: 스레드 전용 API ⏸️

### 목표
답글 목록 및 스레드 조회 API 구현

### 체크리스트
- [ ] `GET /posts/:id/replies` 엔드포인트 구현
- [ ] `GET /posts/:id/thread` 엔드포인트 구현
- [ ] 상위 스레드 조회 로직 (ancestors)
- [ ] 페이지네이션 지원
- [ ] 라우트 설정
- [ ] 컨트롤러 테스트 작성 및 실행

### 산출물
- `app/controllers/posts_controller.rb` (수정)
- `config/routes.rb` (수정)
- `test/controllers/posts_controller_test.rb` (수정)

---

## Phase 6: 카운터 캐싱 및 성능 최적화 ⏸️

### 목표
카운터 캐싱 설정 및 N+1 쿼리 방지

### 체크리스트
- [ ] counter_cache 설정
- [ ] 기존 데이터 카운터 초기화 (rake task)
- [ ] includes/eager_load로 N+1 방지
- [ ] 쿼리 성능 테스트
- [ ] 인덱스 최적화 확인

### 산출물
- `app/models/post.rb` (수정)
- `lib/tasks/threading.rake` (신규)

---

## 주요 질문 및 결정

| 질문 | 결정 | 근거 |
|------|------|------|
| 삭제된 글 처리 방식? | Soft Delete | UX 고려, 답글 보존 |
| 중복 리포스트 허용? | 불허 | 스팸 방지 |
| 스레드 깊이 제한? | 100단계 | 성능 고려 |
| 외래 키 제약? | 미적용 | Soft Delete 호환 |

## 오류 로그

| 날짜 | Phase | 오류 내용 | 해결 방법 |
|------|-------|----------|----------|
| - | - | - | - |

---

## 다음 단계

Phase 1부터 순차적으로 진행. 각 Phase 완료 후 테스트 통과 확인 필수.
