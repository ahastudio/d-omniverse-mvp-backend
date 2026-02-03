# Project: 피드 추천 정렬

## Summary

Scene 페이지 피드에서 로그인 사용자에게 관계 점수 기반 게시물 추천 정렬을 적용하여
개인화된 콘텐츠 경험을 제공한다.

## Goal

관계 점수 기반 피드 정렬 기능 구현 및 테스트 완료

## Current Phase

✅ 완료

## Phases

### Phase 1: Requirements & Discovery ✅

- [x] 요구사항 확인 (spec.md 작성)
- [x] 기존 코드베이스 탐색
- [x] UserRelationship 모델 확인
- [x] PostsController 구조 파악

### Phase 2: Planning & Structure ✅

- [x] SQL 쿼리 설계
- [x] 컨트롤러 로직 설계
- [x] 테스트 케이스 정의

### Phase 3: Implementation ✅

- [x] 컨트롤러 테스트 작성
- [x] PostsController 수정
- [x] Post 모델 scope 추가

### Phase 4: Testing & Verification ✅

- [x] 단위 테스트 실행
- [x] 기존 테스트 영향 검증
- [x] 성능 테스트

### Phase 5: Delivery ✅

- [x] 문서 업데이트
- [x] 커밋 완료

## Technical Context

### Stack

- Ruby on Rails (API-only mode)
- SQLite (development/test), PostgreSQL (production 가능성)
- Minitest (테스트 프레임워크)

### Architecture

- RESTful API
- MVC 패턴 (Rails 기본)
- JWT 인증 기반

### Key Decisions

| Decision                 | Rationale                                 |
| ------------------------ | ----------------------------------------- |
| LEFT JOIN 사용           | 관계 없는 사용자 게시물 표시 (score 0)   |
| 본인 게시물 최상단       | 본인 최신 글 1개만 최상단 고정            |
| 작성자 다양성 보장       | diversity_score로 3번 이상 연속 방지      |
| 동일 점수 시 최신순      | 신선한 콘텐츠 우선 노출                   |
| 비로그인 시 최신순       | 기존 동작 유지, 추천은 로그인 사용자만    |

## Project Structure

### Source Code

```text
app/
├── controllers/
│   └── posts_controller.rb  (수정)
├── models/
│   └── post.rb  (수정: recommended_for scope 추가)
test/
└── controllers/
    └── posts_controller_test.rb  (수정: 다양성 검증)
```

### SQL Query Design (Final)

```sql
-- 1. 작성자별 순번 부여 (서브쿼리)
SELECT posts.*,
       ROW_NUMBER() OVER (
         PARTITION BY posts.user_id
         ORDER BY posts.id DESC
       ) AS author_post_rank
FROM posts
WHERE posts.deleted_at IS NULL

-- 2. 메인 쿼리
SELECT posts.*,
       CASE WHEN posts.id = :latest_own_post_id THEN 1 ELSE 0 END AS is_top_own,
       CASE
         WHEN posts.user_id = :current_user_id THEN 10
         ELSE COALESCE(user_relationships.score, 0) +
              COALESCE(reverse_rel.score, 0) * 0.3
       END AS base_score,
       CASE
         WHEN posts.user_id = :current_user_id THEN 10.0 / author_post_rank
         ELSE (COALESCE(user_relationships.score, 0) +
               COALESCE(reverse_rel.score, 0) * 0.3) / author_post_rank
       END AS diversity_score
FROM (subquery) AS posts
LEFT JOIN user_relationships
  ON user_relationships.user_id = :current_user_id
  AND user_relationships.target_user_id = posts.user_id
LEFT JOIN user_relationships AS reverse_rel
  ON reverse_rel.target_user_id = :current_user_id
  AND reverse_rel.user_id = posts.user_id
ORDER BY is_top_own DESC,
         diversity_score DESC,
         posts.id DESC
```

## Key Questions

1. 페이지네이션 필요 여부는?
2. 캐싱 전략이 필요한가?
3. 성능 목표 기준은?

## Decisions Made

| Decision                       | Rationale                                  |
| ------------------------------ | ------------------------------------------ |
| 컨트롤러에 로직 구현           | 초기 단순 구현, 복잡해지면 모델로 이동     |
| before_action 활용             | 기존 패턴 유지, set_posts 메서드에서 분기  |
| 성능 최적화 후순위             | 기능 구현 우선, 문제 발생 시 대응          |

## Risks & Mitigations

- **성능**: LEFT JOIN 추가로 쿼리 복잡도 증가
  - 완화: 인덱스 활용, 필요시 페이지네이션 추가
- **N+1**: includes(:user)와 JOIN 충돌 가능
  - 완화: 쿼리 최적화 검증
- **대규모 데이터**: 많은 관계/게시물 시 응답 지연
  - 완화: 캐싱, 페이지네이션, 백그라운드 처리 고려

## Dependencies

- UserRelationship 모델 (이미 구현됨)
- JWT 인증 (이미 구현됨)
- PostsController (수정 대상)
